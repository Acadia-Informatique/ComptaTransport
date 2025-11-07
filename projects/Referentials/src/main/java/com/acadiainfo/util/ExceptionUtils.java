package com.acadiainfo.util;


import java.util.regex.Matcher;
import java.util.regex.Pattern;

import jakarta.persistence.PersistenceException;

public class ExceptionUtils {
	// private static final java.util.logging.Logger logger =
	// java.util.logging.Logger.getLogger(ExceptionUtils.class.getName());

	@SuppressWarnings("unchecked")
	public static <E extends Throwable> E sneakyThrow(Throwable e) throws E {
		throw (E) e;
	}

	/** 
	 * Look into a PersistenceException for a SQL-based cause, as a safety net for insufficient checking.
	 * The messages at repository level are meant for debugging, and are not properly localized. 
	 * 
	 * @param exc - the Exception to be analyzed
	 * @return a "human readable" version of the exc argument (may be another PersistenceException)
	 */
	public static jakarta.persistence.PersistenceException explicitPersistenceException(
			jakarta.persistence.PersistenceException exc) {

		if (exc instanceof com.acadiainfo.util.DataIntegrityViolationException
		  || exc instanceof jakarta.persistence.EntityNotFoundException
		  || exc instanceof jakarta.persistence.EntityExistsException) {
			return exc; // those are explicit enough
		}

		Throwable cause = com.acadiainfo.util.ExceptionUtils.unwrapToSqlBasedException(exc);
		if (cause instanceof java.sql.SQLIntegrityConstraintViolationException) {
			java.sql.SQLIntegrityConstraintViolationException sqlCause = (java.sql.SQLIntegrityConstraintViolationException) cause;

			jakarta.persistence.PersistenceException explicited = null;
			
			if (explicited == null) {
				explicited = translateConstraintViolation_UNIQUE(sqlCause);
			}
			if (explicited == null) {
				explicited = translateConstraintViolation_FK(sqlCause);
			}
			if (explicited == null) {
				explicited = translateConstraintViolation_PK(sqlCause);
			}
			if (explicited == null) {
				explicited = new com.acadiainfo.util.DataIntegrityViolationException(sqlCause);
			}
			// } else if ... TODO add analysis for other common java.sql.* exceptions
			
			return explicited;
		} else {
			// simplify the message and cause chain
			return new jakarta.persistence.PersistenceException(cause.getMessage());
		}
	}

	/**
	 * Unwrap a PersistenceException to a "human readable" version, database-originated exception.  
	 * @param exc
	 * @return a "root cause" if found, or the original exc arg if unwrapping failed
	 */
	private static Throwable unwrapToSqlBasedException(PersistenceException exc) {
		Throwable t = exc;

		while (t != null && !isSqlBased(t)) {
			t = t.getCause();
		}

		return (t != null) ? t : exc;
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
		if (t == null) {
			return false;
		} else {
			return t instanceof java.sql.SQLException
				// || t.getClass().getName().startsWith("org.eclipse.persistence.exceptions.")
				|| t.getClass().getName().startsWith("com.mysql.");
		}
	}


	/*
	 * *****************************************************************************
	 * ***************** SQL error message analysis, based on my own database
	 * settings, and my own PK constraint naming habits (couldn't do better for
	 * years ;-)
	 * 
	 * TODO document current database settings (MySQL + UTC timezone + US-EN
	 * locale).
	 */
	private static final Pattern PK_pattern = Pattern.compile("^.*Duplicate entry '(.*)' for key '.*\\.PRIMARY'$");
	private static final Pattern FK_pattern = Pattern.compile("^.*CONSTRAINT `(.*)` FOREIGN KEY .* REFERENCES .*$");
	private static final Pattern UNIQUE_pattern = Pattern.compile("^.*Duplicate entry '(.*)' for key '(.*)'$");

	/**
	 * Look for a Primary Key violation message. 
	 */
	private static jakarta.persistence.EntityExistsException translateConstraintViolation_PK(Throwable t) {
		String message = t.getMessage();
		Matcher matcher = PK_pattern.matcher(message);
		if (matcher.matches() && matcher.groupCount() == 1) {
			jakarta.persistence.EntityExistsException exc = new jakarta.persistence.EntityExistsException(t);
			// duplicated PK value = matcher.group(1)
			return exc;
		} else {
			return null;
		}
	}

	/**
	 * Look for a Foreign Key violation message. 
	 */
	private static com.acadiainfo.util.ForeignKeyViolationException translateConstraintViolation_FK(Throwable t) {
		String message = t.getMessage();
		Matcher matcher = FK_pattern.matcher(message);
		if (matcher.matches() && matcher.groupCount() == 1) {
			ForeignKeyViolationException exc = new ForeignKeyViolationException(t);
			exc.setConstraintName(matcher.group(1));
			return exc;
		} else {
			return null;
		}
	}

	/**
	 * Look for a UNIQUE constraint violation message. 
	 */
	private static UniqueConstraintViolationException translateConstraintViolation_UNIQUE(Throwable t) {
		String message = t.getMessage();
		Matcher matcher = UNIQUE_pattern.matcher(message);
		if (matcher.matches() && matcher.groupCount() == 2) {
			UniqueConstraintViolationException exc = new UniqueConstraintViolationException(t);
			exc.setDuplicateValue(matcher.group(1));
			exc.setConstraintName(matcher.group(2));
			return exc;
		} else {
			return null;
		}
	}

	/************************************************************************************************
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
