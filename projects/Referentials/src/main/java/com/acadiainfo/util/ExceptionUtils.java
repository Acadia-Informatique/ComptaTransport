package com.acadiainfo.util;


import jakarta.persistence.PersistenceException;

public class ExceptionUtils {
	// private static final java.util.logging.Logger logger =
	// java.util.logging.Logger.getLogger(ExceptionUtils.class.getName());

	@SuppressWarnings("unchecked")
	public static <E extends Throwable> E sneakyThrow(Throwable e) throws E {
		throw (E) e;
	}

	//
	/**
	 * Unwrap a PersistenceException to a "human readable" version, database-originated exception.  
	 * @param exc
	 * @return a "root cause" if found, or the original exc arg
	 */
	public static Throwable unwrapToSqlBasedException(PersistenceException exc) {
		Throwable t = exc;

		while (t != null && !isSqlBased(t)) {
			t = t.getCause();
		}

		if (isSqlBased(t)) {
			return t;
		} else {
			return exc; // unwrapping failed, return original arg
		}		
	}

	//
	/**
	 * If only Jakarta EE could wrap all funny exceptions from their
	 * the JDBC-drivers and JPA providers... (and I don't want them in my compile classpath).
	 * 
	 * TODO document current database settings (MySQL + ConnectJ driver) + JPA provider (EclipseLink)
	 * TODO complement and adjust to other possible deployment settings
	 * @param t
	 * @return
	 */
	private static boolean isSqlBased(Throwable t) {
		return (t instanceof java.sql.SQLException)
				// || t.getClass().getName().startsWith("org.eclipse.persistence.exceptions.")
				|| t.getClass().getName().startsWith("com.mysql.");
	}

	/**
	 * Inter-EJB method calls can make exception handling complicate...
	 * Thanks to the good old days of "distributed objects". 
	 * @param exc
	 * @return
	 */
	public static Throwable unwrapEjbException(jakarta.ejb.EJBException exc) {
		Throwable t = exc;
		while (t != null && t instanceof jakarta.ejb.EJBException) {
			t = t.getCause();
		}
		if (t != null) {
			return t;
		} else {
			return exc; // failed, return original arg
		}
	}


}
