package com.acadiainfo.comptatransport.domain;

import java.util.Set;
import java.util.TreeSet;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Embedded;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.NamedQuery;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import jakarta.persistence.Version;


@Entity
@Table(schema = "ComptaTransport", name = "CUSTOMER")
@NamedQuery(name = "Customer.findAll", query = "SELECT c FROM Customer c ORDER BY c.label")
public class Customer implements Auditable, VersionLockable {

	/** Tech. PK */
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "id")
	private Long id;

	/** X3 name, unique */
	@Column(name = "erp_reference")
	private String erpReference;

	/** Display name, probably the same as in X3 */
	@Column(name = "label")
	private String label;

	/** detailed description, explanation, comments.. */
	@Column(name = "description")
	private String description;

	/** Tags can be used for technical filtering (e.g. "Grand Compte") or further description. */
	@Column(name = "tags")
	private Set<String> tags = new TreeSet<String>();
	
	/** All the preferences recorded on this Customer */
    @OneToMany(
        mappedBy = "customer",
        cascade = CascadeType.ALL,
        orphanRemoval = true
    )
	private Set<CustomerShipPreferences> shipPreferences = new TreeSet<CustomerShipPreferences>();
	
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

	public String getErpReference() {
		return erpReference;
	}

	public void setErpReference(String erpReference) {
		this.erpReference = erpReference;
	}

	public String getLabel() {
		return label;
	}

	public void setLabel(String label) {
		this.label = label;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public Set<String> getTags() {
		return tags;
	}

	public void setTags(Set<String> tags) {
		this.tags = tags;
	}

	public Set<CustomerShipPreferences> getShipPreferences() {
		return shipPreferences;
	}

	public void setShipPreferences(Set<CustomerShipPreferences> shipPreferences) {
		this.shipPreferences = shipPreferences;
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
