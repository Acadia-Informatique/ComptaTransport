package com.acadiainfo.util.persistence;

import java.util.List;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

/**
 * JPA Converter for all these omnipresent String list properties.
 */
@Converter(autoApply = true) // Sometimes you may want a @ElementCollection, to make it SQL-queryable. Use
								// @Convert(disableConversion = true) on that field then.
public class StringListConverter extends StringsConverterImpl implements AttributeConverter<List<String>, String> {


    @Override
	public List<String> convertToEntityAttribute(String dbData) {
		String[] value = this._doConvertToEntityAttribute(dbData);
		return java.util.Arrays.asList(value);
    }

	@Override
	public String convertToDatabaseColumn(List<String> value) {
		String dbData = this._doConvertToDatabaseColumn(value);
		return dbData;
	}
}