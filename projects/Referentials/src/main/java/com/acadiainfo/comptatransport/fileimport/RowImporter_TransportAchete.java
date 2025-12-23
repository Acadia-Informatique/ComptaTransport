package com.acadiainfo.comptatransport.fileimport;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.ListIterator;
import java.util.Map;
import java.util.TreeSet;
import java.util.regex.Matcher;

import com.acadiainfo.comptatransport.domain.InputControlCosts;
import com.acadiainfo.comptatransport.domain.MapTransportInvoice;
import com.acadiainfo.comptatransport.domain.TransportPurchaseHeader;

import jakarta.persistence.EntityManager;

/**
 *
 * TODO currently based on ImportTransportAchete entity only.
 * Quite Q&D... esp. the internal state.
 */
public class RowImporter_TransportAchete {

	private int importedCount;

	private EntityManager em;
	private Import importHeader;
	private Map<String, ArticleTransportAchete> refArticles;

	/*
	 * TODO : Constructor intended was something like : public
	 * RowImporter(ConfigImport config)
	 */

	public RowImporter_TransportAchete(EntityManager em, Import importHeader, Map<String, ArticleTransportAchete> refArticles) {
		this.em = em;
		this.importHeader = importHeader;
		this.refArticles = refArticles;

		this.importedCount = 0;
	}

	private static final java.util.regex.Pattern SUBARTICLE_PATTERN = java.util.regex.Pattern
	    .compile("^SUBARTICLE@(\\w+)$");

	public void process(Map<String, Object> rowData) {
		ImportTransportAchete entity = new ImportTransportAchete();

		entity.setImportHeader(this.importHeader);

		String articlePath = rowData.get("ARTICLE_COMPANY") + "/" + rowData.get("ARTICLE_ITEM");
		ArticleTransportAchete articleObj = refArticles.get(articlePath);
		if (articleObj == null)
			throw new IllegalStateException("ArticleTransportAchete not found with path : " + articlePath);
		entity.setArticle(articleObj);

		entity.setCarrierInvoiceNum((String) rowData.get("CARRIER_INVOICE_NUM"));
		entity.setCarrierInvoiceDate((LocalDateTime) rowData.get("CARRIER_INVOICE_DATE"));
		entity.setCarrierOrderNum((String) rowData.get("CARRIER_ORDER_NUM"));
		entity.setCarrierOrderDate((LocalDateTime) rowData.get("CARRIER_ORDER_DATE"));

		entity.setShipCustomerLabel((String) rowData.get("SHIP_CUSTOMER_LABEL"));
		entity.setShipCountry((String) rowData.get("SHIP_COUNTRY"));
		entity.setShipZipcode((String) rowData.get("SHIP_ZIPCODE"));
		entity.setShipComment((String) rowData.get("SHIP_COMMENT"));

		entity.setInternalReference((String) rowData.get("INTERNAL_REFERENCE"));

		entity.setReqTotalWeight((BigDecimal) rowData.get("REQ_TOTAL_WEIGHT"));
		entity.setTotalWeight((BigDecimal) rowData.get("TOTAL_WEIGHT"));
		entity.setShipComment((String) rowData.get("SHIP_COMMENT"));

		BigDecimal parcelCount = (BigDecimal) rowData.get("PARCEL_COUNT");
		entity.setParcelCount(parcelCount == null ? null : parcelCount.intValue());

		entity.setTotalAmount((BigDecimal) rowData.get("TOTAL_AMOUNT"));
		for (String key : rowData.keySet()) {
			Matcher matcher = SUBARTICLE_PATTERN.matcher(key);
			if (matcher.matches()) {
				String fragment = matcher.group(1);

				String subarticleName = (String) rowData.get(key);
				BigDecimal amount = (BigDecimal) rowData.get("AMOUNT@" + fragment);
				if (amount == null || amount.equals(BigDecimal.ZERO))
					continue; // not inserting sub-article for zero amount

				ImportTransportAcheteDetail detail = new ImportTransportAcheteDetail();
				detail.setParent(entity);
				detail.setSubarticleName(subarticleName);
				detail.setAmount(amount);

				entity.getDetails().add(detail);
			}
		}
		this.em.persist(entity);
		em.flush();

		// -----------------
		// Specific to Contrôle Mensuel : user inputs entity is pre-created at import
		InputControlCosts userInputs = new InputControlCosts();

		// Note : TransportPurchaseHeader is a readonly view of the very entity we just
		// persisted
		TransportPurchaseHeader header = em.find(TransportPurchaseHeader.class, entity.getId());
		userInputs.setHeader(header);
		userInputs.setMappedInvoices(resolveInternalReferences(entity.getInternalReference()));
		em.persist(userInputs);
		em.flush();

		this.importedCount++;
	}

	public int getImportedCount() {
		return importedCount;
	}

	/**
	 * Resolve a list of docReferences (aka Acadia Invoice numbers) from a single "custom reference" from the carrier.
	 * Based on the writing habits at "ACADIA Logistique" department.
	 * Implem. note : I wished Java was better suited to recursivity...
	 * @param internalReference - usually just the invoice number, but can be a sophisticated "list" of them.
	 * @return
	 */
	private static TreeSet<MapTransportInvoice> resolveInternalReferences(String internalReference) {
		List<String> resolved = new java.util.ArrayList<>();

		// rule 1 : 1st one serves as base.
		List<String> splitted = java.util.Arrays.asList(internalReference.split("-|/"));
		String baseReference = splitted.getFirst();
		resolved.add(baseReference);

		// rule 1a : and it is ALWAYS complete.
		int baseLength = baseReference.length();

		// rule 2 : from the 2nd split fragment...
		for (String fragm : splitted.subList(1, splitted.size())) {

			// rule 2-a : ... each a fragment replace the *end* of the current base
			// reference
			if (fragm.length() < baseLength) {
				String padding = baseReference.substring(0, baseLength - fragm.length());

				// rule 2-b : each resolved reference serves as base for the next one
				baseReference = padding + fragm;
				resolved.add(baseReference);
			}
		}

		// rule 3 : the invoice numbers rarely contains"ACA-" prefix.
		ListIterator<String> iter = resolved.listIterator();
		while (iter.hasNext()) {
			String candidate = iter.next();
			if (candidate.startsWith("ACA-FC")) {
				// "Complete" invoice number, almost never the case. Leave it alone.
			} else if (candidate.startsWith("CMV")) {
				// Order number, sometimes wrongly used (e.g. by newcomers). Leave it alone.
			} else if (candidate.startsWith("FC")) {
				// The common case. Add the prefix for conformity.
				iter.set("ACA-" + candidate);
			} else {
				// we are doomed. Again.
				// Or maybe it was another prefix well-formed one, with a different prefix (e.g.
				// for Ittelix).
			}
		}

		TreeSet<MapTransportInvoice> result = new TreeSet<>();
		for (String orig : resolved) {
			MapTransportInvoice mti = new MapTransportInvoice();
			mti.setOriginalReference(orig);
			mti.setDocReference(orig);
			result.add(mti);
		}
		return result;
	}

}
