package com.acadiainfo.comptatransport.domain;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;
import java.util.TreeSet;

import jakarta.json.bind.annotation.JsonbProperty;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.NamedNativeQuery;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;

/**
 * This is a read-only view of imported rows as Transport sales HEADERS.
 * The mapping of import (ImportTransportVendu) is split between this and {@link TransportSalesDetails}.
 *
 * It consists on GROUP BY of the imported rows, from any of the TransportSalesHeader_as_XXX named queries.
 *
 * @see com.acadiainfo.comptatransport.fileimport.ImportTransportVendu
 */

@NamedNativeQuery(name = "TransportSalesHeader_as_INVOICE", query = """
    select
    max(id) as id,
    doc_reference,
    group_concat(order_reference ORDER BY order_reference SEPARATOR ';' ) as order_reference,
    max(customer_erp_reference) as customer_erp_reference,
    max(customer_label) as customer_label,
    max(carrier_name) as carrier_name,
    max(ship_country) as ship_country,
    max(ship_zipcode) as ship_zipcode,
    max(doc_date) as doc_date,
    max(salesrep) as salesrep,
    sum(total_weight) as total_weight
    from (
    	select
    	max(id) as id,
    	doc_reference, order_reference,
    	max(customer_erp_reference) as customer_erp_reference,
    	max(customer_label) as customer_label,
    	max(carrier_name) as carrier_name,
    	max(ship_country) as ship_country,
    	max(ship_zipcode) as ship_zipcode,
    	max(doc_date) as doc_date,
    	max(salesrep) as salesrep,
    	max(total_weight) as total_weight
    	from I_TRANSPORT_VENDU
    	where doc_date >= ?1 and doc_date < ?2
    	group by doc_reference, order_reference
    ) as V_TRANSPORT_ORDER
    group by doc_reference
       """, resultClass = TransportSalesHeader.class)
/*
 * @NamedNativeQuery(name = "TransportSalesHeader_as_ORDER", query = """ select
 * max(id) as id, doc_reference, order_reference, max(customer_erp_reference) as
 * customer_erp_reference, max(customer_label) as customer_label,
 * max(carrier_name) as carrier_name, max(ship_country) as ship_country,
 * max(ship_zipcode) as ship_zipcode, max(doc_date) as doc_date, max(salesrep)
 * as salesrep, max(total_weight) as total_weight from I_TRANSPORT_VENDU where
 * doc_date >= ?1 and doc_date < ?2 group by doc_reference, order_reference """,
 * resultClass = TransportSalesHeader.class)
 */
@Entity
public class TransportSalesHeader {
	/** Tech. PK */
	@Id
	@Column(name = "id")
	private Long id;

	@Column(name = "order_reference", insertable = false, updatable = false)
	private String orderReference;

	@Column(name = "doc_reference", insertable = false, updatable = false)
	private String docReference;

	@Column(name = "customer_erp_reference", insertable = false, updatable = false)
	private String customerErpReference;

	@Column(name = "customer_label", insertable = false, updatable = false)
	private String customerLabel;

// TODO currently deemed unusable, need better qualification at source (from ERP X3 ? SEI report ?...)
//	@Column(name = "is_b2c", insertable = false, updatable = false)
//	private boolean b2c;

	@Column(name = "carrier_name", insertable = false, updatable = false)
	private String carrierName;

	@Column(name = "ship_country", insertable = false, updatable = false)
	private String shipCountry;

	@Column(name = "ship_zipcode", insertable = false, updatable = false)
	private String shipZipcode;

	@Column(name = "doc_date", insertable = false, updatable = false)
	private LocalDateTime docDate;

	@Column(name = "salesrep", insertable = false, updatable = false)
	private String salesrep;

	@Column(name = "total_weight", insertable = false, updatable = false)
	private BigDecimal totalWeight;

	/** All the Transport product details associated to the header (=Order/Invoice) */
	@OneToMany(fetch = FetchType.EAGER)
	@JoinColumn(name = "doc_reference", referencedColumnName = "doc_reference")
	private Set<TransportSalesDetails> details = new HashSet<TransportSalesDetails>();

	public Long getId() {
		return id;
	}

	@JsonbProperty("order")
	public String getOrderReference() {
		return orderReference;
	}

	@JsonbProperty("invoice")
	public String getDocReference() {
		return docReference;
	}

	@JsonbProperty("customer")
	public String getCustomerErpReference() {
		return customerErpReference;
	}

	public String getCustomerLabel() {
		return customerLabel;
	}

	@JsonbProperty("carrier")
	public String getCarrierName() {
		return carrierName;
	}

	@JsonbProperty("country")
	public String getShipCountry() {
		return shipCountry;
	}

	@JsonbProperty("zip")
	public String getShipZipcode() {
		return shipZipcode;
	}

	@JsonbProperty("date")
	public LocalDateTime getDocDate() {
		return docDate;
	}

	public String getSalesrep() {
		return salesrep;
	}

	@JsonbProperty("weight")
	public BigDecimal getTotalWeight() {
		return totalWeight;
	}

	public Set<TransportSalesDetails> getDetails() {
		return details;
	}

	@JsonbProperty("price")
	public BigDecimal getTotalPrice() {
		BigDecimal sum = BigDecimal.ZERO;
		for (TransportSalesDetails detailsItem : this.details) {
			sum = sum.add(detailsItem.getTotalPrice());
		}
		return sum;
	}
}
