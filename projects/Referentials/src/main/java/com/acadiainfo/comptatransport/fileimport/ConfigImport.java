package com.acadiainfo.comptatransport.fileimport;

import com.acadiainfo.comptatransport.domain.Auditable;
import com.acadiainfo.comptatransport.domain.AuditingInfo;

import jakarta.persistence.Column;
import jakarta.persistence.Embedded;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * Generic configuration for a tabular File Import job.
 */
@Entity
@Table(schema = "ComptaTransport", name = "I_CONFIG_IMPORT")
public class ConfigImport implements Auditable {

	public enum DstType {
		table, entity, custom
	};

	public class ConfigColumn {
		public String propertyName; // its semantics is related to;
		public int colIndex;
		public String colLabel; // for validity control
	}

	/** PK, Value to be set in entity Import [header] */
	@Id
	@Column(name = "type")
	public String type;

	/** Generic address for the File to be imported (built on the URI specification & extend it */
	@Column(name = "src_path")
	public String src_path;

	@Column(name = "src_col_labels_rowid")
	public int src_colLabelsRowid;

	@Column(name = "src_data_rowid")
	public int src_dataRowid;

	@Column(name = "src_col_condition")
	public String src_col_condition;

	/** sort of URL, where "protocol" part corresponds to enum DstType */
	@Column(name = "dst_path")
	public String dst_path;

	/** serialized details of all column mapping */

	@Column(name = "dst_mapping")
	// @jakarta.persistence.Convert(converter = ConfigColumnConverter.class)
	public ConfigColumn[] dst_mapping;

	@Embedded
	private AuditingInfo auditingInfo;

	@Override
	public AuditingInfo getAuditingInfo() {
		return auditingInfo;
	}


}
