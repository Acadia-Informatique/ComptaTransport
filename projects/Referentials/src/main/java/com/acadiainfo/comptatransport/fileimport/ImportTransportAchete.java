package com.acadiainfo.comptatransport.fileimport;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;

@Entity
@Table(schema = "ComptaTransport", name = "I_TRANSPORT_ACHETE")
public class ImportTransportAchete {
	/** Tech. PK */
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "id")
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "import_id", referencedColumnName = "id", nullable = false, updatable = false)
	private Import importHeader;

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
	@OneToMany(fetch = FetchType.EAGER, cascade = jakarta.persistence.CascadeType.PERSIST, mappedBy = "parent")
	private Set<ImportTransportAcheteDetail> details = new HashSet<ImportTransportAcheteDetail>();

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public Import getImportHeader() {
		return importHeader;
	}

	public void setImportHeader(Import importHeader) {
		this.importHeader = importHeader;
	}

	public ArticleTransportAchete getArticle() {
		return article;
	}

	public void setArticle(ArticleTransportAchete article) {
		this.article = article;
	}

	public String getCarrierInvoiceNum() {
		return carrierInvoiceNum;
	}

	public void setCarrierInvoiceNum(String carrierInvoiceNum) {
		this.carrierInvoiceNum = carrierInvoiceNum;
	}

	public LocalDateTime getCarrierInvoiceDate() {
		return carrierInvoiceDate;
	}

	public void setCarrierInvoiceDate(LocalDateTime carrierInvoiceDate) {
		this.carrierInvoiceDate = carrierInvoiceDate;
	}

	public String getCarrierOrderNum() {
		return carrierOrderNum;
	}

	public void setCarrierOrderNum(String carrierOrderNum) {
		this.carrierOrderNum = carrierOrderNum;
	}

	public LocalDateTime getCarrierOrderDate() {
		return carrierOrderDate;
	}

	public void setCarrierOrderDate(LocalDateTime carrierOrderDate) {
		this.carrierOrderDate = carrierOrderDate;
	}

	public String getInternalReference() {
		return internalReference;
	}

	public void setInternalReference(String internalReference) {
		this.internalReference = internalReference;
	}

	public String getShipCustomerLabel() {
		return shipCustomerLabel;
	}

	public void setShipCustomerLabel(String shipCustomerLabel) {
		this.shipCustomerLabel = shipCustomerLabel;
	}

	public String getShipCountry() {
		return shipCountry;
	}

	public void setShipCountry(String shipCountry) {
		this.shipCountry = shipCountry;
	}

	public String getShipZipcode() {
		return shipZipcode;
	}

	public void setShipZipcode(String shipZipcode) {
		this.shipZipcode = shipZipcode;
	}

	public String getShipComment() {
		return shipComment;
	}

	public void setShipComment(String shipComment) {
		this.shipComment = shipComment;
	}

	public BigDecimal getReqTotalWeight() {
		return reqTotalWeight;
	}

	public void setReqTotalWeight(BigDecimal reqTotalWeight) {
		this.reqTotalWeight = reqTotalWeight;
	}

	public BigDecimal getTotalWeight() {
		return totalWeight;
	}

	public void setTotalWeight(BigDecimal totalWeight) {
		this.totalWeight = totalWeight;
	}

	public Integer getParcelCount() {
		return parcelCount;
	}

	public void setParcelCount(Integer parcelCount) {
		this.parcelCount = parcelCount;
	}

	public Set<ImportTransportAcheteDetail> getDetails() {
		return details;
	}

	public void setDetails(Set<ImportTransportAcheteDetail> details) {
		this.details = details;
	}

}
