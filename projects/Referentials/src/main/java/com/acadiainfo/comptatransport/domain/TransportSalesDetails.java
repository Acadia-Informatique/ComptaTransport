package com.acadiainfo.comptatransport.domain;

import java.math.BigDecimal;
import java.util.Objects;

import jakarta.json.bind.annotation.JsonbProperty;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * This is a read-only view of imported rows as Transport sales DETAILS (meaning item & price).
 * The mapping of import (ImportTransportVendu) is split between this and {@link TransportSalesHeader}.
 *
 * By the way, it shares the same base table than the "import entity" and the same cardinality,
 * but is considered a child entity of TransportSalesHeader.
 *
 * @see com.acadiainfo.comptatransport.fileimport.ImportTransportVendu
 */
@Entity
@Table(schema = "ComptaTransport", name = "I_TRANSPORT_VENDU")
public class TransportSalesDetails {
	public enum ProductType {
		MAIN, B2C, OPTS, UNK
	};

	/** Tech. PK */
	@Id
	@Column(name = "id")
	private Long id;

	/** FK to parent entity : cannot be easily queried, since parent is the result of a native query...
	private TransportSalesHeader header; */

	@Column(name = "product_desc")
	private String productDesc;

	@Column(name = "total_price")
	private BigDecimal totalPrice;

	@jakarta.json.bind.annotation.JsonbTransient
	public Long getId() {
		return id;
	}

	@JsonbProperty("type")
	public ProductType getProductType() {
		//TODO use the new export columns PROD_FAMILY_* and PRODUCT_*
		return switch(this.productDesc) {
		case "Frais de port Europe", "Frais de port Export", "Frais de port France",
			"Frais de port Dropshipper",
			"Frais de port E-shopper" // specific to customer "ninepoint GmbH" ?
			-> ProductType.MAIN;
		case "Frais de traitement livraison direct", "Frais de traitement livraison direct Europe",
			"Frais Commande Drop"
			-> ProductType.B2C;
		case "LIVRAISON  SAMEDI"
			-> ProductType.OPTS;
		default
			-> ProductType.UNK;
		};
	}

	@JsonbProperty("product")
	public String getProductDesc() {
		return productDesc;
	}

	@JsonbProperty("price")
	public BigDecimal getTotalPrice() {
		return totalPrice;
	}

	// ===================
	// as a Set item of TransportSalesHeader
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
		TransportSalesDetails other = (TransportSalesDetails) obj;
		return Objects.equals(id, other.id)
		/*
		 * && Objects.equals(productDesc, other.productDesc) &&
		 * Objects.equals(totalPrice, other.totalPrice)
		 */;
	}

}
