package com.acadiainfo.comptatransport.fileimport;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.acadiainfo.comptatransport.domain.Customer;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.NamedNativeQuery;
import jakarta.persistence.NamedQuery;
import jakarta.persistence.Table;

@NamedQuery(name = "ImportTransportVendu.purgePrevious", query = """
    DELETE FROM ImportTransportVendu imp
    where imp.docReference = :docReference
      and imp.importHeader <> :importHeader
    """)

@NamedNativeQuery(name = "ImportTransportVendu_as_new_Customers", query = """
    select
        itv.customer_erp_reference as erp_reference,
        MAX(itv.customer_label) as label,
        MAX(itv.salesrep) as salesrep,
    	MAX(all_customers.id) + min(itv.id) as id
    from I_TRANSPORT_VENDU itv
    left outer join CUSTOMER on itv.customer_erp_reference = CUSTOMER.erp_reference
      inner join CUSTOMER all_customers
    where CUSTOMER.id is NULL
      and itv.import_id = ?1
    group by itv.customer_erp_reference
      """, resultClass = Customer.class)

@NamedQuery(name = "ImportTransportVendu.groupTo", query = """
	UPDATE ImportTransportVendu imp
	SET imp.docReference = :groupDocReference
	where imp.docReference = :docReference
""")
@NamedQuery(name = "ImportTransportVendu.ungroup", query = """
	UPDATE ImportTransportVendu imp
	SET imp.docReference = imp.origDocReference
	where imp.docReference = :groupDocReference
""")

@Entity
@Table(schema = "ComptaTransport", name = "I_TRANSPORT_VENDU")
public class ImportTransportVendu {
	/** Tech. PK */
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "id")
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "import_id", referencedColumnName = "id", nullable = false, updatable = false)
	private Import importHeader;

	@Column(name = "code_societe")
	private String codeSociete;

	@Column(name = "order_reference")
	private String orderReference;

	@Column(name = "doc_reference")
	private String docReference;

	@Column(name = "orig_doc_reference")
	private String origDocReference;

	@Column(name = "customer_erp_reference")
	private String customerErpReference;

	@Column(name = "customer_label")
	private String customerLabel;

	@Column(name = "product_desc")
	private String productDesc;

	@Column(name = "is_b2c")
	private boolean b2c;

	@Column(name = "carrier_name")
	private String carrierName;

	@Column(name = "ship_country")
	private String shipCountry;

	@Column(name = "ship_zipcode")
	private String shipZipcode;

	@Column(name = "doc_date")
	private LocalDateTime docDate;

	@Column(name = "salesrep")
	private String salesrep;

	@Column(name = "salesrep2")
	private String salesrep2;

	@Column(name = "total_weight")
	private BigDecimal totalWeight;

	@Column(name = "total_price")
	private BigDecimal totalPrice;


	public Import getImportHeader() {
		return importHeader;
	}

	public void setImportHeader(Import importHeader) {
		this.importHeader = importHeader;
	}

	public String getCodeSociete() {
		return codeSociete;
	}

	public void setCodeSociete(String codeSociete) {
		this.codeSociete = codeSociete;
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

	public String getOrigDocReference() {
		return origDocReference;
	}

	public void setOrigDocReference(String origDocReference) {
		this.origDocReference = origDocReference;
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

	public String getProductDesc() {
		return productDesc;
	}

	public void setProductDesc(String productDesc) {
		this.productDesc = productDesc;
	}

	public boolean isB2c() {
		return b2c;
	}

	public void setB2c(boolean b2c) {
		this.b2c = b2c;
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

	public String getSalesrep2() {
		return salesrep2;
	}

	public void setSalesrep2(String salesrep2) {
		this.salesrep2 = salesrep2;
	}

	public BigDecimal getTotalWeight() {
		return totalWeight;
	}

	public void setTotalWeight(BigDecimal totalWeight) {
		this.totalWeight = totalWeight;
	}

	public BigDecimal getTotalPrice() {
		return totalPrice;
	}

	public void setTotalPrice(BigDecimal totalPrice) {
		this.totalPrice = totalPrice;
	}

}
