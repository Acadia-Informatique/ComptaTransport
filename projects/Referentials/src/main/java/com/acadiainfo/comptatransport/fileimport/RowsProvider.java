package com.acadiainfo.comptatransport.fileimport;

import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.Iterator;
import java.util.Map;
import java.util.Optional;
import java.util.function.Consumer;
import java.util.logging.Logger;

import org.dhatim.fastexcel.reader.ReadableWorkbook;
import org.dhatim.fastexcel.reader.Row;
import org.dhatim.fastexcel.reader.Sheet;

import com.acadiainfo.comptatransport.fileimport.ConfigImport.ConfigColumn;

/**
 * Tabular row provider, currently supports only Excel rows.
 * TODO support CSV with a sprinkle of polymorphism ;-)
 */
public class RowsProvider {
	private static final Logger logger = Logger.getLogger(RowsProvider.class.getName());

	private ConfigImport config;
	private URI srcUri;
	private String excelSheet;

	public RowsProvider(ConfigImport config) {
		this.config = config;
	}

	/**
	 * Resolve these "import-specific URIs".
	 * @return
	 * @throws URISyntaxException
	 * @throws IOException
	 */
	protected InputStream open() throws URISyntaxException, IOException {
		this.srcUri = new URI(this.config.src_path);
		switch (srcUri.getScheme()) {
		case "file": // TODO support other formats than Excel
			this.excelSheet = this.srcUri.getFragment();
			return srcUri.toURL().openStream();
		// TODO implement here all the funny mail-based URIs.
		default:
			throw new UnsupportedOperationException(
			    "This class does not support (yet) the specified URI scheme : " + srcUri.getScheme());
		}
	}

	public void walkRows(Consumer<Map<String, Object>> callback) throws Exception {
		try (InputStream is = this.open(); ReadableWorkbook wb = new ReadableWorkbook(is)) {
			Sheet dataSheet;
			if (this.excelSheet == null) {
				logger.fine("Excel sheet name not specified, assuming 1st is the one to read.");
				dataSheet = wb.getFirstSheet();
			} else {
				Optional<Sheet> oSheet = wb.findSheet(excelSheet);
				if (oSheet.isEmpty())
					throw new java.util.NoSuchElementException("Excel sheet name not found : " + this.excelSheet);
				dataSheet = oSheet.get();
			}

			java.util.List<Row> rows = dataSheet.read();
			Iterator<Row> rowsIterator = rows.iterator();

			while (rowsIterator.hasNext()) {
				Row row = rowsIterator.next();
				if (row.getRowNum() == this.config.src_colLabelsRowid) {
					validateColumnNames(row);
				}
				if (row.getRowNum() >= this.config.src_dataRowid) {
					processRow(row, callback);
				}

			}
		}
	}

	private Map<String, Object> recycledMap = new java.util.HashMap<>(); // recycled as a flyw weight

	private void processRow(Row row, Consumer<Map<String, Object>> callback) {
		if (this.config.src_col_condition != null) {
			String val_condition = row.getCellAsString(this.config.src_col_condition.intValue()).orElse(null);
			if (val_condition == null || val_condition.equals("")) {
				logger.fine("Row skipped because of empty src_col_condition");
				return;
			}
		}

		for (ConfigColumn columnConf : this.config.dst_mapping) {
			Object colValue;

			if (columnConf.colIndex < 0) {
				// A) negative index : computed and constant values
				colValue = switch (columnConf.datatype) {
				// Basic Excel types
				case "STRING" -> columnConf.colLabel;
				case "NUMBER" -> new java.math.BigDecimal(columnConf.colLabel);
				case "DATE" -> LocalDateTime.parse(columnConf.colLabel);
				case "BOOLEAN" -> Boolean.valueOf(columnConf.colLabel);
				default ->
				    throw new UnsupportedOperationException("Const datatype not supported : " + columnConf.datatype);
				};
			} else {
				// B) normal case : read value from cell
				int colIdx = columnConf.colIndex - 1; // fastexcel API uses zero-based index
				try {
					colValue = switch (columnConf.datatype) {
					// Basic Excel types
					case "STRING" -> row.getCellAsString(colIdx).orElse(null);
					case "NUMBER" -> row.getCellAsNumber(colIdx).orElse(null);
					case "DATE" -> row.getCellAsDate(colIdx).orElse(null);
					case "BOOLEAN" -> row.getCellAsBoolean(colIdx).orElse(null);

					// Simple conversions
					case "DATE_AS_ISO_LOCAL_DATE" -> parseHiphenedYYYYMMDD(row.getCellAsString(colIdx).orElse(null));

					default ->
					    throw new UnsupportedOperationException("Datatype not supported : " + columnConf.datatype);
					};
				} catch (org.dhatim.fastexcel.reader.ExcelReaderException exc) {

					throw new UnsupportedOperationException(
					  "Error reading column [propertyName=\"" + columnConf.propertyName + "\"] at row #"
					  + row.getRowNum() + ": " + exc.getMessage());
				}
			}
			recycledMap.put(columnConf.propertyName, colValue);
		}

		callback.accept(recycledMap);
	}

	private void validateColumnNames(Row row) {
		for (ConfigColumn columnConf : this.config.dst_mapping) {
			if (columnConf.colIndex < 0) continue; // for e.g, -1 marks computed and constant values
			int colIdx = columnConf.colIndex - 1; // fastexcel API uses zero-based index

			String expectedColName = columnConf.colLabel;
			String actualColName = (colIdx < row.getCellCount()) ? row.getCellAsString(colIdx).orElse("")
			  : "";

			if (!expectedColName.equalsIgnoreCase(actualColName)) {
				// equalsIgnoreCase() a bit more lenient that equals()...
				throw new java.util.NoSuchElementException(
				  "Expected column name : [" + expectedColName + "], got [" + actualColName + "] instead.");
			}
		}

	}


	protected static LocalDateTime parseHiphenedYYYYMMDD(String value) {
		if (value == null) return null;
		LocalDate parsedDate = LocalDate.parse(value, DateTimeFormatter.ISO_LOCAL_DATE);
		return LocalDateTime.of(parsedDate, LocalTime.MIDNIGHT);
	}
}
