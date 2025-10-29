package com.acadiainfo.util;

import java.io.IOException;
import java.util.stream.Stream;

import jakarta.ws.rs.core.*;

public class WSUtils {

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
