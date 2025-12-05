package com.acadiainfo.comptatransport.fileimport;

import com.acadiainfo.comptatransport.fileimport.ConfigImport.ConfigColumn;

import jakarta.json.JsonArray;
import jakarta.json.JsonValue;
import jakarta.json.stream.JsonParser;
import jakarta.json.stream.JsonParserFactory;
import jakarta.persistence.AttributeConverter;

public class ConfigImportColumnConverter implements AttributeConverter<ConfigColumn[], String> {
	private static jakarta.json.bind.Jsonb jsonb = jakarta.json.bind.JsonbBuilder.create();
	private static JsonParserFactory parserFactory = jakarta.json.Json.createParserFactory(null);
	private static ConfigColumn[] EMPTY = new ConfigColumn[0];

	@Override
	public String convertToDatabaseColumn(ConfigColumn[] arg0) {
		throw new UnsupportedOperationException("Not implemented, maybe if we write a UI to edit them...");
	}

	@Override
	public ConfigColumn[] convertToEntityAttribute(String s) {
		java.util.List<ConfigColumn> result = new java.util.ArrayList<>();

		JsonParser parser = parserFactory.createParser(java.io.StringReader.of(s));
		JsonArray jsonArr = parser.getArray();
		for (JsonValue val : jsonArr) {
			result.add(jsonb.fromJson(val.toString(), ConfigColumn.class));
		}
		return result.toArray(EMPTY);
	}

}