package com.acadiainfo.util;

import java.io.IOException;
import java.util.stream.Stream;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.core.*;

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

}
