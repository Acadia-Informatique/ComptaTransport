package com.acadiainfo.util;

public class ExceptionUtils {

	@SuppressWarnings("unchecked")
	public static <T, E extends Exception> T sneakyThrow(Exception e) throws E {
		throw (E) e;
	}

}
