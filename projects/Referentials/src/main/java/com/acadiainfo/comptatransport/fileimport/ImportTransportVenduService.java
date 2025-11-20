package com.acadiainfo.comptatransport.fileimport;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.util.Iterator;

import org.dhatim.fastexcel.reader.ReadableWorkbook;
import org.dhatim.fastexcel.reader.Row;
import org.dhatim.fastexcel.reader.Sheet;

import jakarta.annotation.Resource;
import jakarta.ejb.Stateless;
import jakarta.ejb.TransactionManagement;
import jakarta.ejb.TransactionManagementType;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.HeuristicMixedException;
import jakarta.transaction.HeuristicRollbackException;
import jakarta.transaction.NotSupportedException;
import jakarta.transaction.RollbackException;
import jakarta.transaction.SystemException;
import jakarta.transaction.UserTransaction;

@Stateless
@jakarta.ws.rs.Path("/import-test")
@TransactionManagement(TransactionManagementType.BEAN)
public class ImportTransportVenduService {
	public static final String IMPORT_TYPE = "Transport Vendu";

	@Resource
	private UserTransaction ut;

	public static final long TRANSACTION_BATCH_SIZE = 20;

	private static final int H1_SOCIETE = 0, H1_CLIENT = 3, H1_ARTICLE = 5, H1_TRANSPORTEUR = 6, H1_VENTES = 12,
	    H1_VENTES_2 = 14;
	private static final int H2_SOC_CODE = 0, H2_NUM_CMD = 1, H2_NUM_DOC = 2, H2_VENDU_A = 3, H2_NOM_VENDU_A = 4,
	    H2_DESCRIPTION_1 = 5, H2_TRANSP_CODE = 6, H2_PAYS = 7, H2_ADR_FACTURATION = 8, H2_ADR_LIVRAISON = 9, H2_CP = 10,
	    H2_DATE_COMPTA = 11, H2_SALESREP = 12, H2_POIDS = 13, H2_MONTANT = 14;

	@PersistenceContext(unitName = "ComptaTransportPU")
	private EntityManager em;

	@jakarta.ws.rs.GET
	public void startBatch() throws IllegalStateException, SecurityException, SystemException {
		try {
			this.readExcel();
		} catch (Exception e) {
			ut.rollback();
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	public void readExcel()
	    throws FileNotFoundException, IOException, NotSupportedException, SystemException, SecurityException,
	    IllegalStateException, RollbackException, HeuristicMixedException, HeuristicRollbackException {
		boolean validateHeader = true;
		//TODO path in app properties

		try (InputStream is = new java.io.FileInputStream("C:\\Users\\Robert.KWAN\\Documents\\ComptaTransport-input\\Transport quotidien.xlsx");
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
			long iterationCount = -1;
			while (rowsIterator.hasNext()) {
		    	Row row = rowsIterator.next();
				iterationCount++;

		    	if (iterationCount == 0 && validateHeader) {//Note : row 0 is empty, so the lib already skips it
				    if (!("Société".equals(row.getCell(H1_SOCIETE).asString())
					&& "Client".equals(row.getCell(H1_CLIENT).asString())
					&& "Article".equals(row.getCell(H1_ARTICLE).asString())
					&& "Transporteur".equals(row.getCell(H1_TRANSPORTEUR).asString())
					&& "Ventes".equals(row.getCell(H1_VENTES).asString())
					&& "Ventes".equals(row.getCell(H1_VENTES_2).asString()))) {
						throw new IllegalArgumentException("Row 2 is not the expected header : " + row);
					}
		    	} else if (iterationCount == 1 && validateHeader) {
				    if (!("Code".equals(row.getCell(H2_SOC_CODE).asString())
					&& "Numéro de commande".equals(row.getCell(H2_NUM_CMD).asString())
					&& "N° Document".equals(row.getCell(H2_NUM_DOC).asString())
					&& "Vendu-à".equals(row.getCell(H2_VENDU_A).asString())
					&& "Nom Vendu-à".equals(row.getCell(H2_NOM_VENDU_A).asString())
					&& "Description 1".equals(row.getCell(H2_DESCRIPTION_1).asString())
					&& "Code".equals(row.getCell(H2_TRANSP_CODE).asString())
					&& "Pays livraison".equals(row.getCell(H2_PAYS).asString())
					&& "Adresse de Facture 0".equals(row.getCell(H2_ADR_FACTURATION).asString())
					&& "Adresse de Livraison 0".equals(row.getCell(H2_ADR_LIVRAISON).asString())
					&& "Code postal livraison".equals(row.getCell(H2_CP).asString())
					&& "Date comptable".equals(row.getCell(H2_DATE_COMPTA).asString())
					&& "Nom du représentant 1".equals(row.getCell(H2_SALESREP).asString())
					&& "Cumul poids".equals(row.getCell(H2_POIDS).asString())
					&& "Montant GL".equals(row.getCell(H2_MONTANT).asString()))) {
						throw new IllegalArgumentException("Row 3 is not the expected header : " + row);
					}
		    	} else if ("".equals(row.getCellAsString(H2_SOC_CODE).orElse(null))
		        	  && row.getCellAsNumber(H2_MONTANT).orElse(java.math.BigDecimal.ZERO).floatValue()>0) {
	        		// - Grand total (final row)
	        		//... ignore it
	        	} else {
	        		// - regular row
					ImportTransportVendu entity = new ImportTransportVendu();

					entity.setImportHeader(importHeader);

					entity.setCodeSociete(row.getCellAsString(H2_SOC_CODE).orElse(null));
					entity.setOrderReference(row.getCellAsString(H2_NUM_CMD).orElse(null));
					entity.setDocReference(row.getCellAsString(H2_NUM_DOC).orElse(null));
					entity.setCustomerErpReference(row.getCellAsString(H2_VENDU_A).orElse(null));
					entity.setCustomerLabel(row.getCellAsString(H2_NOM_VENDU_A).orElse(null));
					entity.setProductDesc(row.getCellAsString(H2_DESCRIPTION_1).orElse(null));


					/* we don't store the street addresses */
					String billing_addr = row.getCellAsString(H2_ADR_FACTURATION).orElse("");
					String shipping_addr = row.getCellAsString(H2_ADR_LIVRAISON).orElse("");
					entity.setB2c(!billing_addr.equals(shipping_addr));

					entity.setCarrierName(row.getCellAsString(H2_TRANSP_CODE).orElse(null));
					entity.setShipCountry(row.getCellAsString(H2_PAYS).orElse(null));
					entity.setShipZipcode(row.getCellAsString(H2_CP).orElse(null));

					entity.setDocDate(row.getCellAsDate(H2_DATE_COMPTA).orElse(null));

					entity.setSalesrep(row.getCellAsString(H2_SALESREP).orElse(null));

					entity.setTotalWeight(row.getCellAsNumber(H2_POIDS).orElse(null));

					entity.setTotalPrice(row.getCellAsNumber(H2_MONTANT).orElse(null));

					em.persist(entity);
					if (iterationCount % TRANSACTION_BATCH_SIZE == 0) {
						em.flush();
						ut.commit();
						ut.begin(); // for next loop
					}
	        	}
		    }

			ut.commit();

		    //3) close header
			// TODO write _date_ended

		} // end try with resources
	}
}
