package com.acadiainfo.comptatransport.domain;

import java.time.LocalDateTime;

import jakarta.persistence.Basic;
import jakarta.persistence.Column;
import jakarta.persistence.Embedded;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Lob;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import jakarta.persistence.Version;


@Entity
@Table(schema = "ComptaTransport", name = "PRICE_GRID_VERSION", uniqueConstraints = {
		@UniqueConstraint(columnNames = { "price_grid_id", "version" }) })
public class PriceGridVersion implements Auditable, VersionLockable {

	/** Tech. PK */
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "id")
	private Long id;

	/** FK to parent entity */
	@ManyToOne
	@JoinColumn(name = "price_grid_id", nullable = false)
	private PriceGrid priceGrid;

	/** User-defined version tag, usually based on date */
	@Column(name = "version", nullable = false)
	private String version;

	/** detailed description, explanation, comments... */
	@Column(name = "description")
	private String description;

	/** Publication date, may be in the future for planned publish */
	@Column(name = "published_date")
	private LocalDateTime publishedDate;

	@Lob
	@Column(name = "json_content")
	@Basic(fetch = FetchType.LAZY)
	private String jsonContent;

	/**
	 * JPA Optimistic lock
	 */
	@Version
	@Column(name = "_v_lock")
	private long _v_lock;
	

	@Embedded
	private AuditingInfo auditingInfo;

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public PriceGrid getPriceGrid() {
		return priceGrid;
	}

	public void setPriceGrid(PriceGrid priceGrid) {
		this.priceGrid = priceGrid;
	}

	public String getVersion() {
		return version;
	}

	public void setVersion(String version) {
		this.version = version;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public LocalDateTime getPublishedDate() {
		return publishedDate;
	}

	public void setPublishedDate(LocalDateTime publishedDate) {
		this.publishedDate = publishedDate;
	}

	@jakarta.json.bind.annotation.JsonbTransient
	public String getJsonContent() {
		return jsonContent;
	}

	public void setJsonContent(String jsonContent) {
		this.jsonContent = jsonContent;
	}

	@Override
	public long get_v_lock() {
		return _v_lock;
	}

	@Override
	public void set_v_lock(long _v_lock) {
		this._v_lock = _v_lock;
	}

	@Override
	public AuditingInfo getAuditingInfo() {
		return auditingInfo;
	}

}
