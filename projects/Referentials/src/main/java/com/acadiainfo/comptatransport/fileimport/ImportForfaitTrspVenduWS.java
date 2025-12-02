package com.acadiainfo.comptatransport.fileimport;

import java.io.InputStream;
import java.util.Iterator;
import java.util.List;
import java.util.logging.Logger;

import org.dhatim.fastexcel.reader.ReadableWorkbook;
import org.dhatim.fastexcel.reader.Row;
import org.dhatim.fastexcel.reader.Sheet;

import com.acadiainfo.comptatransport.domain.AggShippingRevenue;
import com.acadiainfo.comptatransport.domain.Customer;

import jakarta.annotation.Resource;
import jakarta.ejb.Stateless;
import jakarta.ejb.TransactionManagement;
import jakarta.ejb.TransactionManagementType;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Query;
import jakarta.transaction.UserTransaction;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Stateless
@jakarta.ws.rs.Path("/import-forfait-trsp-vendu")
@TransactionManagement(TransactionManagementType.BEAN)
public class ImportForfaitTrspVenduWS {
	private static final Logger logger = Logger.getLogger(ImportForfaitTrspVenduWS.class.getName());

	// TODO replace with import from email
	public static final String IMPORT_FILE_PATH = "C:\\Users\\Robert.KWAN\\Documents\\ComptaTransport-input\\MONTHLY.xlsx";
	public static final String IMPORT_TYPE = "Forfait Transport Vendu";

	@Resource
	private UserTransaction ut;

	public static final long TRANSACTION_BATCH_SIZE = 20;

	private static final int H1_SOCIETE = 0, H1_CLIENT = 2, H1_ARTICLE = 4, H1_VENTES = 7;
	private static final int H2_SOC_CODE = 0, H2_NUM_DOC = 1, H2_VENDU_A = 2, H2_NOM_VENDU_A = 3,
		H2_CODE /*PRODUCT*/ = 4, H2_DESCRIPTION_1 = 5,
	    H2_DATE_COMPTA = 6, H2_SALESREP = 7, H2_MONTANT = 8;

	@PersistenceContext(unitName = "ComptaTransportPU")
	private EntityManager em;

	@jakarta.ws.rs.GET
	@Produces(value = MediaType.TEXT_PLAIN)
	public String startBatch() {
		try {
			Import importHeader = this.readExcel();
			int customerCreated = createMissingCustomers(importHeader);
			int aggregatesCreated = adjustAggShippingRevenues(importHeader);

			return "rows imported : " + importHeader.getRowCount() + "\ncustomers created: " + customerCreated
			    + "\naggregates created: " + aggregatesCreated;
		} catch (Exception exc) {
			logger.log(java.util.logging.Level.SEVERE, "Error importing " + IMPORT_TYPE, exc);
			return "Error importing : " + exc.getMessage();
		}
	}

