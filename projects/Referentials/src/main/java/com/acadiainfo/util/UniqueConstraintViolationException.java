package com.acadiainfo.util;

public class UniqueConstraintViolationException extends DataIntegrityViolationException {


	public UniqueConstraintViolationException() {
		super();
	}

	public UniqueConstraintViolationException(String message, Throwable cause) {
		super(message, cause);
	}

	public UniqueConstraintViolationException(String message) {
		super(message);
	}

	public UniqueConstraintViolationException(Throwable cause) {
		super(cause);
	}

	private String constraintName;
	private String duplicateValue;

	public String getConstraintName() {
		return constraintName;
	}

	public void setConstraintName(String constraintName) {
		this.constraintName = constraintName;
	}

	public String getDuplicateValue() {
		return duplicateValue;
	}

	public void setDuplicateValue(String duplicateValue) {
		this.duplicateValue = duplicateValue;
	}

	@Override
	public String getMessage() {
		return "Unique constraint '" + constraintName + "' violated - Duplicated value : '" + duplicateValue + "'";
	}
}
