package com.acadiainfo.comptatransport.domain;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

import com.acadiainfo.comptatransport.fileimport.ArticleTransportAchete;
import com.acadiainfo.comptatransport.fileimport.ImportTransportAcheteDetail;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;

/**
 * This is a read-only view of imported rows as Transport purchase HEADERS.
 *
 * It could be dismissed as a (mostly) duplicate of ImportTransportAchete, but it was created
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

	@ManyToOne
	@JoinColumn(name = "article_id", referencedColumnName = "id", nullable = false, updatable = false)
	private ArticleTransportAchete article;

	/* ===== Carrier Invoice references ======== */
	// they are not really used, other for deduplicating and... human inferences.

	@Column(name = "carrier_invoice_num", insertable = false, updatable = false)
	private String carrierInvoiceNum;

	@Column(name = "carrier_invoice_date", insertable = false, updatable = false)
	private LocalDateTime carrierInvoiceDate;

	@Column(name = "carrier_order_num", insertable = false, updatable = false)
	private String carrierOrderNum;

	@Column(name = "carrier_order_date", insertable = false, updatable = false)
	private LocalDateTime carrierOrderDate;

	/* ===== link to "Transport Vendu" === */

	/**
	 * Can be one or more Invoice or Order reference from ERP, in a... hard to predict format.
	 * Will be resolved later and persisted in "doc_reference_list" database column.
	 */
	@Column(name = "internal_reference", insertable = false, updatable = false)
	private String internalReference;

	/* ===== shipping address ========== */

	@Column(name = "ship_customer_label", insertable = false, updatable = false)
	private String shipCustomerLabel;

	@Column(name = "ship_country", insertable = false, updatable = false)
	private String shipCountry;

	@Column(name = "ship_zipcode", insertable = false, updatable = false)
	private String shipZipcode;

	@Column(name = "ship_comment", insertable = false, updatable = false)
	private String shipComment;

	/* ====== Order packaging info ========= */

	/**
	 * Requested weight = what the customer (= ACADIA) declared.
	 */
	@Column(name = "req_total_weight", insertable = false, updatable = false)
	private BigDecimal reqTotalWeight;

	/**
	 * Actual Weight = what the carrier used as reference for pricing (may be the same as declared).
	 */
	@Column(name = "total_weight", insertable = false, updatable = false)
	private BigDecimal totalWeight;

	/**
	 * Sometimes the carrier give that as feedback (or to justify the price).
	 */
	@Column(name = "parcel_count", insertable = false, updatable = false)
	private Integer parcelCount;

	/* ========== Amount total and details ========== */
	@Column(name = "total_amount", insertable = false, updatable = false)
	private BigDecimal totalAmount;

	@OneToMany(mappedBy = "parent", fetch = FetchType.EAGER) // + JOIN FETCH in repository query
	private Set<ImportTransportAcheteDetail> details = new HashSet<ImportTransportAcheteDetail>();


	/** The user inputs from Contrôle Mensuel (costs control) */
	@OneToOne(optional = true, mappedBy = "header", fetch = FetchType.EAGER) // + JOIN FETCH in repository query
	private InputControlCosts userInputs;


	public Long getId() {
		return id;
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

	public BigDecimal getTotalAmount() {
		return totalAmount;
	}

	/**
	 * Not serialized to JSON, but transferred using a somewhat more compact form.
	 * (And also feeling guilty about using a fileimport package object here.)
	 * @see TransportPurchaseHeader#getDetailAmounts()
	 * @return
	 */
	@jakarta.json.bind.annotation.JsonbTransient
	public Set<ImportTransportAcheteDetail> getDetails() {
		return details;
	}

	public InputControlCosts getUserInputs() {
		return userInputs;
	}

	public void setUserInputs(InputControlCosts userInputs) {
		this.userInputs = userInputs;
	}

	// ============================
	// Serializing from ImportTransportAcheteDetail to amounts...

	public java.util.Map<String, BigDecimal> getDetailAmounts() {
		if (this.details == null) return null;
		var detailAmounts = new java.util.HashMap<String, BigDecimal>();
		for (ImportTransportAcheteDetail detail : this.details) {
			detailAmounts.put(detail.getSubarticleName(), detail.getAmount());
		}
		return detailAmounts;
	}


	// ------------------------------
	// Computed not JPA-mapped

	@jakarta.persistence.Transient
	private String customerErpReference;

	public String getCustomerErpReference() {
		return customerErpReference;
	}

	public void setCustomerErpReference(String customerErpReference) {
		this.customerErpReference = customerErpReference;
	}

	// -------------------------------
	/** minimal version for JSON version of
	 * {@link TransportSalesHeader#getMappedPurchase()}
	 *
	 * @param id
	 */
	public TransportPurchaseHeader asRef() {
		TransportPurchaseHeader ref = new TransportPurchaseHeader();
		ref.id = this.id;
		ref.carrierInvoiceDate = this.carrierInvoiceDate;
		ref.carrierInvoiceNum = this.carrierInvoiceNum;
		ref.carrierOrderDate = this.carrierOrderDate;
		ref.carrierOrderNum = this.carrierOrderNum;
		ref.details = null;
		return ref;
	}

}

