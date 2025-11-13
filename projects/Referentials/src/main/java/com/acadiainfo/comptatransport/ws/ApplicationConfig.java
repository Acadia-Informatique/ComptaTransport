package com.acadiainfo.comptatransport.ws;

import com.acadiainfo.comptatransport.domain.*;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.ApplicationPath;
import jakarta.ws.rs.core.Application;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.Response.Status;

/**
 * This represents the root context for the API.
 * It contains also an application-specific registry about the database.
 * TODO maybe make it less... hard-coded ?
 */
@ApplicationPath("api")
public class ApplicationConfig extends Application {
	/**
	 * An application specific registry of "pretty" entity names.
	 */
	private static final java.util.Map<Class<?>, String> ENTITY_CLASS_MAP;
	static {
		ENTITY_CLASS_MAP = new java.util.HashMap<Class<?>, String>();
		ENTITY_CLASS_MAP.put(Carrier.class, "Transporteur");
		ENTITY_CLASS_MAP.put(PriceGrid.class, "Grille Tarifaire");
		ENTITY_CLASS_MAP.put(PriceGridVersion.class, "Version de Grille Tarifaire");
		ENTITY_CLASS_MAP.put(Customer.class, "Client");
		ENTITY_CLASS_MAP.put(CustomerShipPreferences.class, "Préférences Transport du Client");
	}

	public static Response response(jakarta.persistence.PersistenceException exc, HttpServletRequest servletRequest,
			Class<?> entityClass) {

		exc = com.acadiainfo.util.ExceptionUtils.explicitPersistenceException(exc);
		java.util.Locale locale = servletRequest.getLocale();

		// TODO should find a polymorphic way to do that on
		// com.acadiainfo.util.DataIntegrityViolationException class hierarchy
		// ...but beware of the cyclic references to this Application-specific class.
		if (exc instanceof jakarta.persistence.EntityNotFoundException) {
			return com.acadiainfo.util.WSUtils.response(Status.NOT_FOUND, servletRequest,
			  getEntityLabel(entityClass, locale) + " n'existe pas, ou a été supprimé depuis.\n"
			  + exc.getMessage());
		} else if (exc instanceof jakarta.persistence.EntityExistsException) {
			return com.acadiainfo.util.WSUtils.response(Status.CONFLICT, servletRequest,
			  getEntityLabel(entityClass, locale) + " n'a pu être créé en doublon.\n"
			  + exc.getMessage());
		} else if (exc instanceof com.acadiainfo.util.UniqueConstraintViolationException customExc) {
			return com.acadiainfo.util.WSUtils.response(Status.CONFLICT, servletRequest,
			  getEntityLabel(entityClass, locale) + " ne peut avoir la même valeur '"
			  + customExc.getDuplicateValue() + "' de "
			  + getUniqueAttributeLabel(customExc.getConstraintName(), locale));
		} else if (exc instanceof com.acadiainfo.util.ForeignKeyViolationException customExc) {
			return com.acadiainfo.util.WSUtils.response(Status.NOT_ACCEPTABLE, servletRequest,
			  getEntityLabel(entityClass, locale) + " possède encore des "
			  + getDependentEntityLabel(customExc.getConstraintName(), locale));
		}
		throw exc;
	}

	/**
	 * Get "pretty names" for WS messages.
	 * @param entityClass
	 * @param locale - not used yet / TODO i18n : make it Locale-aware.
	 * @return
	 */
	public static String getEntityLabel(Class<?> entityClass, java.util.Locale locale) {
		String label = ENTITY_CLASS_MAP.get(entityClass);
		if (label == null) {
			label = entityClass.getName(); // as a fallback
		}
		return label;
	}

	/**
	 * Get "pretty names" for WS messages.
	 * @param SQL database constraint name
	 * @param locale - not used yet / TODO i18n : make it Locale-aware.
	 * @return
	 */
	public static String getUniqueAttributeLabel(String constraintName, java.util.Locale locale) {

		switch (constraintName) {
		case "PRICE_GRID.PRICE_GRID_NAME_UNIQUE":
			return "Nom";
		case "PRICE_GRID_VERSION.PRICE_GRID_VERSION_UNIQUE":
			return "[Grille + Version]";
		case "CUSTOMER.CUSTOMER_ERP_REF_UNIQUE":
			return "Référence ERP";
		case "CUSTOMER_SHIP_PREFERENCES.CUSTOMER_SHIP_PREFERENCES_UNIQUE":
			return "[Client + Date d'application]";
		default:
			return constraintName; // as a fallback
		}
	}


	/**
	 * Get "pretty names" for WS messages.
	 * @param SQL database constraint name
	 * @param locale - not used yet / TODO i18n : make it Locale-aware.
	 * @return
	 */
	public static String getDependentEntityLabel(String constraintName, java.util.Locale locale) {
		switch (constraintName) {
		case "PRICE_GRID_VERSION_PRICE_GRID_FK":
			return "Versions de Grille Tarifaire";
		case "CUSTOMER_SHIP_PREFERENCES_PRICE_GRID_FK":
			return "Grille Tarifaire spécifique au Client";
		// case "CUSTOMER_SHIP_PREFERENCES_CUSTOMER_FK":
		// return... cannot unbind that one

		default:
			return constraintName; // as a fallback
		}
	}



}