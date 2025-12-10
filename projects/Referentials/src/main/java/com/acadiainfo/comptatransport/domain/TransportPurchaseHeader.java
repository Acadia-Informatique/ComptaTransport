package com.acadiainfo.comptatransport.domain;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import com.acadiainfo.comptatransport.fileimport.ArticleTransportAchete;
import com.acadiainfo.comptatransport.fileimport.Import;
import com.acadiainfo.comptatransport.fileimport.ImportTransportAcheteDetail;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;

/**
 * This is a read-only view of imported rows as Transport purchase HEADERS.
 *
 * It could be dismissed as a mostly duplicate of ImportTransportAchete, but it was created
 * for the sake of symmetry with the pair ImportTransportVendu (=file import) / TransportSalesHeader (=displayed).
 *
 * @see com.acadiainfo.comptatransport.fileimport.ImportTransportAchete
 */

@Table(schema = "ComptaTransport", name = "I_TRANSPORT_ACHETE")
@Entity
public class TransportPurchaseHeader {

	/** Tech. PK */
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "id")
	private Long id;

	@jakarta.json.bind.annotation.JsonbTransient
	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "import_id", referencedColumnName = "id", nullable = false, updatable = false)
	private Import importHeader;

	@jakarta.json.bind.annotation.JsonbTransient
	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "article_id", referencedColumnName = "id", nullable = false, updatable = false)
	private ArticleTransportAchete article;

	/* ===== Carrier Invoice references ======== */
	// they are not really used, other for deduplicating and... human inferences.

	@Column(name = "carrier_invoice_num")
	private String carrierInvoiceNum;

	@Column(name = "carrier_invoice_date")
	private LocalDateTime carrierInvoiceDate;

	@Column(name = "carrier_order_num")
	private String carrierOrderNum;

	@Column(name = "carrier_order_date")
	private LocalDateTime carrierOrderDate;

	/* ===== link to "Transport Vendu" === */

	/**
	 * Can be one or more Invoice or Order reference from ERP, in a... hard to predict format.
	 * Will be resolved later and persisted in "doc_reference_list" database column.
	 */
	@Column(name = "internal_reference")
	private String internalReference;

	/* ===== shipping address ========== */

	@Column(name = "ship_customer_label")
	private String shipCustomerLabel;

	@Column(name = "ship_country")
	private String shipCountry;

	@Column(name = "ship_zipcode")
	private String shipZipcode;

	@Column(name = "ship_comment")
	private String shipComment;

	/* ====== Order packaging info ========= */

	/**
	 * Requested weight = what the customer (= ACADIA) declared.
	 */
	@Column(name = "req_total_weight")
	private BigDecimal reqTotalWeight;

	/**
	 * Actual Weight = what the carrier used as reference for pricing (may be the same as declared).
	 */
	@Column(name = "total_weight")
	private BigDecimal totalWeight;

	/**
	 * Sometimes the carrier give that as feedback (or to justify the price).
	 */
	@Column(name = "parcel_count")
	private Integer parcelCount;

	/* ========== Amount details ========== */
	@jakarta.json.bind.annotation.JsonbTransient
	@OneToMany(fetch = FetchType.EAGER, cascade = jakarta.persistence.CascadeType.PERSIST, mappedBy = "parent")
	private Set<ImportTransportAcheteDetail> details = new HashSet<ImportTransportAcheteDetail>();

	/* ========== Invoice links ========== */
	@Convert(disableConversion = true)
	@ElementCollection
	@CollectionTable(name = "MAP_TRANSPORT_INVOICE", joinColumns = @JoinColumn(name = "tr_achete_id"))
	@Column(name = "doc_reference")
	private List<String> resolvedDocReferences = new java.util.ArrayList<>();

	public java.util.Map<String, Object> getTestMap() {
		var map = new java.util.HashMap<String, Object>();
		map.put("arf", Integer.MAX_VALUE);
		map.put("erf", new java.util.Date());
		return map;
	}

	public Long getId() {
		return id;
	}

	public Import getImportHeader() {
		return importHeader;
	}

	public ArticleTransportAchete getArticle() {
		return article;
	}

	public String getCarrierInvoiceNum() {
		return carrierInvoiceNum;
	}

	public LocalDateTime getCarrierInvoiceDate() {
		return carrierInvoiceDate;
	}

	public String getCarrierOrderNum() {
		return carrierOrderNum;
	}

	public LocalDateTime getCarrierOrderDate() {
		return carrierOrderDate;
	}

	public String getInternalReference() {
		return internalReference;
	}

	public String getShipCustomerLabel() {
		return shipCustomerLabel;
	}

	public String getShipCountry() {
		return shipCountry;
	}

	public String getShipZipcode() {
		return shipZipcode;
	}

	public String getShipComment() {
		return shipComment;
	}

	public BigDecimal getReqTotalWeight() {
		return reqTotalWeight;
	}

	public BigDecimal getTotalWeight() {
		return totalWeight;
	}

	public Integer getParcelCount() {
		return parcelCount;
	}

	public Set<ImportTransportAcheteDetail> getDetails() {
		return details;
	}

	public List<String> getResolvedDocReferences() {
		return resolvedDocReferences;
	}


}

