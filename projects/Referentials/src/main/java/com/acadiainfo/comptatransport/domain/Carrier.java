package com.acadiainfo.comptatransport.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.NamedQuery;
import jakarta.persistence.Table;
import jakarta.persistence.Version;


@Entity
//@jakarta.enterprise.inject.Model
@Table(schema = "ComptaTransport", name = "CARRIER")

@NamedQuery(name = "CARRIER.findAll", query = "SELECT c FROM Carrier c ORDER BY c.name")
public class Carrier {

	/** X3 name **/
	@Id
	@Column(name = "name")
	private String name;

	/** from X3, not necessarily useful */
	@Column(name = "short_name")
	private String shortName;

	/** pretty name */
	@Column(name = "label")
	private String label;

	/**
	 * Important for "Contrôle quotidien". Is to be directly compared to the ones
	 * given by "Grille Tarifaire [Acadia]" module.
	 */
	@Column(name = "group_name")
	private String groupName;

	/** detailed description, explanation, comments.. */
	@Column(name = "description")
	private String description;

	/**
	 * Indicates a "zero-fee" carrier (usually a virtual shipping mode).
	 */
	@Column(name = "zero_charge", nullable = false)
	private boolean isZeroCharge;

	/**
	 * When not null, this message is displayed at "Contrôle quotidien" whenever
	 * this carrier is used. Typically used for outdated / "temporary+virtual"
	 * carriers.
	 */
	@Column(name = "warning_msg", nullable = true)
	private String warningMessage;
	
	@Version
	@Column(name = "_v_lock")
	private long version;
	
}
