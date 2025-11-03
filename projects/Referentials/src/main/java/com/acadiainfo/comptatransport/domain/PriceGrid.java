package com.acadiainfo.comptatransport.domain;

import java.util.Set;
import java.util.TreeSet;

import jakarta.persistence.Column;
import jakarta.persistence.Embedded;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.NamedQuery;
import jakarta.persistence.Table;
import jakarta.persistence.Version;


@Entity
@Table(schema = "ComptaTransport", name = "PRICE_GRID")
@NamedQuery(name = "PriceGrid.findAll", query = "SELECT pg FROM PriceGrid pg ORDER BY pg.name")
public class PriceGrid implements Auditable, VersionLockable {

	/** Tech. PK */
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "id")
	private Long id;

	/** Name = business ID */
	@Column(name = "name", unique = true)
	private String name;

	/** Tags can be used for technical filtering. */
	@Column(name = "tags")
	private Set<String> tags = new TreeSet<String>();

	/** detailed description, explanation, comments.. */
	@Column(name = "description")
	private String description;


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

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public Set<String> getTags() {
		return tags;
	}

	public void setTags(Set<String> tags) {
		this.tags = tags;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
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
