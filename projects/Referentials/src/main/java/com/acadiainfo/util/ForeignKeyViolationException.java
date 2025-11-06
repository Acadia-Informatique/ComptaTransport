package com.acadiainfo.util;

public class ForeignKeyViolationException extends DataIntegrityViolationException {

	private static final long serialVersionUID = 7261731010419056445L;

	public ForeignKeyViolationException() {
		super();
	}

	public ForeignKeyViolationException(String message, Throwable cause) {
		super(message, cause);
	}

	public ForeignKeyViolationException(String message) {
		super(message);
	}

	public ForeignKeyViolationException(Throwable cause) {
		super(cause);
	}

	private String constraintName;

	public String getConstraintName() {
		return constraintName;
	}

	public void setConstraintName(String constraintName) {
		this.constraintName = constraintName;
	}

	@Override
	public String getMessage() {
		return "FK constraint '" + constraintName + "' violated";
	}

}
