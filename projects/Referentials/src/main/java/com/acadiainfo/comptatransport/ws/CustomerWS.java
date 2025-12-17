package com.acadiainfo.comptatransport.ws;

import java.time.LocalDateTime;
import java.util.Set;
import java.util.logging.Logger;
import java.util.stream.Stream;

import com.acadiainfo.comptatransport.data.AggShippingRevenueRepository;
import com.acadiainfo.comptatransport.data.CustomersRepository;
import com.acadiainfo.comptatransport.data.PriceGridsRepository;
import com.acadiainfo.comptatransport.domain.AggShippingRevenue;
import com.acadiainfo.comptatransport.domain.Customer;
import com.acadiainfo.comptatransport.domain.CustomerShipPreferences;
import com.acadiainfo.comptatransport.domain.PriceGrid;
import com.acadiainfo.util.WSUtils;

import jakarta.ejb.Stateless;
import jakarta.json.Json;
import jakarta.json.JsonArrayBuilder;
import jakarta.json.JsonBuilderFactory;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
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
import jakarta.ws.rs.core.StreamingOutput;
import jakarta.ws.rs.core.UriBuilder;


@Stateless
@Path("/customers")
public class CustomerWS {
	private static final Logger logger = Logger.getLogger(CustomerWS.class.getName());

	@Context
	private HttpServletRequest servReq;

	@PersistenceContext(unitName = "ComptaTransportPU")
	private EntityManager em;

	@GET
	@Path("/{id}")
	@Produces(MediaType.APPLICATION_JSON)
	public Response getOne_WS(@PathParam("id") Long id) {
		try {
			Customer customer = this.getOne(id);
			return Response.ok(customer).build();
		} catch (jakarta.persistence.PersistenceException exc) {
			return ApplicationConfig.response(exc, servReq, Customer.class);
		}
	}

	/**
	 * Get customer by id.
	 * @param id
	 * @return Customer is exists
	 * @throws jakarta.persistence.EntityNotFoundException if not
	 */
	public Customer getOne(Long id) {
		Customer customer = CustomersRepository.getInstance(em).findById(id);
		if (customer != null)
			return customer;
		else
			throw new jakarta.persistence.EntityNotFoundException("(id=" + id + ")");
	}

	@GET
	@Produces(value = MediaType.APPLICATION_JSON)
	public StreamingOutput getAll_WS(
	    @QueryParam("name-like") String nameLike,
	  @QueryParam("tag") Set<String> tags,
	  @QueryParam("show-inactive") Boolean showInactive) {
		CustomersRepository repo = CustomersRepository.getInstance(em);

		Stream<Customer> customers;
		if (nameLike != null && !nameLike.equals("")) {
			customers = repo.findAllByLabel(nameLike);
		} else {
			customers = repo.findAll();
		}

		if (showInactive == null || !showInactive.booleanValue())
			customers = customers.filter(c -> !c.getTags().contains("inactive"));

		if (tags != null && !tags.isEmpty()) {
			logger.finer("tags detected : " + tags);
			customers = customers.filter(c -> c.getTags().containsAll(tags));
		}

		return WSUtils.entityJsonStreamingOutput(customers);
	}


	@POST
	@Consumes(value = MediaType.APPLICATION_JSON)
	public Response add_WS(Customer customer) {
		try {
			/* invalidate tags cache */ TAGS_JSON_timestamp = 0L;
			customer = this.add(customer);
			java.net.URI uri = UriBuilder.fromUri("./customers").path(String.valueOf(customer.getId())).build();
			return Response.created(uri).build();
		} catch (IllegalArgumentException exc) {
			return WSUtils.response(Status.BAD_REQUEST, servReq, exc.getMessage());
		} catch (jakarta.persistence.PersistenceException exc) {
			return ApplicationConfig.response(exc, servReq, Customer.class);
		}
	}

