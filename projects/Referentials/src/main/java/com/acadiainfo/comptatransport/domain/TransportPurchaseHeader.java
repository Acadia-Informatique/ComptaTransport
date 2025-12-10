package com.acadiainfo.comptatransport.domain;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

import jakarta.json.bind.annotation.JsonbProperty;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.NamedNativeQuery;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OneToOne;

/**
 * This is a read-only view of imported rows as Transport sales HEADERS.
 * The mapping of import (ImportTransportVendu) is split between this and {@link TransportSalesDetails}.
 *
 * It consists on GROUP BY of the imported rows, from any of the TransportSalesHeader_as_XXX named queries.
 *
 * @see com.acadiainfo.comptatransport.fileimport.ImportTransportVendu
 */

public class TransportPurchaseHeader {

	/**
	 * Marks as "Group" the entities where "doc_reference" (= invoice) starts with this.
	 */
	public static final String GROUPREF_PREFIX = "{";

	/** Virtual PK, "view" entity is never persisted as is.
	 * Using it as identifier allow us to postpone the choice between instance being an Order or an Invoice... indefinitely. */
	@Id
	@Column(name = "id")
	private Long id;

	@JsonbProperty("order")
	@Column(name = "order_reference", insertable = false, updatable = false)
	private String orderReference;

	@JsonbProperty("invoice")
	@Column(name = "doc_reference", insertable = false, updatable = false)
	private String docReference;

	@JsonbProperty("invoice_orig")
	@Column(name = "orig_doc_reference", insertable = false, updatable = false)
	private String origDocReference;

	/** Note : since CUSTOMER table contains only those with an "interesting" profile regarding Transport,
	 * this relationship is mostly empty. */
	@ManyToOne(fetch = FetchType.EAGER)
	@JoinColumn(name = "customer_id", nullable = true, insertable = false, updatable = false)
	private Customer customer;

	@JsonbProperty("customerRef")
	@Column(name = "customer_erp_reference", insertable = false, updatable = false)
	private String customerErpReference;

	@Column(name = "customer_label", insertable = false, updatable = false)
	private String customerLabel;

	@JsonbProperty("carrier")
	@Column(name = "carrier_name", insertable = false, updatable = false)
	private String carrierName;

	@JsonbProperty("country")
	@Column(name = "ship_country", insertable = false, updatable = false)
	private String shipCountry;

	@JsonbProperty("zip")
	@Column(name = "ship_zipcode", insertable = false, updatable = false)
	private String shipZipcode;

	@JsonbProperty("date")
	@Column(name = "doc_date", insertable = false, updatable = false)
	private LocalDateTime docDate;

	@Column(name = "salesrep", insertable = false, updatable = false)
	private String salesrep;

	@Column(name = "is_b2c", insertable = false, updatable = false)
	private Boolean b2c;

	@JsonbProperty("weight")
	@Column(name = "total_weight", insertable = false, updatable = false)
	private BigDecimal totalWeight;

	/** All the Transport product details associated to the header (=Order/Invoice) */
	@OneToMany(fetch = FetchType.EAGER)
	@JoinColumn(name = "doc_reference", referencedColumnName = "doc_reference")
	private Set<TransportSalesDetails> details = new HashSet<TransportSalesDetails>();

	/** The user inputs from Contrôle Quotidien (revenue control) */
	@OneToOne(optional = true)
	@JoinColumn(name = "doc_reference", referencedColumnName = "doc_reference")
	// note : The Join columns *now* is the doc_reference, since the header
	// represents an Invoice (it could have been an Order).
	private InputControlRevenue userInputs;


	// Note : even for this non-writable entity we still have setters.
	// For instance, in TransportSalesWS.saveOne(), they are needed for :
	// - parsing the JSON request payload
	// - making the JSON response lighter


	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public String getOrderReference() {
		return orderReference;
	}

	public void setOrderReference(String orderReference) {
		this.orderReference = orderReference;
	}

	public String getDocReference() {
		return docReference;
	}

	public void setDocReference(String docReference) {
		this.docReference = docReference;
	}

	/** only serialize if useful */
	public String getOrigDocReference() {
		return !this.docReference.equals(this.origDocReference) ? this.origDocReference : null;
	}

	public void setOrigDocReference(String origDocReference) {
		this.origDocReference = origDocReference;
	}

	/**
	 * BTW, correlated with non-null getOrigDocReference.
	 * @return true or null (for lighter JSON payload)
	 */
	@JsonbProperty("isGroup")
	public Boolean isGroup() {
		return (this.docReference.startsWith(GROUPREF_PREFIX)) ? Boolean.TRUE : null;
	}

	public Customer getCustomer() {
		return customer;
	}

	public void setCustomer(Customer customer) {
		this.customer = customer;
	}

	public String getCustomerErpReference() {
		return customerErpReference;
	}

	public void setCustomerErpReference(String customerErpReference) {
		this.customerErpReference = customerErpReference;
	}

	public String getCustomerLabel() {
		return customerLabel;
	}

	public void setCustomerLabel(String customerLabel) {
		this.customerLabel = customerLabel;
	}

	public String getCarrierName() {
		return carrierName;
	}

	public void setCarrierName(String carrierName) {
		this.carrierName = carrierName;
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

	public LocalDateTime getDocDate() {
		return docDate;
	}

	public void setDocDate(LocalDateTime docDate) {
		this.docDate = docDate;
	}


	public String getSalesrep() {
		return salesrep;
	}


	public void setSalesrep(String salesrep) {
		this.salesrep = salesrep;
	}

	/** TODO currently deemed unusable, need better qualification at source (from ERP X3 ? SEI report ?...)
	 * Until we find a better way to qualify B2C orders from X3,
	 * we are using the same heuristics from the original Excel spreadsheet.
	 * So we cannot apply B2C price grids until the human users *are* applying it themselves,
	 * which defeats the very meaning of a control ;-) */
	public Boolean isB2c() {
		// return b2c;

		if (customer != null) {
			boolean isCustomerB2C = customer.getTags().contains("Dropshipper");
			// if a customer is a Dropshipping pure player,
			// everything it sells is deemed B2C.
			if (isCustomerB2C) return true;
		}

		if (details != null) {
			boolean orderhasB2C = details.stream()
			    .anyMatch(det -> det.getProductType() == TransportSalesDetails.ProductType.B2C);
			return orderhasB2C;
		}
		return null;
	}

	public void setB2c(Boolean b2c) {
		this.b2c = b2c;
	}

	public BigDecimal getTotalWeight() {
		return totalWeight;
	}

	public void setTotalWeight(BigDecimal totalWeight) {
		this.totalWeight = totalWeight;
	}

	public Set<TransportSalesDetails> getDetails() {
		return details;
	}

	public void setDetails(Set<TransportSalesDetails> details) {
		this.details = details;
	}

	public InputControlRevenue getUserInputs() {
		return userInputs;
	}

	public void setUserInputs(InputControlRevenue userInputs) {
		this.userInputs = userInputs;
	}

	/**
	 * New computed property : total price of details
	 * @return
	 */
	@JsonbProperty("price")
	public BigDecimal getTotalPrice() {
		if (this.details == null) return null;

		BigDecimal sum = BigDecimal.ZERO;
		for (TransportSalesDetails detailsItem : this.details) {
			sum = sum.add(detailsItem.getTotalPrice());
		}
		return sum;
	}

}
