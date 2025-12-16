package com.acadiainfo.comptatransport.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Embedded;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import jakarta.persistence.Version;


@Entity
@Table(schema = "ComptaTransport", name = "INPUT_CTRL_COSTS")
public class InputControlCosts implements Auditable, VersionLockable {
	/** Tech. PK */
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "id")
	private Long id;

	/** FK to parent entity */
	@jakarta.json.bind.annotation.JsonbTransient
	@OneToOne
	@JoinColumn(name = "tr_achete_id")
	private TransportPurchaseHeader header;

	// ============================================
	// Control results

	@Column(name = "theirAmountOK_comment")
	private String theirAmountOK_comment;

	@Column(name = "ourMarginOK_comment")
	private String ourMarginOK_comment;

	@Column(name = "theirAmountOK_override")
	private Byte theirAmountOK_override;

	@Column(name = "ourMarginOK_override")
	private Byte ourMarginOK_override;

	/**
	 * JPA Optimistic lock
	 */
	@Version
	@Column(name = "_v_lock")
	private Long _v_lock;


	@Embedded
	private AuditingInfo auditingInfo;



	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public TransportPurchaseHeader getHeader() {
		return header;
	}

	public void setHeader(TransportPurchaseHeader header) {
		this.header = header;
	}

	public String getTheirAmountOK_comment() {
		return theirAmountOK_comment;
	}

	public void setTheirAmountOK_comment(String theirAmountOK_comment) {
		this.theirAmountOK_comment = theirAmountOK_comment;
	}

	public String getOurMarginOK_comment() {
		return ourMarginOK_comment;
	}

	public void setOurMarginOK_comment(String ourMarginOK_comment) {
		this.ourMarginOK_comment = ourMarginOK_comment;
	}

	public Byte getTheirAmountOK_override() {
		return theirAmountOK_override;
	}

	public void setTheirAmountOK_override(Byte theirAmountOK_override) {
		this.theirAmountOK_override = theirAmountOK_override;
	}

	public Byte getOurMarginOK_override() {
		return ourMarginOK_override;
	}

	public void setOurMarginOK_override(Byte ourMarginOK_override) {
		this.ourMarginOK_override = ourMarginOK_override;
	}

	@Override
	public Long get_v_lock() {
		return _v_lock;
	}

	@Override
	public void set_v_lock(Long _v_lock) {
		this._v_lock = _v_lock;
	}

	@Override
	public AuditingInfo getAuditingInfo() {
		return auditingInfo;
	}

}
