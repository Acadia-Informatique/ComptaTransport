package com.acadiainfo.comptatransport.domain;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Objects;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.NamedQuery;
import jakarta.persistence.Table;


@Entity
@Table(schema = "ComptaTransport", name = "AGG_SHIPPING_REVENUE")
@NamedQuery(name = "AggShippingRevenue.deleteByUniqueRef", query = """
    DELETE FROM AggShippingRevenue agg
    where agg.customer = :customer
      and agg.product = :product
      and agg.date = :date
     """)

@NamedQuery(name = "AggShippingRevenue.findAllBetween", query = """
    SELECT agg FROM AggShippingRevenue agg
    where agg.date >= :start_date and agg.date < :end_date
     """)
public class AggShippingRevenue {

	public enum ProductType {
		MAIN, B2C, OPTS, MONTHLY, QUOTE_MONTHLY
	};

	/** Tech. PK */
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "id")
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "customer_id", referencedColumnName = "id", nullable = false, updatable = false)
	private Customer customer;

	@Enumerated(EnumType.STRING)
	@Column(name = "product")
	private ProductType product;

	@Column(name = "date")
	private LocalDateTime date;

	@Column(name = "amount")
	private BigDecimal amount;

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	@jakarta.json.bind.annotation.JsonbTransient
	public Customer getCustomer() {
		return customer;
	}

	public void setCustomer(Customer customer) {
		this.customer = customer;
	}

	/** simplified json representation */
	public Long getCustomerId() {
		return this.customer != null ? this.customer.getId() : null;
	}

	public ProductType getProduct() {
		return product;
	}

	public void setProduct(ProductType product) {
		this.product = product;
	}

	public LocalDateTime getDate() {
		return date;
	}

	public void setDate(LocalDateTime date) {
		this.date = date;
	}

	public BigDecimal getAmount() {
		return amount;
	}

	public void setAmount(BigDecimal amount) {
		this.amount = amount;
	}

	// ===================
	// as a Set item of Customer

	@Override
	public int hashCode() {
		return Objects.hash(id);
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		AggShippingRevenue other = (AggShippingRevenue) obj;
		return Objects.equals(id, other.id);
	}

}
