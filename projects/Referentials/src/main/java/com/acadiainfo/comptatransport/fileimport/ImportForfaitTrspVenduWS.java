package com.acadiainfo.comptatransport.fileimport;

import java.math.BigDecimal;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.logging.Logger;

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
	public static final String IMPORT_TYPE = "Forfait Transport Vendu";

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
				int aggregatesCreated = adjustAggShippingRevenues(importHeader);

				return "rows imported : " + importHeader.getRowCount()
				  + "\ncustomers created: " + customerCreated
				  + "\naggregates created: " + aggregatesCreated;
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
			ImportForfaitTrspVendu entity = new ImportForfaitTrspVendu();

			entity.setImportHeader(importHeader);

			entity.setCodeSociete((String) m.get("SOC_CODE"));
			entity.setDocReference((String) m.get("NUM_DOC"));
			entity.setCustomerErpReference((String) m.get("VENDU_A"));
			entity.setCustomerLabel((String) m.get("NOM_VENDU_A"));
			entity.setProductCode((String) m.get("CODE_PRODUIT"));
			entity.setProductDesc((String) m.get("DESCRIPTION_1"));

			entity.setDocDate((java.time.LocalDateTime) m.get("DATE_COMPTA"));

			entity.setSalesrep((String) m.get("SALESREP"));

			entity.setTotalPrice((BigDecimal) m.get("MONTANT"));

			em.persist(entity);

			// purge previous
			Query deleteDupesQuery = em.createNamedQuery("ImportForfaitTrspVendu.purgePrevious");
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
