package com.acadiainfo.comptatransport.ws;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.logging.Logger;
import java.util.stream.Stream;

import com.acadiainfo.comptatransport.data.TransportSalesRepository;
import com.acadiainfo.comptatransport.domain.AggShippingRevenue;
import com.acadiainfo.comptatransport.domain.Carrier;
import com.acadiainfo.comptatransport.domain.Customer;
import com.acadiainfo.comptatransport.domain.CustomerShipPreferences;
import com.acadiainfo.comptatransport.domain.InputControlRevenue;
import com.acadiainfo.comptatransport.domain.TransportSalesHeader;
import com.acadiainfo.util.WSUtils;

import jakarta.ejb.Stateless;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Query;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.Response.Status;

/**
 * Used for manipulating Transport Sales (and their dependencies),
 * which are basically the rows of Transport Revenue Control (aka Contrôle Quotidien du Transport).
 */
@Stateless
@Path("/transport-sales")
public class TransportSalesWS {
	private static final Logger logger = Logger.getLogger(TransportSalesWS.class.getName());

	@Context
	private HttpServletRequest servReq;

	@PersistenceContext(unitName = "ComptaTransportPU")
	private EntityManager em;



	/**
	 * Get data row for a date interval.
	 * @param startDate - included
	 * @param endDate -excluded
	 * @return
	 */
	@GET
	@Produces(value = MediaType.APPLICATION_JSON)
	public Response getAll_WS(
	  @QueryParam("start-date") String startDate,
	  @QueryParam("end-date") String endDate) {
			if (startDate == null)
				return WSUtils.response(Status.BAD_REQUEST, servReq, "Paramètre de requête \"start-date\" obligatoire.");

			LocalDateTime startDateObj, endDateObj;
			try {
				startDateObj = WSUtils.parseParamDate(startDate);
				// end-date is optional, if not set use start-date + 1
				endDateObj = (endDate == null) ? startDateObj.plusDays(1) : WSUtils.parseParamDate(endDate);
			} catch (java.time.format.DateTimeParseException exc) {
				return WSUtils.response(Status.BAD_REQUEST, servReq, "Format de paramètres de date incorrect (\"start-date\" et/ou \"end-date\").");
			}
			Stream<TransportSalesHeader> headers = getAll(startDateObj, endDateObj);
			return Response.ok(WSUtils.entityJsonStreamingOutput(headers)).build();
	}

	public Stream<TransportSalesHeader> getAll(LocalDateTime startDate, LocalDateTime endDate) {
		TransportSalesRepository repo = TransportSalesRepository.getInstance(em);

		List<TransportSalesHeader> headers = repo.getAllBetween(startDate, endDate).toList();
		for (TransportSalesHeader header : headers) {
			// Simplify and enrich Customer, if any, to make it contain only pricing details

			Customer customer = header.getCustomer();
			if (customer == null)
				continue;

			// - disconnect Customer entity before manipulating it for serialization
			em.detach(customer);
			// ... we mainly need customer.getTags();
			// customer.setDescription(null); requested by users
			customer.setErpReference(null); // useful, but redundant with TransportSalesHeader.customerRef
			customer.setLabel(null);
			customer.setSalesrep(null);
			customer.set_v_lock(null);
			customer.emptyAuditingInfo();


			// - keep only last applicable preferences
			List<CustomerShipPreferences> preferences = new ArrayList<>(customer.getShipPreferences());
			customer.getShipPreferences().clear();
			preferences.removeIf(pref -> pref.getApplicationDate().isAfter(header.getDocDate()));
			java.util.Collections.sort(preferences,
			    java.util.Comparator.comparing(CustomerShipPreferences::getApplicationDate));
			if (!preferences.isEmpty()) {
				CustomerShipPreferences lastPref = preferences.getLast();
				lastPref.emptyAuditingInfo();
				customer.getShipPreferences().add(lastPref);
			}

			// - get applicable AggShippingRevenue items (usually 1 / product / date)
			customer.getAggShippingRevenues().clear();
			LocalDateTime startOfMonthAtDate = header.getDocDate().withDayOfMonth(1);
			Query aggRevQuery = em
			    .createQuery("select agg from AggShippingRevenue agg where agg.customer=:customer and agg.date=:date");
			aggRevQuery.setParameter("customer", customer);
			aggRevQuery.setParameter("date", startOfMonthAtDate);
			@SuppressWarnings("unchecked")
			List<AggShippingRevenue> aggRevenues = aggRevQuery.getResultList();
			for (AggShippingRevenue aggRevenue : aggRevenues) {
				// simplify json content
				em.detach(aggRevenue);
				aggRevenue.setCustomer(null);
				aggRevenue.setDate(null);
				customer.getAggShippingRevenues().add(aggRevenue);
			}

		}

		return headers.stream();
	}

