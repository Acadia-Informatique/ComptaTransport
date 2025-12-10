package com.acadiainfo.comptatransport.ws;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.logging.Logger;
import java.util.stream.Stream;

import com.acadiainfo.comptatransport.data.TransportPurchaseRepository;
import com.acadiainfo.comptatransport.data.TransportSalesRepository;
import com.acadiainfo.comptatransport.domain.AggShippingRevenue;
import com.acadiainfo.comptatransport.domain.Carrier;
import com.acadiainfo.comptatransport.domain.Customer;
import com.acadiainfo.comptatransport.domain.CustomerShipPreferences;
import com.acadiainfo.comptatransport.domain.InputControlRevenue;
import com.acadiainfo.comptatransport.domain.TransportPurchaseHeader;
import com.acadiainfo.comptatransport.domain.TransportSalesHeader;
import com.acadiainfo.comptatransport.fileimport.RowsProvider;
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
@Path("/transport-purchase")
public class TransportPurchaseWS {
	private static final Logger logger = Logger.getLogger(TransportPurchaseWS.class.getName());

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
			Stream<TransportPurchaseHeader> headers = getAll(startDateObj, endDateObj);
			return Response.ok(WSUtils.entityJsonStreamingOutput(headers)).build();
	}

	public Stream<TransportPurchaseHeader> getAll(LocalDateTime startDate, LocalDateTime endDate) {
		TransportPurchaseRepository purchaseRepo = TransportPurchaseRepository.getInstance(em);
		TransportSalesRepository    salesRepo    = TransportSalesRepository.getInstance(em);

		List<TransportPurchaseHeader> headers = purchaseRepo.getAllBetween(startDate, endDate).toList();
		for (TransportPurchaseHeader header : headers) {
			for (String docReference : header.getResolvedDocReferences()) {
				TransportSalesHeader sales = salesRepo.getOne(docReference);
				//
			}

			// Simplify and enrich Customer, if any, to make it contain only pricing details

//			Customer customer = header.getCustomer();
//			if (customer == null)
//				continue;
//
//			// - disconnect Customer entity before manipulating it for serialization
//			em.detach(customer);
//			// ... we mainly need customer.getTags();
//			customer.setDescription(null);
//			customer.setErpReference(null); // useful, but redundant with TransportSalesHeader.customerRef
//			customer.setLabel(null);
//			customer.setSalesrep(null);
//			customer.set_v_lock(null);
//			customer.emptyAuditingInfo();

		}

		return headers.stream();
	}

//	/**
//	 *
//	 * Persist the user entry on one row of Transport Revenue Control.
//	 * @param id - ignored, dummy id in view !
//	 * @param row - TransportSalesHeader is never saved per-se, so it is really a convenient
//	 *              wrapper for *saving* its 1-to-1 writable counterpart, InputControlRevenue.
//	 * @return
//	 */
//	@PUT
//	@Path("/{id}")
//	@Consumes(value = MediaType.APPLICATION_JSON)
//	@Produces(value = MediaType.APPLICATION_JSON)
//	public Response saveOne(@PathParam("id") Long id, TransportPurchaseHeader row) {
//		try {
//			// TransportSalesHeader will NOT be retrieved by its id,
//			// since it is a view Object.
//			// Nor will it be persisted... (hence no cascading between them).
//
//			InputControlRevenue realPayload = row.getUserInputs();
//			if (realPayload == null) return Response.noContent().build();
//
//			// linking is through docReference(=invoice number)
//			// because current choice is : a row represents an Invoice (and not an Order).
//			if (row.getDocReference() == null) throw new IllegalArgumentException("Numéro de facture obligatoire dans le bloc \"userInputs\" (attribut \"invoice\")");
//			realPayload.setDocReference(row.getDocReference());
//
//			InputControlRevenue saved;
//			if (realPayload.getId() == null) {
//				em.persist(realPayload);
//				saved = realPayload;
//			} else {
//				// "manual merge" of related entities in payload (find by id instead, in fact)
//				Carrier carrierOverride = realPayload.getCarrier_override();
//				if (carrierOverride != null) {
//					carrierOverride = em.find(Carrier.class, carrierOverride.getName());
//					if (carrierOverride != null) {
//						realPayload.setCarrier_override(carrierOverride);
//					} else {
//						throw new IllegalArgumentException(
//						    "Transport de nom inconnu dans le bloc \"userInputs\" (attribut \"carrier_override\")");
//					}
//				}
//
//				saved = em.merge(realPayload);
//			}
//			em.flush();
//
//			row.setUserInputs(saved);
//			// all others are just irrelevent, we send them back unchanged.
//			row.setDetails(null); // except details is nullified
//
//			return Response.ok(row).build();
//		} catch (IllegalArgumentException exc) {
//			return WSUtils.response(Status.BAD_REQUEST, servReq, exc.getMessage());
//		} catch (jakarta.persistence.PersistenceException exc) {
//			return ApplicationConfig.response(exc, servReq, InputControlRevenue.class);
//		}
//	}


}
