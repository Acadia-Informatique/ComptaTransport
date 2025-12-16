package com.acadiainfo.comptatransport.ws;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map.Entry;
import java.util.logging.Logger;
import java.util.stream.Stream;

import com.acadiainfo.comptatransport.data.CustomersRepository;
import com.acadiainfo.comptatransport.data.TransportPurchaseRepository;
import com.acadiainfo.comptatransport.data.TransportSalesRepository;
import com.acadiainfo.comptatransport.domain.Customer;
import com.acadiainfo.comptatransport.domain.InputControlCosts;
import com.acadiainfo.comptatransport.domain.InputControlRevenue;
import com.acadiainfo.comptatransport.domain.TransportPurchaseHeader;
import com.acadiainfo.comptatransport.domain.TransportSalesHeader;
import com.acadiainfo.util.WSUtils;

import jakarta.ejb.Stateless;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
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
			// get linked Invoices
			for (String mixedReference : header.getResolvedDocReferences()) {
				TransportSalesHeader salesHeader;
				if (mixedReference.startsWith("ACA-FC"))
					salesHeader = salesRepo.getOne(mixedReference);
				else if (mixedReference.startsWith("CMV"))
					salesHeader = salesRepo.findByOrderNum(mixedReference);
				else
					salesHeader = null;

				header.putInvoice(mixedReference, salesHeader);
			}

			// infer Customer from already matched invoices
			String customerErpReference = null;
			for (Entry<String, TransportSalesHeader> entry : header.getInvoices().entrySet()) {
				TransportSalesHeader salesHeader = entry.getValue();

				// for every invoice present in system...
				if (salesHeader != null) {
					if (customerErpReference == null) {
						customerErpReference = salesHeader.getCustomerErpReference();
					} else {
						// if customer already found, check consistency
						if (!customerErpReference.equals(salesHeader.getCustomerErpReference()))
							customerErpReference = "(???)";
					}
				}
			}
			header.setCustomerErpReference(customerErpReference);
		}

		return headers.stream();
	}

	/**
	 *
	 * Persist the user entry on one row of Transport Costs Control.
	 * @param id - the one on TransportPurchaseHeader
	 * @param row - TransportPurchaseHeader is never saved per-se, so it is really a convenient
	 *              wrapper for *saving* its 1-to-1 writable counterpart, InputControlCosts.
	 * @return
	 */
	@PUT
	@Path("/{id}")
	@Consumes(value = MediaType.APPLICATION_JSON)
	@Produces(value = MediaType.APPLICATION_JSON)
	public Response saveOne(@PathParam("id") Long id, TransportPurchaseHeader row) {
		try {
			TransportPurchaseRepository repo = TransportPurchaseRepository.getInstance(em);
			TransportPurchaseHeader header = repo.findById(id);

			// As a wrapper, TransportSalesHeader itself will not be updated.

			InputControlCosts realPayload = row.getUserInputs();
			if (realPayload == null)
				return Response.noContent().build();
			else
				realPayload.setHeader(header);

			InputControlCosts saved;
			if (realPayload.getId() == null) {
				em.persist(realPayload);
				saved = realPayload;
			} else {
				saved = em.merge(realPayload);
			}
			em.flush();

			row.setUserInputs(saved);
			// all others are just irrelevent, we send them back unchanged.

			return Response.ok(row).build();
		} catch (IllegalArgumentException exc) {
			return WSUtils.response(Status.BAD_REQUEST, servReq, exc.getMessage());
		} catch (jakarta.persistence.PersistenceException exc) {
			return ApplicationConfig.response(exc, servReq, InputControlRevenue.class);
		}
	}


}
