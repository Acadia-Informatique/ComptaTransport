package com.acadiainfo.comptatransport.fileimport;

import java.math.BigDecimal;
import java.net.URI;
import java.net.URISyntaxException;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.regex.Matcher;

import jakarta.persistence.Column;
import jakarta.persistence.EntityManager;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;

/**
 *
 * TODO currently based on ImportTransportAchete entity only.
 * Quite Q&D... esp. the internal state.
 */
public class RowImporter {

	private EntityManager em;
	private Import importHeader;
	private Map<String, ArticleTransportAchete> refArticles;

	/*
	 * TODO : Constructor intended was something like : public
	 * RowImporter(ConfigImport config)
	 */

	public RowImporter(EntityManager em, Import importHeader, Map<String, ArticleTransportAchete> refArticles) {
		this.em = em;
		this.importHeader = importHeader;
		this.refArticles = refArticles;
	}

	private static final java.util.regex.Pattern SSARTICLE_PATTERN = java.util.regex.Pattern
	    .compile("^SSARTICLE@(\\w+)$");

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

		for (String key : rowData.keySet()) {
			Matcher matcher = SSARTICLE_PATTERN.matcher(key);
			if (matcher.matches()) {
				String fragment = matcher.group(1);

				String ssarticleName = (String) rowData.get(key);
				BigDecimal amount = (BigDecimal) rowData.get("AMOUNT@" + fragment);

				ImportTransportAcheteDetail detail = new ImportTransportAcheteDetail();
				detail.setParent(entity);
				detail.setSsarticleName(ssarticleName);
				detail.setAmount(amount);

				entity.getDetails().add(detail);
			}
		}

		this.em.persist(entity);
	}
}