	public Import readExcel() throws Exception {
		boolean validateHeader = true;

		try (InputStream is = new java.io.FileInputStream(IMPORT_FILE_PATH);
			ReadableWorkbook wb = new ReadableWorkbook(is)) {
		    Sheet sheet = wb.getFirstSheet();

		    //1) Create header
		    ut.begin();
			Import importHeader = new Import();
			importHeader.setType(IMPORT_TYPE);
			em.persist(importHeader);
			em.flush();
			ut.commit();

			ut.begin();

			//2) iterate over rows
		    java.util.List<Row> rows = sheet.read();
		    Iterator<Row> rowsIterator = rows.iterator();
			int iterationCount = -1, rowCount = 0;
			while (rowsIterator.hasNext()) {
		    	Row row = rowsIterator.next();
				iterationCount++;

		    	if (iterationCount == 0 && validateHeader) {//Note : row 0 is empty, so the lib already skips it
				    if (!("Société".equals(row.getCell(H1_SOCIETE).asString())
					&& "Client".equals(row.getCell(H1_CLIENT).asString())
					&& "Article".equals(row.getCell(H1_ARTICLE).asString())
					&& "Ventes".equals(row.getCell(H1_VENTES).asString())))
						throw new IllegalArgumentException("Row 2 is not the expected header : " + row);
		    	} else if (iterationCount == 1 && validateHeader) {
				    if (!("Code".equals(row.getCell(H2_SOC_CODE).asString())
					&& "N° Document".equals(row.getCell(H2_NUM_DOC).asString())
					&& "Vendu-à".equals(row.getCell(H2_VENDU_A).asString())
					&& "Nom Vendu-à".equals(row.getCell(H2_NOM_VENDU_A).asString())
					    && "Code".equals(row.getCell(H2_CODE).asString())
					&& "Description 1".equals(row.getCell(H2_DESCRIPTION_1).asString())
					&& "Date comptable".equals(row.getCell(H2_DATE_COMPTA).asString())
					&& "Nom du représentant 1".equals(row.getCell(H2_SALESREP).asString())
					&& "Montant GL".equals(row.getCell(H2_MONTANT).asString())))
						throw new IllegalArgumentException("Row 3 is not the expected header : " + row);
		    	} else if ("".equals(row.getCellAsString(H2_SOC_CODE).orElse(null))
		        	  && row.getCellAsNumber(H2_MONTANT).orElse(java.math.BigDecimal.ZERO).floatValue()>0) {
	        		// - Grand total (final row)
	        		//... ignore it
	        	} else {
					// - regular row
					ImportForfaitTrspVendu entity = new ImportForfaitTrspVendu();

					entity.setImportHeader(importHeader);

					entity.setCodeSociete(row.getCellAsString(H2_SOC_CODE).orElse(null));
					entity.setDocReference(row.getCellAsString(H2_NUM_DOC).orElse(null));
					entity.setCustomerErpReference(row.getCellAsString(H2_VENDU_A).orElse(null));
					entity.setCustomerLabel(row.getCellAsString(H2_NOM_VENDU_A).orElse(null));
					entity.setProductCode(row.getCellAsString(H2_CODE).orElse(null));
					entity.setProductDesc(row.getCellAsString(H2_DESCRIPTION_1).orElse(null));

					entity.setDocDate(row.getCellAsDate(H2_DATE_COMPTA).orElse(null));

					entity.setSalesrep(row.getCellAsString(H2_SALESREP).orElse(null));

					entity.setTotalPrice(row.getCellAsNumber(H2_MONTANT).orElse(null));

					em.persist(entity);

					// purge previous
					Query deleteDupesQuery = em.createNamedQuery("ImportForfaitTrspVendu.purgePrevious");
					deleteDupesQuery.setParameter("docReference", entity.getDocReference());
					deleteDupesQuery.setParameter("importHeader", importHeader);
					deleteDupesQuery.executeUpdate(); // maybe record purged row count ?...

					rowCount++;
					if (iterationCount % TRANSACTION_BATCH_SIZE == 0) {
						em.flush();
						ut.commit();
						ut.begin(); // for next loop
					}
	        	}
		    }

		    //3) close header
			importHeader.setRowCount(rowCount);
			importHeader.setDateEnded(System.currentTimeMillis());
			em.merge(importHeader);

			em.flush();
			ut.commit();
			return importHeader;

		} // end try with resources
	}

	private int createMissingCustomers(Import importHeader) throws Exception {
		try {
			ut.begin();
			Query query = em.createNamedQuery("ImportForfaitTrspVendu_as_new_Customers");
			query.setParameter(1, importHeader.getId());

			@SuppressWarnings("unchecked")
			List<Customer> customers = query.getResultList();
			for (Customer customer : customers) {
				em.detach(customer);
				customer.getTags().add("IMPORT forfait");
				customer.setDescription("(créé par import des Forfaits mensuels)");
				em.persist(customer);
			}
			em.flush();
			ut.commit();
			return customers.size();
		} catch (Exception e) {
			ut.rollback();
			throw e;
		}
	}

	private int adjustAggShippingRevenues(Import importHeader) throws Exception {
		try {
			ut.begin();
			Query query = em.createNamedQuery("ImportForfaitTrspVendu_as_new_AggShippingRevenues");
			query.setParameter(1, importHeader.getId());

			Query deleteDupesQuery = em.createNamedQuery("AggShippingRevenue.deleteByUniqueRef");

			@SuppressWarnings("unchecked")
			List<AggShippingRevenue> aggs = query.getResultList();
			for (AggShippingRevenue agg : aggs) {
				em.detach(agg);

				deleteDupesQuery.setParameter("customer", agg.getCustomer());
				deleteDupesQuery.setParameter("product", agg.getProduct());
				deleteDupesQuery.setParameter("date", agg.getDate());
				deleteDupesQuery.executeUpdate();
				em.flush();

				em.persist(agg);
			}
			em.flush();
			ut.commit();
			return aggs.size();
		} catch (Exception e) {
			ut.rollback();
			throw e;
		}
	}

}