	public Customer add(Customer customer) {
		CustomersRepository customersRepo = CustomersRepository.getInstance(em);

		if (customer == null)
			throw new IllegalArgumentException("Le corps du message n'a pas pu interprété comme un Client");
		if (customer.getErpReference() == null || customer.getErpReference().equals(""))
			throw new IllegalArgumentException("La référence ERP du Client ne peut pas être vide.");
		if (customer.getLabel() == null || customer.getLabel().equals(""))
			throw new IllegalArgumentException("Le libellé du Client ne peut pas être vide.");
		if (customer.getShipPreferences() != null)
			if (!customer.getShipPreferences().isEmpty())
				throw new IllegalArgumentException("Les Préférences Transport du Client ne doivent pas être incluses."
				  +"\n Utilisez le verb PATCH pour cela.");


		// Unusual : id is not supposed to be provided
		if (customer.getId() != null)
			if (customersRepo.find(customer) != null)
				throw new jakarta.persistence.EntityExistsException("Un Client possède déjà le même identifiant."
				  + " Il est recommandé de ne pas l'inclure dans le corps du message.");

		if (customersRepo.findByErpReference(customer.getErpReference()) != null)
			throw new jakarta.persistence.EntityExistsException("Un autre Client possède déjà la même référence ERP.");

		return customersRepo.insert(customer);
	}

	/**
	 * This one has a a "Update" semantics for all properties, except for "ShipPreferences" where it is more "PATCH" (add & update only, never delete)
	 * @param id
	 * @param customer_payload
	 * @return
	 */
	@PUT
	@Path("/{id}")
	@Consumes(value = MediaType.APPLICATION_JSON)
	public Response update_WS(@PathParam("id") Long id, String customer_payloadstr) {
		logger.info(customer_payloadstr);
		jakarta.json.bind.Jsonb jsonb = jakarta.json.bind.JsonbBuilder.create();
		Customer customer_payload = jsonb.fromJson(customer_payloadstr, Customer.class);

		CustomersRepository customersRepo = CustomersRepository.getInstance(em);

		// payload check
		if (customer_payload.getId() != null && !customer_payload.getId().equals(id))
			return WSUtils.response(Status.BAD_REQUEST, servReq,
			  "Identifiant incohérent dans l'URI et le corps du message."
			 +" Il est possible (et recommandé) de ne pas l'inclure dans le corps du message.");
		if (customer_payload.getErpReference() == null || customer_payload.getErpReference().equals(""))
			return WSUtils.response(Status.BAD_REQUEST, servReq, "La référence ERP du Client ne peut pas être vide.");
		if (customer_payload.getLabel() == null || customer_payload.getLabel().equals(""))
			return WSUtils.response(Status.BAD_REQUEST, servReq, "Le libellé du Client ne peut pas être vide.");

		// constraint check
		Customer otherCustomer = customersRepo.findByErpReference(customer_payload.getErpReference());
		if (otherCustomer != null && !otherCustomer.getId().equals(id))
			return WSUtils.response(Status.CONFLICT, servReq, "Un autre Client possède déjà la même référence ERP.");

		try {
			/* invalidate tags cache */ TAGS_JSON_timestamp = 0L;
			customer_payload.setId(id);
			// customer_payload.setShipPreferences(... neutralized specifically in repo
			Customer customer = customersRepo.update(customer_payload, false);

			// specific handling of ShipPreferences, with a PATCH semantics
			if (customer_payload.getShipPreferences() != null) {
				PriceGridsRepository priceGridsRepo = PriceGridsRepository.getInstance(em);

				for (CustomerShipPreferences preference_in_payload : customer_payload.getShipPreferences()) {
					// resolve Customer consistency in payload
					if (preference_in_payload.getCustomer() != null
					  && preference_in_payload.getCustomer().getId() != null
					  && !customer.getId().equals(preference_in_payload.getCustomer().getId()))
						return WSUtils.response(Status.BAD_REQUEST, servReq, "Les Préférences de Transport ne doivent pas spécifier un identifiant Client différent !");
					preference_in_payload.setCustomer(customer);

					// Try and find corresponding record in database :
					CustomerShipPreferences preference_in_base = customer.getShipPreferences().stream()
					    .filter(pref -> pref.getCustomer().getId().equals(preference_in_payload.getCustomer().getId()))
					    .filter(pref -> pref.getApplicationDate().equals(preference_in_payload.getApplicationDate()))
					    .findAny().orElse(null);

					if (preference_in_base == null) {
						// a) either Create new ShipPreferences
						preference_in_payload.setCustomer(customer);
						em.persist(preference_in_payload);
						// customer.getShipPreferences().add(preference_in_payload); bidi mapping

					} else { // b) or Update existing ShipPreferences
						// b) or Update existing ShipPreferences
												patchShipPreference(preference_in_base, preference_in_payload, priceGridsRepo);
					}
				}
			}
			em.flush();

			return Response.noContent().entity(customer).build(); // no_content with a content ;-)
		} catch (jakarta.persistence.OptimisticLockException exc) {
			return WSUtils.response(Status.CONFLICT, servReq,
					"Client peut-être modifié depuis (\"_v_lock\" non-concordant).");
		} catch (jakarta.persistence.EntityNotFoundException exc) {
			return WSUtils.response(Status.NOT_FOUND, servReq, "Client peut-être supprimé depuis.");
		} catch (jakarta.persistence.PersistenceException exc) {
			return ApplicationConfig.response(exc, servReq, Customer.class);
		}
	}

