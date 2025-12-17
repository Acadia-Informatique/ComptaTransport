package com.acadiainfo.comptatransport.fileimport;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.ListIterator;
import java.util.Set;

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

	/* ========== Amount total and details ========== */
	@Column(name = "total_amount")
	private BigDecimal totalAmount;

	@OneToMany(fetch = FetchType.EAGER, cascade = jakarta.persistence.CascadeType.PERSIST, mappedBy = "parent")
	private Set<ImportTransportAcheteDetail> details = new HashSet<ImportTransportAcheteDetail>();

	/* ========== Invoice links ========== */
	@Convert(disableConversion = true)
	@ElementCollection
	@CollectionTable(name = "MAP_TRANSPORT_INVOICE", joinColumns = @JoinColumn(name = "tr_achete_id"))
	@Column(name = "doc_reference")
	private List<String> resolvedDocReferences;

	/**
	 * Resolve a list of docReferences (aka Acadia Invoice numbers) from a single "custom reference" from the carrier.
	 * Based on the writing habits at "ACADIA Logistique" department.
	 * Implem. note : I wished Java was better suited to recursivity...
	 * @param internalReference - usually just the invoice number, but can be a sophisticated "list" of them.
	 * @return
	 */
	private static List<String> resolveInternalReferences(String internalReference) {
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

		return resolved;
	}


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
		this.resolvedDocReferences = resolveInternalReferences(this.internalReference);
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

	public BigDecimal getTotalAmount() {
		return totalAmount;
	}

	public void setTotalAmount(BigDecimal totalAmount) {
		this.totalAmount = totalAmount;
	}

	public Set<ImportTransportAcheteDetail> getDetails() {
		return details;
	}

	public void setDetails(Set<ImportTransportAcheteDetail> details) {
		this.details = details;
	}

}