	/**
	 *
	 * Persist the user entry on one row of Transport Revenue Control.
	 * @param id - ignored, dummy id in view !
	 * @param row - TransportSalesHeader is never saved per-se, so it is really a convenient
	 *              wrapper for *saving* its 1-to-1 writable counterpart, InputControlRevenue.
	 * @return
	 */
	@PUT
	@Path("/{id}")
	@Consumes(value = MediaType.APPLICATION_JSON)
	@Produces(value = MediaType.APPLICATION_JSON)
	public Response saveOne(@PathParam("id") Long id, TransportSalesHeader row) {
		try {
			// TransportSalesHeader will NOT be retrieved by its id,
			// since it is a view Object.
			// Nor will it be persisted... (hence no cascading between them).

			InputControlRevenue realPayload = row.getUserInputs();
			if (realPayload == null) return Response.noContent().build();

			// linking is through docReference(=invoice number)
			// because current choice is : a row represents an Invoice (and not an Order).
			if (row.getDocReference() == null) throw new IllegalArgumentException("Numéro de facture obligatoire dans le bloc \"userInputs\" (attribut \"invoice\")");
			realPayload.setDocReference(row.getDocReference());

			InputControlRevenue saved;
			if (realPayload.getId() == null) {
				em.persist(realPayload);
				saved = realPayload;
			} else {
				// "manual merge" of related entities in payload (find by id instead, in fact)
				Carrier carrierOverride = realPayload.getCarrier_override();
				if (carrierOverride != null) {
					carrierOverride = em.find(Carrier.class, carrierOverride.getName());
					if (carrierOverride != null) {
						realPayload.setCarrier_override(carrierOverride);
					} else {
						throw new IllegalArgumentException(
						    "Transport de nom inconnu dans le bloc \"userInputs\" (attribut \"carrier_override\")");
					}
				}

				saved = em.merge(realPayload);
			}
			em.flush();

			row.setUserInputs(saved);
			// all others are just irrelevent, we send them back unchanged.
			row.setDetails(null); // except details is nullified

			return Response.ok(row).build();
		} catch (IllegalArgumentException exc) {
			return WSUtils.response(Status.BAD_REQUEST, servReq, exc.getMessage());
		} catch (jakarta.persistence.PersistenceException exc) {
			return ApplicationConfig.response(exc, servReq, InputControlRevenue.class);
		}
	}



	/**
	 * Make even bigger TransportSalesHeader, grouping even more rows of ImportTransportVendu.
	 *
	 * Usually each consist in one Invoice/Order, but some sales are made of logically related
	 * orders, even across several invoices, even across several days (they have to be from the
	 * same Customer, though).
	 *
	 */
	@POST
	@Path("/*/group")
	public Response groupDocRef(@QueryParam("invoice") Set<String> docReferences) {
		// define a common "doc_reference" for the group
		if (docReferences.size() < 2) {
			return WSUtils.response(Status.BAD_REQUEST, servReq,
			    "Il faut au moins 2 factures distinctes (query param \"invoice\")");
		}
		String groupReference;
		Optional<String> oGroupReference = docReferences.stream()
		  .filter(ref -> ref.startsWith(TransportSalesHeader.GROUPREF_PREFIX))
		  .sorted().findFirst();
		if (oGroupReference.isPresent()) {
			groupReference = oGroupReference.get(); // keeping existing group name to preserve user inputs
		} else {
			groupReference = TransportSalesHeader.GROUPREF_PREFIX
			    + new java.util.TreeSet<String>(docReferences).last();
			// 1st, last, by date order ?...business decision ;-)
		}

		// batch change "doc_reference" to group name.
		int updateCount = 0; // not necessarily docReferences.size(), if you group... existing groups !
		for (String docRef : docReferences) {
			Query updQuery = em.createNamedQuery("ImportTransportVendu.groupTo");
			updQuery.setParameter("groupDocReference", groupReference);
			updQuery.setParameter("docReference", docRef);
			updateCount += updQuery.executeUpdate();
		}

		// add new comment, if not already exists.
		Query query = em.createQuery("SELECT DISTINCT imp.origDocReference FROM ImportTransportVendu imp WHERE imp.docReference = :docReference");
		query.setParameter("docReference", groupReference);
		@SuppressWarnings("unchecked")
		List<String> originalDocReferences = query.getResultList();

		Query inputQuery = em.createQuery("SELECT i FROM InputControlRevenue i WHERE i.docReference = :docReference");
		inputQuery.setParameter("docReference", groupReference);

		try {
			InputControlRevenue input = (InputControlRevenue) inputQuery.getSingleResult();
			String comment = input.getAmountOK_comment(); // usually where grouping is signaled by users...
			if (comment == null || comment.trim().equals("") || comment.trim().equals("???")) {
				input.setAmountOK_comment("(" + originalDocReferences.size() + " factures groupées)");
			}
		} catch (jakarta.persistence.NoResultException exc) {
			InputControlRevenue input = new InputControlRevenue();
			input.setDocReference(groupReference);
			input.setAmountOK_comment("(" + originalDocReferences.size() + " factures groupées)");
			em.persist(input);
		}
		em.flush();

		return Response.ok(updateCount + " modifiées pour grouper dans : " + groupReference).build();
	}

