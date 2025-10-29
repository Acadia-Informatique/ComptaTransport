package com.acadiainfo.util.persistence;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

/**
 * UTC Timestamps from MySQL are misinterpreted somewhere in the stack.
 * For an unknown reason, I can't make it work with all 
 * the parameters combinations found about it :
 * - useLegacyDatetimeCode=true (Connector/J 5.1)
 * - connectionTimeZone=LOCAL & forceConnectionTimeZoneToSession=false
 * - connectionTimeZone=LOCAL & forceConnectionTimeZoneToSession=true
 * - connectionTimeZone=SERVER & preserveInstants=true
 * - connectionTimeZone=user_defined & preserveInstants=true
 *
 * Now I am just using connectionTimeZone="UTC" for DATETIME columns, and this class for TIMESTAMP ones. 
 * TODO document current database settings (MySQL + UTC timezone + US-EN locale) 
 * 
 * And I don't want to change the JVM's user.timezone because *IT IS OUTRAGEOUS*. 
 * TODO find a way to make it work at JDBC driver level, and REMOVE it altogether.
 * 
 * @see <a href="https://dev.mysql.com/blog-archive/support-for-date-time-types-in-connector-j-8-0/">source for the (mostly useless) JDBC parameters</a>
 */
@Converter
public class AuditTimestampConverter implements AttributeConverter<Long, java.time.LocalDateTime> {

	@Override
	public LocalDateTime convertToDatabaseColumn(Long attribute) {
		throw new UnsupportedOperationException(
				"DEV error : code has been commented out for it is not supposed to be used.");
	}

	@Override
	public Long convertToEntityAttribute(LocalDateTime dbData) {
		if (dbData == null) {
			return null;
		}

		// -either the DB column value is at offset time zone (such as UTC)
		OffsetDateTime odt = dbData.atOffset(java.time.ZoneOffset.UTC);
		Instant ins = odt.toInstant();

		// - or the DB column value is at geographical time zone
		// ZonedDateTime zdt = dbData.atZone(java.time.ZoneId.of("Europe/Paris"));
		// Instant ins = zdt.toInstant();
		return ins.toEpochMilli();
	}

}
