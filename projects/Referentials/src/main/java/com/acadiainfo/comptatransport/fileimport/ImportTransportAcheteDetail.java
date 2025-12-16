package com.acadiainfo.comptatransport.fileimport;

import java.math.BigDecimal;
import java.util.Objects;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(schema = "ComptaTransport", name = "I_TRANSPORT_ACHETE_DETAIL")
public class ImportTransportAcheteDetail {
	/** Tech. PK */
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "id")
	private Long id;

	/** FK to parent ImportTransportAchete*/
	@jakarta.json.bind.annotation.JsonbTransient
	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "tr_achete_id")
	private ImportTransportAchete parent;

	@Column(name = "subarticle_name")
	private String subarticleName;

	@Column(name = "amount")
	private BigDecimal amount;

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public ImportTransportAchete getParent() {
		return parent;
	}

	public void setParent(ImportTransportAchete parent) {
		this.parent = parent;
	}

	public String getSubarticleName() {
		return subarticleName;
	}

	public void setSubarticleName(String subarticle_name) {
		this.subarticleName = subarticle_name;
	}

	public BigDecimal getAmount() {
		return amount;
	}

	public void setAmount(BigDecimal amount) {
		this.amount = amount;
	}


	// ======== as an element of ArticleTransportAchete.details

	@Override
	public int hashCode() {
		return Objects.hash(subarticleName);
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		ImportTransportAcheteDetail other = (ImportTransportAcheteDetail) obj;
		return Objects.equals(subarticleName, other.subarticleName);
	}

}
