package com.acadiainfo.comptatransport.domain;

import java.math.BigDecimal;
import java.util.Objects;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.persistence.Transient;

@Embeddable
public class MapTransportInvoice implements Comparable<MapTransportInvoice> {

	@Column(name = "doc_reference")
	private String docReference;

	@Column(name = "original_reference", insertable = true, updatable = false)
	private String originalReference;

	@Column(name = "total_weight_override")
	private BigDecimal totalWeight_override;

	@Column(name = "total_price_override")
	private BigDecimal totalPrice_override;

	public String getDocReference() {
		return docReference;
	}

	public void setDocReference(String docReference) {
		this.docReference = docReference;
	}

	public String getOriginalReference() {
		return originalReference;
	}

	public void setOriginalReference(String originalReference) {
		this.originalReference = originalReference;
	}

	public BigDecimal getTotalWeight_override() {
		return totalWeight_override;
	}

	public void setTotalWeight_override(BigDecimal totalWeight_override) {
		this.totalWeight_override = totalWeight_override;
	}

	public BigDecimal getTotalPrice_override() {
		return totalPrice_override;
	}

	public void setTotalPrice_override(BigDecimal totalPrice_override) {
		this.totalPrice_override = totalPrice_override;
	}

	// ----------------------
	// for efficency, WS returns the row associated through docReference

	@Transient
	private TransportSalesHeader mapped;

	public TransportSalesHeader getMapped() {
		return mapped;
	}

	public void setMapped(TransportSalesHeader mapped) {
		this.mapped = mapped;
	}

	// -------------------------
	// SortedSet element contract

	@Override
	public int compareTo(MapTransportInvoice o) {
		return this.docReference.compareTo(o.docReference);
	}

	@Override
	public int hashCode() {
		return Objects.hash(docReference);
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		MapTransportInvoice other = (MapTransportInvoice) obj;
		return Objects.equals(docReference, other.docReference);
	}

}
