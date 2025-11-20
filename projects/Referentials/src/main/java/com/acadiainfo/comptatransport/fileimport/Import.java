package com.acadiainfo.comptatransport.fileimport;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * Header entry of a File Import job.
 */
@Entity
@Table(schema = "ComptaTransport", name = "I_IMPORT")
public class Import {

	/** Tech. PK */
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "id")
	private Long id;

	@Column(name = "type")
	private String type;

	@Column(name = "_date_started", updatable = false, insertable = false)
	@jakarta.persistence.Convert(converter = com.acadiainfo.util.persistence.AuditTimestampConverter.class)
	private Long dateStarted;

	@Column(name = "_date_ended")
	@jakarta.persistence.Convert(converter = com.acadiainfo.util.persistence.AuditTimestampConverter.class)
	private Long dateEnded;

	public java.util.Date getDateStarted() {
		return new java.util.Date(dateStarted);
	}

	public java.util.Date getDateEnded() {
		return new java.util.Date(dateEnded);
	}

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public String getType() {
		return type;
	}

	public void setType(String type) {
		this.type = type;
	}

	public void setDateStarted(Long dateStarted) {
		this.dateStarted = dateStarted;
	}

	public void setDateEnded(Long dateEnded) {
		this.dateEnded = dateEnded;
	}

}
