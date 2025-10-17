package com.acadiainfo.util.persistence;


import java.util.Set;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class StringSetConverter extends StringsConverterImpl implements AttributeConverter<Set<String>, String> {
	
    @Override
	public Set<String> convertToEntityAttribute(String dbData) {
		String[] value = this._doConvertToEntityAttribute(dbData);
		return new java.util.TreeSet<>(java.util.Arrays.asList(value));
    }

	@Override
	public String convertToDatabaseColumn(Set<String> value) {
		String dbData = this._doConvertToDatabaseColumn(value);
		return dbData;
	}


}