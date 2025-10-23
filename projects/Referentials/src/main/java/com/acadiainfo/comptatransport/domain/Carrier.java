package com.acadiainfo.comptatransport.domain;

import java.util.Set;
import java.util.TreeSet;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.NamedQuery;
import jakarta.persistence.Table;
import jakarta.persistence.Version;


@Entity
@Table(schema = "ComptaTransport", name = "CARRIER")
@NamedQuery(name = "findAll", query = "SELECT c FROM Carrier c ORDER BY c.name")
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
	 * Tags can be used for technical filtering (e.g. "zero-fee") or for expressing customer preferences.
	 */
	@Column(name = "tags")
	private Set<String> tags = new TreeSet<String>();


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

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getShortName() {
		return shortName;
	}

	public void setShortName(String shortName) {
		this.shortName = shortName;
	}

	public String getLabel() {
		return label;
	}

	public void setLabel(String label) {
		this.label = label;
	}

	public String getGroupName() {
		return groupName;
	}

	public void setGroupName(String groupName) {
		this.groupName = groupName;
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

	public String getWarningMessage() {
		return warningMessage;
	}

	public void setWarningMessage(String warningMessage) {
		this.warningMessage = warningMessage;
	}
	
}
