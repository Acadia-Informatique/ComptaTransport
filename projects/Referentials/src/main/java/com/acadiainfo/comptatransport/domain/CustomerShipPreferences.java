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
@Table(schema = "ComptaTransport", name = "CUSTOMER_SHIP_PREFERENCES")
public class CustomerShipPreferences implements Auditable, VersionLockable {
//	  `customer_id` bigint unsigned NOT NULL,
//	  `application_date` datetime DEFAULT NULL COMMENT 'Nul si non-validées, peut être dans le futur. Indique les conditions applicables à un instant donné.',
//	  `override_price_grid` bigint unsigned DEFAULT NULL COMMENT '(optionel) La grille tarifaire particulière à ce client',
//	  `override_carriers` varchar(256) DEFAULT NULL COMMENT '"semicolon-separated string", FK virtuelle vers CARRIER. A priori le client n''utilisera QUE ces transporteurs.',
//	  `carrier_tags_whitelist` varchar(256) DEFAULT NULL COMMENT '(optionel) "semicolon-separated string", CARRIER.tags préférés du client',
//	  `carrier_tags_blacklist` varchar(256) DEFAULT NULL COMMENT '(optionel) "semicolon-separated string", CARRIER.tags que le client veut éviter',
//
//	  
//	  UNIQUE KEY `CUSTOMER_SHIP_PREFERENCES_UNIQUE_IDX` (`customer_id`,`application_date`) USING BTREE,
//	  KEY `CUSTOMER_SHIP_PREFERENCES_PRICE_GRID_FK` (`override_price_grid`),
//	  CONSTRAINT `CUSTOMER_SHIP_PREFERENCES_CUSTOMER_FK` FOREIGN KEY (`customer_id`) REFERENCES `CUSTOMER` (`id`) ON DELETE CASCADE,
//	  CONSTRAINT `CUSTOMER_SHIP_PREFERENCES_PRICE_GRID_FK` FOREIGN KEY (`override_price_grid`) REFERENCES `PRICE_GRID` (`id`)

//TODO LA PRIMARY KEY EST MAL DEFINIE	

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
