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
 * This is mainly interpreted by {@link RowImporter_TransportAchete} and {@link RowsProvider} classes.
 */
@Entity
@Table(schema = "ComptaTransport", name = "I_CONFIG_IMPORT")
public class ConfigImport implements Auditable {
	public static class ConfigColumn {
		public String propertyName; // its semantics is related to;
		public String datatype; // standard type or specific parser
		public int colIndex; // usually 0+ ; if -1 then colLabel will be interpreted as an expression (TBD)
		public String colLabel; // for validity control ; except if colIndex = -1
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

	/** zero-based column index tested for "valid rows" */
	@Column(name = "src_col_condition")
	public Integer src_col_condition;

	/** TODO : NOT USED YET. Intended to be :  sort of URL, where "protocol" part corresponds to ... whatever */
	@Column(name = "dst_path")
	public String dst_path;

	/** serialized details of all column mapping */
	@Column(name = "dst_mapping")
	@jakarta.persistence.Convert(converter = ConfigImportColumnConverter.class)
	public ConfigColumn[] dst_mapping;

	@Embedded
	private AuditingInfo auditingInfo;

	@Override
	public AuditingInfo getAuditingInfo() {
		return auditingInfo;
	}


}
