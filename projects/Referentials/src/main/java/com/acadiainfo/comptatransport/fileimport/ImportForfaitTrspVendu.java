package com.acadiainfo.comptatransport.fileimport;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.acadiainfo.comptatransport.domain.AggShippingRevenue;
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

@NamedQuery(name = "ImportForfaitTrspVendu.purgePrevious", query = """
    DELETE FROM ImportForfaitTrspVendu imp
    where imp.docReference = :docReference
      and imp.importHeader <> :importHeader
    """)
@NamedNativeQuery(name = "ImportForfaitTrspVendu_as_new_Customers", query = """
    select
        iftv.customer_erp_reference as erp_reference,
        MAX(iftv.customer_label) as label,
        MAX(iftv.salesrep) as salesrep,
    	MAX(all_customers.id) + min(iftv.id) as id
    from I_FORFAIT_TRSP_VENDU iftv
    left outer join CUSTOMER on iftv.customer_erp_reference = CUSTOMER.erp_reference
      inner join CUSTOMER all_customers
    where CUSTOMER.id is NULL
      and iftv.import_id = ?1
    group by iftv.customer_erp_reference
      """, resultClass = Customer.class)

@NamedNativeQuery(name = "ImportForfaitTrspVendu_as_new_AggShippingRevenues", query = """
    select
    	max(iftv.id) as id,
    	CUSTOMER.id as customer_id,
    	'MONTHLY' as product,
    	STR_TO_DATE(CONCAT(DATE_FORMAT(doc_date,'%Y-%m'),'-01 00'),'%Y-%m-%d %H') as date,
    	sum(total_price) as amount
    from I_FORFAIT_TRSP_VENDU iftv
    inner join CUSTOMER on iftv.customer_erp_reference = CUSTOMER.erp_reference
    where iftv.product_code = '3810514051' and iftv.product_desc = 'Frais de port mensuel France'
      and iftv.import_id = ?1
    group by CUSTOMER.id, date
     """, resultClass = AggShippingRevenue.class)

@Entity
@Table(schema = "ComptaTransport", name = "I_FORFAIT_TRSP_VENDU")
public class ImportForfaitTrspVendu {
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

	@Column(name = "doc_reference")
	private String docReference;

	@Column(name = "customer_erp_reference")
	private String customerErpReference;

	@Column(name = "customer_label")
	private String customerLabel;

	@Column(name = "product_code")
	private String productCode;

	@Column(name = "product_desc")
	private String productDesc;

	@Column(name = "doc_date")
	private LocalDateTime docDate;

	@Column(name = "salesrep")
	private String salesrep;

	@Column(name = "total_price")
	private BigDecimal totalPrice;


	public Import getImportHeader() {
		return importHeader;
	}

	public void setImportHeader(Import importHeader) {
		this.importHeader = importHeader;
	}

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public String getCodeSociete() {
		return codeSociete;
	}

	public void setCodeSociete(String codeSociete) {
		this.codeSociete = codeSociete;
	}

	public String getDocReference() {
		return docReference;
	}

	public void setDocReference(String docReference) {
		this.docReference = docReference;
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

	public String getProductCode() {
		return productCode;
	}

	public void setProductCode(String productCode) {
		this.productCode = productCode;
	}

	public String getProductDesc() {
		return productDesc;
	}

	public void setProductDesc(String productDesc) {
		this.productDesc = productDesc;
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

	public BigDecimal getTotalPrice() {
		return totalPrice;
	}

	public void setTotalPrice(BigDecimal totalPrice) {
		this.totalPrice = totalPrice;
	}

}
