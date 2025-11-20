package com.acadiainfo.comptatransport.ws;

import java.time.LocalDateTime;
import java.util.Set;
import java.util.logging.Logger;
import java.util.stream.Stream;

import com.acadiainfo.comptatransport.data.CarriersRepository;
import com.acadiainfo.comptatransport.data.TransportSalesRepository;
import com.acadiainfo.comptatransport.domain.Carrier;
import com.acadiainfo.comptatransport.domain.TransportSalesHeader;
import com.acadiainfo.util.WSUtils;

import jakarta.ejb.Stateless;
import jakarta.json.*;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.servlet.http.HttpServletRequest;

import jakarta.ws.rs.*;
import jakarta.ws.rs.core.*;
import jakarta.ws.rs.core.Response.Status;

@Stateless
@Path("/transport-sales")
public class TransportSalesWS {
	private Logger logger = Logger.getLogger(getClass().getName());

	@Context
	private HttpServletRequest servReq;

	@PersistenceContext(unitName = "ComptaTransportPU")
	private EntityManager em;

//
//	@GET
//	@Path("/{name}")
//	@Produces(MediaType.APPLICATION_JSON)
//	public Response getOne_WS(@PathParam("name") String name) {
//		Carrier carrier = this.getOne(name);
//		if (carrier != null) {
//			return Response.ok(carrier).build();
//		} else {
//			return WSUtils.response(Status.NOT_FOUND, servReq,
//					"Transporteur non-trouvé avec ce nom.");
//		}
//	}
//
//	public Carrier getOne(String name) {
//		return CarriersRepository.getInstance(em).findById(name);
//	}

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
			return WSUtils.response(Status.BAD_REQUEST, servReq, "\"start-date\" query param expected");

		LocalDateTime startDateObj = WSUtils.parseParamDate(startDate);

		// end-date is optional, if not set use start-date + 1
		LocalDateTime endDateObj = (endDate == null) ? startDateObj.plusDays(1) : WSUtils.parseParamDate(endDate);

		Stream<TransportSalesHeader> headers = getAll(startDateObj, endDateObj);
		return Response.ok(WSUtils.entityJsonStreamingOutput(headers)).build();
	}

	public Stream<TransportSalesHeader> getAll(LocalDateTime startDate, LocalDateTime endDate) {
		TransportSalesRepository repo = TransportSalesRepository.getInstance(em);

		return repo.getAllBetween(startDate, endDate);
	}
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
