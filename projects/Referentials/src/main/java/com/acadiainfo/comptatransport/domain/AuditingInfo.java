package com.acadiainfo.comptatransport.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

/**
 * Database row modification audit info.
 * @see Auditable
 */
@Embeddable
public class AuditingInfo {

	@Column(name = "_date_created", updatable = false, insertable = false)
	@jakarta.persistence.Convert(converter = com.acadiainfo.util.persistence.AuditTimestampConverter.class)
	private Long dateCreated;

	@Column(name = "_date_modified", updatable = false, insertable = false)
	@jakarta.persistence.Convert(converter = com.acadiainfo.util.persistence.AuditTimestampConverter.class)
	private Long dateModified;

	// TODO add modifying user

	public java.util.Date getDateCreated() {
		return new java.util.Date(dateCreated);
	}

	public java.util.Date getDateModified() {
		return new java.util.Date(dateModified);
	}
}