	@DELETE
	@Path("/{id}")
	public Response delete_WS(@PathParam("id") Long id) {
		try {
			/* invalidate tags cache */ TAGS_JSON_timestamp = 0L;
			CustomersRepository.getInstance(em).deleteById(id);
			return Response.noContent().build();
		} catch (jakarta.persistence.PersistenceException exc) {
			return ApplicationConfig.response(exc, servReq, Customer.class);
		}
	}


	private static void patchShipPreference(CustomerShipPreferences target, CustomerShipPreferences source,
	    PriceGridsRepository priceGridsRepo) {

		//id and customer : out of scope
		target.setApplicationDate(source.getApplicationDate());
		target.setOverrideCarriers(source.getOverrideCarriers());
		target.setTags(source.getTags());
		target.setCarrierTagsWhitelist(source.getCarrierTagsWhitelist());
		target.setCarrierTagsBlacklist(source.getCarrierTagsBlacklist());


		if (source.getOverridePriceGrid() != null) {
			PriceGrid overridePriceGrid = null;
			Long pgid = source.getOverridePriceGrid().getId();
			if (overridePriceGrid == null && pgid != null) {
				overridePriceGrid = priceGridsRepo.findById(pgid);
			}

			String pgname = source.getOverridePriceGrid().getName();
			if (overridePriceGrid == null && pgid != null) {
				overridePriceGrid = priceGridsRepo.findByName(pgname);
			}

			if (overridePriceGrid == null)
				throw new IllegalArgumentException("Dans Préférence Transport du Client, la Grille Tarifaire n'a été trouvée ni par l'id, ni par le nom fourni");
			target.setOverridePriceGrid(overridePriceGrid);
		} else {
			target.setOverridePriceGrid(null);
		}
	}

	@PUT
	@Path("/{id_or_ref}/activate")
	public Response activate_WS(@PathParam("id_or_ref") String idOrRef) {
		try {
			CustomersRepository customersRepo = CustomersRepository.getInstance(em);
			Customer customer = customersRepo.findByErpReference(idOrRef);
			if (customer == null) {
				try {
					long id = Long.parseLong(idOrRef);
					customer = customersRepo.findById(id);
				} catch (NumberFormatException exc) {
					throw new IllegalArgumentException(
					    idOrRef + " n'a pu être trouvé comme réf. ERP, mais n'est pas un identifiant numérique non plus.");
				}
			}
			if (customer == null)
				return WSUtils.response(Status.NOT_FOUND, servReq,
				    "Aucun Client trouvé avec [" + idOrRef + "] (ni par id ni par réf. ERP)");

			/* invalidate tags cache */ TAGS_JSON_timestamp = 0L;
			customer.getTags().remove("inactive");
			em.detach(customer);
			em.merge(customer); // TODO that doesn't seem right ...
			em.flush();

			return Response.noContent().build();
		} catch (jakarta.persistence.PersistenceException exc) {
			return ApplicationConfig.response(exc, servReq, Customer.class);
		}
	}

