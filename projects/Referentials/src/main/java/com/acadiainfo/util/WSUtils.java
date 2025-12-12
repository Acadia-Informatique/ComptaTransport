package com.acadiainfo.util;

import java.io.IOException;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.stream.Stream;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.StreamingOutput;

public class WSUtils {
	/**
	 * Builds a response for API caller *and* web app user.
	 * @param status - HTTP status of the response
	 * @param servletRequest - context info
	 * @param message - Message to be sent as response payload
	 * @return build Response
	 */
	public static Response response(Response.Status status, HttpServletRequest servletRequest, String message) {
		java.util.Locale locale = servletRequest.getLocale();
		//TODO use locale for i18n, may need to change "message" argument to {"messageKey" + args}...

		return Response.status(status)
		  .entity(message)
		  .type(MediaType.TEXT_PLAIN_TYPE.withCharset("UTF-8"))
		  .language(locale.toLanguageTag()) // i know that's currently a lie :D
		  .build();
	}

	private static class JsonArrayElementWriter {
		private jakarta.json.bind.Jsonb jsonb = jakarta.json.bind.JsonbBuilder.create();
		// JsonbBuilder.create() uses a default JsonbConfig with encoding set to UTF-8

		private volatile boolean isFirst = true;

		public void writeOne(Object element, java.io.OutputStream out) {
			try {
				if (isFirst) {
					isFirst = false;
				} else {
					out.write(','); // at least, that is common to all (most ?) charsets
				}
				jsonb.toJson(element, out);
			} catch (IOException e) {
				throw new RuntimeException(e);
			}
		}
	}

	public static StreamingOutput entityJsonStreamingOutput(Stream<?> entityStream) {

		StreamingOutput stream = new StreamingOutput() {
			@Override
			public void write(java.io.OutputStream out)
					throws java.io.IOException, jakarta.ws.rs.WebApplicationException {
				JsonArrayElementWriter writer = new JsonArrayElementWriter();
				out.write('[');
				entityStream.forEach(c -> writer.writeOne(c, out));
				out.write(']');
			}
		};
		return stream;
	}

	/**
	 * Transform a "human" local date indication to a proper LocalDateTime to be used in database queries.
	 * The complete list of available formats is currently :
	 * - "now" : current date time accurate to the second
	 * - "tomorrow" : see "now"
	 * - "dd/mm/yyyy" and "dd/mm/yyyy hh:mi:ss": commonly used formats in France
	 * - "yyyy-mm-dd'T'hh:mi:ss": ISO8601 without timezone
	 * - "yyyy-mm-dd'T'hh:mi:ssZ": ISO8601 UTC (as returned by Javascript Date.toISOString()
	 * - "yyyy", "yyyy-mm, "yyyy-mm-dd": ISO8601-derived for years, months, dates, ...
	 *   they are interpreted as the 1st day of the time span, starting as midnight.
	 *
	 * @param paramDate - a convenient value for filtering by date
	 * @return the corresponding LocalDateTime
	 * @throws an IllegalArgumentException when no date can be deduced
	 */
	public static LocalDateTime parseParamDate(String paramDate) {
		if (paramDate == null)
			throw new IllegalArgumentException("Cannot parse null parameter to date.");
		paramDate = paramDate.trim();
		if (paramDate.equals(""))
			throw new IllegalArgumentException("Cannot parse empty parameter to date.");

		if (paramDate.equals("now"))
			return LocalDateTime.now();
		else if (paramDate.equals("tomorrow"))
			return LocalDateTime.now().plusDays(1);
		else if (localDatePattern.matcher(paramDate).matches())
			return java.time.LocalDateTime.parse(paramDate + " 00:00:00", frenchLocalDTFormatter);
		else if (localDateTimePattern.matcher(paramDate).matches())
			return java.time.LocalDateTime.parse(paramDate + ":00", frenchLocalDTFormatter);
		else if (localDateTimeSecPattern.matcher(paramDate).matches())
			return java.time.LocalDateTime.parse(paramDate, frenchLocalDTFormatter);
		else if (isoDateTimePattern.matcher(paramDate).matches()) {
			Instant instant = Instant.parse(paramDate);
			return LocalDateTime.ofInstant(instant, java.time.ZoneId.systemDefault());
			// expected default to "here in France"
		} else {
			String extendedTimeValue;
			if (yearPattern.matcher(paramDate).matches()) {
				extendedTimeValue = paramDate + "-01-01T00:00:00";
			} else if (monthPattern.matcher(paramDate).matches()) {
				extendedTimeValue = paramDate + "-01T00:00:00";
			} else if (dayPattern.matcher(paramDate).matches()) {
				extendedTimeValue = paramDate + "T00:00:00";
			} else {
				extendedTimeValue = paramDate; // let the smart thing do its best
			}

			return java.time.LocalDateTime.parse(extendedTimeValue);
		}
	}

	private static final java.time.format.DateTimeFormatter frenchLocalDTFormatter = java.time.format.DateTimeFormatter
	    .ofPattern("dd/MM/uuuu HH:mm:ss");
	private static final java.util.regex.Pattern localDatePattern = java.util.regex.Pattern
	    .compile("^\\d{2}/\\d{2}/\\d{4}");
	private static final java.util.regex.Pattern localDateTimePattern = java.util.regex.Pattern
	    .compile("^\\d{2}/\\d{2}/\\d{4} \\d{2}:\\d{2}$");
	private static final java.util.regex.Pattern localDateTimeSecPattern = java.util.regex.Pattern
	    .compile("^\\d{2}/\\d{2}/\\d{4} \\d{2}:\\d{2}:\\d{2}$");
	private static final java.util.regex.Pattern isoDateTimePattern = java.util.regex.Pattern
	    .compile("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d+)?Z$");

	private static final java.util.regex.Pattern yearPattern = java.util.regex.Pattern.compile("^\\d{4}$");
	private static final java.util.regex.Pattern monthPattern = java.util.regex.Pattern.compile("^\\d{4}-\\d{2}$");
	private static final java.util.regex.Pattern dayPattern = java.util.regex.Pattern.compile("^\\d{4}-\\d{2}-\\d{2}$");

}
