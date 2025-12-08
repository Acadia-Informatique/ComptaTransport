package com.acadiainfo.comptatransport.fileimport;

import java.math.BigDecimal;
import java.util.Objects;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
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
	@ManyToOne
	@JoinColumn(name = "tr_achete_id")
	private ImportTransportAchete parent;

	@Column(name = "ssarticle_name")
	private String ssarticleName;

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

	public String getSsarticleName() {
		return ssarticleName;
	}

	public void setSsarticleName(String ssarticleName) {
		this.ssarticleName = ssarticleName;
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
		return Objects.hash(ssarticleName);
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
		return Objects.equals(ssarticleName, other.ssarticleName);
	}

}
