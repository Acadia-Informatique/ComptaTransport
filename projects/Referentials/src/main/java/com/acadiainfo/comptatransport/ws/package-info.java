/**
 * This package represents the service level of the application,
 * but it is also the REST API level for the web apps using them.
 * <p>
 * As such, is is an integral part of the web apps for the end user, so its is
 * <em>where messages are localized</em>. At data and domain level,
 * messages stay in english.
 * </p>
 * <p>
 * 	Simply put,<p>here</p>we can speak French.
 * </p>
 * TODO make the service respond the Accept-Language headers and make the services bilingual ;-)
 * @see com.acadiainfo.util.WSUtils#responseMessage(jakarta.ws.rs.core.Response.Status, String, java.util.Locale) for that i18n goal
 */
package com.acadiainfo.comptatransport.ws;