	@POST
	@Path("/*/ungroup")
	public Response ungroupDocRef(@QueryParam("invoice") String docReference) {
		if (docReference == null || docReference.trim().equals("")) {
			return WSUtils.response(Status.BAD_REQUEST, servReq,
			    "Le numéro de facture du groupe doit être fourni (query param \"invoice\")");
		}

		// batch change "doc_reference" back to their original values.
		Query updQuery = em.createNamedQuery("ImportTransportVendu.ungroup");
		updQuery.setParameter("groupDocReference", docReference);
		int updateCount = updQuery.executeUpdate();

		return Response.ok(updateCount + " lignes dégroupées").build();
	}

	@GET
	@Path("/{mixedId}")
	@Produces(MediaType.APPLICATION_JSON)
	public Response findOneBy(@PathParam("mixedId") String mixedId, @QueryParam("type") String idType) {
		TransportSalesRepository repo = TransportSalesRepository.getInstance(em);
		try {
			TransportSalesHeader header;
			if (idType == null || idType.equals(""))
				idType = "doc";
			switch (idType) {
			case "order":
				header = repo.findByOrderNum(mixedId);
				break;
			case "doc":
				header = repo.getOne(mixedId);
				break;
			default:
				return WSUtils.response(Status.BAD_REQUEST, servReq,
				    "Paramètre de requête \"type\" inconnu, valeur attendue parmi \"doc\" (par défaut) ou \"order\" pour interpréter ID : "
				        + mixedId);
			}

			if (header == null)
				return WSUtils.response(Status.NOT_FOUND, servReq,
				    "Aucune facture trouvée avec ce numéro (essayer avec le paramètre \"type\" ?).");
			else
				return Response.ok(header).build();
		} catch (jakarta.persistence.PersistenceException exc) {
			return ApplicationConfig.response(exc, servReq, TransportSalesRepository.class);
		}
	}

//
//
//
//		try {
//
//		}
//
//
//			// purge previous

//
//		}
//}

//@NamedQuery(name = , query = """
//	UPDATE ImportTransportVendu imp
//	SET imp.docReference = :groupDocReference
//	where imp.docReference = :docReference
//""")
//@NamedQuery(name = "ImportTransportVendu.ungroup", query = """
//
//
//		}

//
//	@POST
//	@Consumes(value = MediaType.APPLICATION_JSON)
//	public Response add_WS(Carrier carrier) {
//		if (carrier == null) {
//			return WSUtils.response(Status.BAD_REQUEST, servReq,
//			  "Le corps du message n'a pas pu interprété comme un Transporteur (Carrier)");
//		}
//		if ("".equals(carrier.getName())) {
//			return WSUtils.response(Status.BAD_REQUEST, servReq,
//					"Le nom du Transporteur ne peut pas être vide");
//		}
//
//		try {
//			/* invalidate tags cache */ TAGS_JSON_timestamp = 0L;
//			carrier = this.add(carrier);
//			return Response.created(UriBuilder.fromUri("./carriers").path(carrier.getName()).build()).build();
//		} catch (jakarta.persistence.EntityExistsException exc) {
//			return WSUtils.response(Status.CONFLICT, servReq,
//					"Le nom du Transporteur doit être unique.");
//		}
//	}
//
//	public Carrier add(Carrier carrier) {
//		CarriersRepository carriersRepo = CarriersRepository.getInstance(em);
//		return carriersRepo.insert(carrier);
//	}
//
//	@PUT
//	@Path("/{name}")
//	@Consumes(value = MediaType.APPLICATION_JSON)
//	public Response update_WS(@PathParam("name") String name, Carrier carrier) {
//		// Carrier-specific : key is "name", so it is also provided in JSON payload
//		if ("".equals(name) || !name.equals(carrier.getName())) {
//			return WSUtils.response(Status.BAD_REQUEST, servReq,
//					"Nom de transporteur manquant ou incohérent dans l'URI et le corps du message."
//			 +" Rappel : le nom ne peut pas être modifié après création.");
//		}
//		try {
//			/* invalidate tags cache */ TAGS_JSON_timestamp = 0L;
//			carrier = CarriersRepository.getInstance(em).update(carrier, false);
//			return Response.noContent().entity(carrier).build();
//		} catch (jakarta.persistence.OptimisticLockException exc) {
//			return WSUtils.response(Status.CONFLICT, servReq,
//			  "Transporteur peut-être modifié depuis (\"_v_lock\" non-concordant).");
//		} catch (jakarta.persistence.EntityNotFoundException exc) {
//			return WSUtils.response(Status.NOT_FOUND, servReq,
//			  "Transporteur peut-être supprimé depuis.");
//		}
//	}
//
//
//	@DELETE
//	@Path("/{name}")
//	public Response delete_WS(@PathParam("name") String name) {
//		try {
//			/* invalidate tags cache */ TAGS_JSON_timestamp = 0L;
//			CarriersRepository.getInstance(em).deleteById(name);
//			return Response.noContent().build();
//		} catch (jakarta.persistence.EntityNotFoundException exc) {
//			return WSUtils.response(Status.NOT_FOUND, servReq,
//					"Transporteur introuvable avec le nom = " + name);
//		}
//	}
//
//	/**
//	 * Tag listing service, with static cache.
//	 */
//	private static String TAGS_JSON = "";
//	private static volatile long TAGS_JSON_timestamp = 0L;
//	private static final long TAGS_JSON_ttl = 60000L; /* 1 min */
//
//	private static final java.util.List<String> SYSTEM_TAGS;
//	static {
//		SYSTEM_TAGS = new java.util.ArrayList<String>();
//		SYSTEM_TAGS.add("Sans frais");
//		SYSTEM_TAGS.add("Virtuel");
//	}
//
//
//	@GET
//	@Path("/*/tags")
//	@Produces(value = MediaType.APPLICATION_JSON)
//	public String getCollectedTags() {
//
//		/* rebuild cache if stale (concurrent build is allowed) */
//		if (System.currentTimeMillis() - TAGS_JSON_timestamp > TAGS_JSON_ttl) {
//			logger.fine("Build TAGS_JSON cache");
//
//			// collect custom tags already set
//			Set<String> collectedTags = java.util.Collections.synchronizedSet(new java.util.TreeSet<String>());
//			this.getAll(null).forEach(t -> collectedTags.addAll(t.getTags()));
//			collectedTags.removeAll(SYSTEM_TAGS);
//
//			// build Json String to cache
//			JsonBuilderFactory factory = Json.createBuilderFactory(null);
//			JsonArrayBuilder systemTagsB = factory.createArrayBuilder();
//			for (String tag : SYSTEM_TAGS) {
//				systemTagsB.add(tag);
//			}
//			JsonArrayBuilder collectedTagsB = factory.createArrayBuilder();
//			for (String tag : collectedTags) {
//				collectedTagsB.add(tag);
//			}
//			String newValue = Json.createObjectBuilder()
//			   .add("system", systemTagsB)
//			   .add("collected", collectedTagsB)
//			   .build().toString();
//
//			synchronized(this.getClass()) {
//				TAGS_JSON = newValue;
//				TAGS_JSON_timestamp = System.currentTimeMillis();
//			}
//		}
//
//		synchronized(this.getClass()) {
//			return TAGS_JSON;
//		}
//
//	}


}
