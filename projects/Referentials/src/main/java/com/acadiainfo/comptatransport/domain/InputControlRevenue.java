package com.acadiainfo.comptatransport.domain;

import java.math.BigDecimal;

import jakarta.persistence.Column;
import jakarta.persistence.Embedded;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.Version;


@Entity
@Table(schema = "ComptaTransport", name = "INPUT_CTRL_REVENUE")
public class InputControlRevenue implements Auditable, VersionLockable {
	/** Tech. PK */
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "id")
	private Long id;

	/** "virtual" FK to parent entity (TransportSalesHeader)
	 *  which can be missing (due to re-import of the same data from SEI). */
	@Column(name = "doc_reference")
	private String docReference;

	// ============================================
	// Control results

	@Column(name = "carrierOK_comment")
	private String carrierOK_comment;

	@Column(name = "amountOK_comment")
	private String amountOK_comment;

	@Column(name = "carrierOK_override")
	private Byte carrierOK_override;

	@Column(name = "amountOK_override")
	private Byte amountOK_override;

	// ============================================
	// Control results

	@Column(name = "is_b2c_override")
	private Boolean b2c_override;

	@Column(name = "is_nonstd_pack_override")
	private Boolean nonstdPack_override;

	@ManyToOne
	@JoinColumn(name = "carrier_override")
	private Carrier carrier_override;

	@Column(name = "price_MAIN_override")
	private BigDecimal price_MAIN_override;

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

	public String getDocReference() {
		return docReference;
	}

	public void setDocReference(String docReference) {
		this.docReference = docReference;
	}

	public String getCarrierOK_comment() {
		return carrierOK_comment;
	}

	public void setCarrierOK_comment(String carrierOK_comment) {
		this.carrierOK_comment = carrierOK_comment;
	}

	public String getAmountOK_comment() {
		return amountOK_comment;
	}

	public void setAmountOK_comment(String amountOK_comment) {
		this.amountOK_comment = amountOK_comment;
	}

	public Byte getCarrierOK_override() {
		return carrierOK_override;
	}

	public void setCarrierOK_override(Byte carrierOK_override) {
		this.carrierOK_override = carrierOK_override;
	}

	public Byte getAmountOK_override() {
		return amountOK_override;
	}

	public void setAmountOK_override(Byte amountOK_override) {
		this.amountOK_override = amountOK_override;
	}

	public Boolean getB2c_override() {
		return b2c_override;
	}

	public void setB2c_override(Boolean b2c_override) {
		this.b2c_override = b2c_override;
	}

	public Boolean getNonstdPack_override() {
		return nonstdPack_override;
	}

	public void setNonstdPack_override(Boolean nonstdPack_override) {
		this.nonstdPack_override = nonstdPack_override;
	}

	public Carrier getCarrier_override() {
		return carrier_override;
	}

	public void setCarrier_override(Carrier carrier_override) {
		this.carrier_override = carrier_override;
	}

	public BigDecimal getPrice_MAIN_override() {
		return price_MAIN_override;
	}

	public void setPrice_MAIN_override(BigDecimal price_MAIN_override) {
		this.price_MAIN_override = price_MAIN_override;
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
