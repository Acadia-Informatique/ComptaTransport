package com.acadiainfo.util.persistence;

/**
 * Package private
 */
class StringsConverterImpl {
	/**
	 * The separator mostly used in the UI too, so not typically expected to be used
	 * *in* the middle of values.
	 */
	final public static String SEPARATOR = ";";
	
	/*
	 * Empty arrays are immutable so can be shared.
	 */
	final private static String[] EMPTY_ARRAY = new String[0];

	protected String[] _doConvertToEntityAttribute(String dbData) {
		if (dbData == null || dbData.equals("")) {
			return EMPTY_ARRAY;
		} else {
			return dbData.split(SEPARATOR);
		}
	}

	protected String _doConvertToDatabaseColumn(Iterable<? extends CharSequence> value) {
		String dbData = value != null ? String.join(SEPARATOR, value) : "";
		return dbData;
	}
}