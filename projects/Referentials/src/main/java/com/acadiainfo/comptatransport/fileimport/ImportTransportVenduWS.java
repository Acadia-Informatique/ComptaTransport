package com.acadiainfo.comptatransport.fileimport;

import java.math.BigDecimal;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.logging.Logger;

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
@jakarta.ws.rs.Path("/import-transport-vendu")
@TransactionManagement(TransactionManagementType.BEAN)
public class ImportTransportVenduWS {
	private static final Logger logger = Logger.getLogger(ImportTransportVenduWS.class.getName());

	// TODO replace with import from email
	public static final String IMPORT_TYPE = "Transport Vendu";

	public static final long TRANSACTION_BATCH_SIZE = 20;

	@Resource
	private UserTransaction ut;

	@PersistenceContext(unitName = "ComptaTransportPU")
	private EntityManager em;

	@jakarta.ws.rs.GET
	@Produces(value = MediaType.TEXT_PLAIN)
	public String startBatch() {
		try {
			try {
				Import importHeader = this.readExcel();
				int customerCreated = createMissingCustomers(importHeader);

				return "rows imported : " + importHeader.getRowCount()
				  + "\ncustomers created: " + customerCreated;
			} catch (Exception e) {
				ut.rollback();
				throw e;
			}
		} catch (Exception exc) {
			logger.log(java.util.logging.Level.SEVERE, "Error importing " + IMPORT_TYPE, exc);
			return "Error importing : " + exc.getMessage();
		}
	}

	private Import readExcel() throws Exception {
		ut.begin();
		ConfigImport config = em.find(ConfigImport.class, IMPORT_TYPE);
		if (config == null) {
			throw new IllegalArgumentException("No config with type=[" + IMPORT_TYPE + "] found");
		}

		// 1) Create header
		Import importHeader = new Import();
		importHeader.setType(IMPORT_TYPE);
		em.persist(importHeader);
		em.flush();
		ut.commit();
		ut.begin();

		// 2) iterate over rows
		AtomicInteger rowCount = new AtomicInteger(0);
		RowsProvider rowsProvider = new RowsProvider(config);
		rowsProvider.walkRows(m -> {
			ImportTransportVendu entity = new ImportTransportVendu();

			entity.setImportHeader(importHeader);

			entity.setCodeSociete((String) m.get("SOC_CODE"));
			entity.setOrderReference((String) m.get("NUM_CMD"));
			entity.setDocReference((String) m.get("NUM_DOC"));
			entity.setOrigDocReference(entity.getDocReference()); // this setter's only call, as a pristine val.
			entity.setCustomerErpReference((String) m.get("VENDU_A"));
			entity.setCustomerLabel((String) m.get("NOM_VENDU_A"));
			entity.setProductDesc((String) m.get("DESCRIPTION_1"));

			/* we don't store the street addresses anyway */
			// String billing_addr = m.get("ADR_FACTURATION");
			// String shipping_addr = m.get("ADR_LIVRAISON");
			// entity.setB2c(!billing_addr.equals(shipping_addr)); heuristics not reliable.
			entity.setB2c(false); // TODO find a better way to tell B2C orders from the others.

			entity.setCarrierName((String) m.get("TRANSP_CODE"));
			entity.setShipCountry((String) m.get("PAYS"));
			entity.setShipZipcode((String) m.get("CP"));

			entity.setDocDate((java.time.LocalDateTime) m.get("DATE_COMPTA"));

			entity.setSalesrep((String) m.get("SALESREP"));

			entity.setTotalWeight((BigDecimal) m.get("POIDS"));

			entity.setTotalPrice((BigDecimal) m.get("MONTANT"));

			em.persist(entity);

			// purge previous
			Query deleteDupesQuery = em.createNamedQuery("ImportTransportVendu.purgePrevious");
			deleteDupesQuery.setParameter("docReference", entity.getDocReference());
			deleteDupesQuery.setParameter("importHeader", importHeader);
			deleteDupesQuery.executeUpdate(); // maybe record purged row count ?...

			if (rowCount.getAndIncrement() % TRANSACTION_BATCH_SIZE == 0) {
				em.flush();
				try {
					ut.commit();
					ut.begin(); // for next loop
				} catch (Exception e) { // SecurityException, RollbackException, HeuristicMixedException,
				                        // HeuristicRollbackException, SystemException, NotSupportedException
					throw new RuntimeException(e);
				}
			}
		});

		// 3) close header
		importHeader.setRowCount(rowCount.get());
		importHeader.setDateEnded(System.currentTimeMillis());
		em.merge(importHeader);

		em.flush();
		ut.commit();
		return importHeader;
	}




	private int createMissingCustomers(Import importHeader) throws Exception {
		ut.begin();
		Query query = em.createNamedQuery("ImportTransportVendu_as_new_Customers");
		query.setParameter(1, importHeader.getId());

		@SuppressWarnings("unchecked")
		List<Customer> customers = query.getResultList();
		for (Customer customer : customers) {
			em.detach(customer);
			customer.getTags().add("IMPORT");
			customer.getTags().add("inactive"); // TODO remove when then the view will support pagination
			customer.setDescription("(créé par import de frais de port)");
			em.persist(customer);
		}
		em.flush();
		ut.commit();
		return customers.size();
	}
}