	@GET
	@Path("/*/agg-shipping-revenues")
	@Produces(MediaType.APPLICATION_JSON)
	public StreamingOutput getAll_ShippingRevenueAggregates_WS(
	  @QueryParam("start-date") String startDate,
	  @QueryParam("end-date") String endDate) {

		LocalDateTime startDateObj, endDateObj;
		if (startDate == null || startDate.equals("")) {
			throw new IllegalArgumentException("Le paramètre \"start-date\" est une date obligatoire");
		}
		if (endDate == null || endDate.equals("")) {
			throw new IllegalArgumentException("Le paramètre \"end-date\" est une date obligatoire");
		}
		try {
			startDateObj = WSUtils.parseParamDate(startDate);
			// end-date is optional, if not set use start-date + 1
			endDateObj = (endDate == null) ? startDateObj.plusDays(1) : WSUtils.parseParamDate(endDate);
		} catch (java.time.format.DateTimeParseException exc) {
			throw new IllegalArgumentException(
			    "Format de paramètres de date incorrect (\"start-date\" et/ou \"end-date\").");
		}

		AggShippingRevenueRepository aggShippingRevRepo = AggShippingRevenueRepository.getInstance(em);

		Stream<AggShippingRevenue> aggs = aggShippingRevRepo.getAllBetween(startDateObj, endDateObj);
		return WSUtils.entityJsonStreamingOutput(aggs);
	}

	/**
	 * Tag listing service, with static cache.
	 */
	private static String TAGS_JSON = "";
	private static volatile long TAGS_JSON_timestamp = 0L;
	private static final long TAGS_JSON_ttl = 60000L; /* 1 min */

	private static final java.util.List<String> VIP_TAGS, SYS_TAGS;
	static {
		VIP_TAGS = new java.util.ArrayList<String>();
		VIP_TAGS.add("Grand Compte");
		VIP_TAGS.add("Dropshipper");
		SYS_TAGS = new java.util.ArrayList<String>();
		SYS_TAGS.add("inactive");
	}

	@GET
	@Path("/*/tags")
	@Produces(value = MediaType.APPLICATION_JSON)
	public String getCollectedTags() {

		/* rebuild cache if stale (concurrent build is allowed) */
		if (System.currentTimeMillis() - TAGS_JSON_timestamp > TAGS_JSON_ttl) {
			logger.fine("Build TAGS_JSON cache");

			// collect custom tags already set
			Set<String> collectedTags = java.util.Collections.synchronizedSet(new java.util.TreeSet<String>());
			CustomersRepository.getInstance(em).findAll().forEach(t -> collectedTags.addAll(t.getTags()));
			collectedTags.removeAll(VIP_TAGS);
			collectedTags.removeAll(SYS_TAGS);

			// build Json String to cache
			JsonBuilderFactory factory = Json.createBuilderFactory(null);
			JsonArrayBuilder vipTagsB = factory.createArrayBuilder();
			for (String tag : VIP_TAGS) {
				vipTagsB.add(tag);
			}
			JsonArrayBuilder systemTagsB = factory.createArrayBuilder();
			for (String tag : SYS_TAGS) {
				systemTagsB.add(tag);
			}
			JsonArrayBuilder collectedTagsB = factory.createArrayBuilder();
			for (String tag : collectedTags) {
				collectedTagsB.add(tag);
			}
			String newValue = Json.createObjectBuilder()
				.add("vip", vipTagsB)
				.add("system", systemTagsB)
			    .add("collected", collectedTagsB)
			    .build().toString();

			synchronized (this.getClass()) {
				TAGS_JSON = newValue;
				TAGS_JSON_timestamp = System.currentTimeMillis();
			}
		}

		synchronized (this.getClass()) {
			return TAGS_JSON;
		}

	}

}
