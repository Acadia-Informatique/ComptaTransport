package com.acadiainfo.comptatransport.domain;

/**
 * Marks entities which modifications are to be tracked.
 * Most of it will be set at database level, not application code.
 */
public interface Auditable {
	public AuditingInfo getAuditingInfo();
}
