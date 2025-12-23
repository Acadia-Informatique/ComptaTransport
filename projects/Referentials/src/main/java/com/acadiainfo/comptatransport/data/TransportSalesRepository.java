package com.acadiainfo.comptatransport.data;

import java.time.LocalDateTime;
import java.util.logging.Logger;
import java.util.stream.Stream;

import com.acadiainfo.comptatransport.domain.TransportSalesHeader;

import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;

public class TransportSalesRepository {
	private static final Logger logger = Logger.getLogger(TransportSalesRepository.class.getName());

	/**
	 * (Current impl. gives a new one at each call).
	 * @param em
	 * @return
	 */
	public static TransportSalesRepository getInstance(EntityManager em) {
		return new TransportSalesRepository(em);
	}

	private EntityManager em;

	private TransportSalesRepository(EntityManager em) {
		this.em = em;
	}

	public Stream<TransportSalesHeader> getAllBetween(LocalDateTime start_date, LocalDateTime end_date) {
		// Query query = em.createNamedQuery("TransportSalesHeader_as_ORDER");
		/*
		 * Commented out in same entity. Not used, but it is simpler than _as_INVOICE.
		 * The relationship between xxxHeader and xxxDetail would change too
		 * (FK to doc(=invoice) -> order).
		 */
		Query query = em.createNamedQuery("TransportSalesHeader_as_INVOICE");
		query.setParameter(1, start_date);
		query.setParameter(2, end_date);

		@SuppressWarnings("unchecked")
		Stream<TransportSalesHeader> stream = query.getResultStream();

		return stream;
	}


	/**
	 * Find a TransportSalesHeader by invoice number.
	 * @param docReference - more accurately,the *original* invoice number (before grouping)
	 * @return
	 */
	public TransportSalesHeader getOne(String docReference) {
		Query query = em.createNamedQuery("findOne_TransportSalesHeader_as_INVOICE");
		query.setParameter(1, docReference);

		try {
			TransportSalesHeader header = (TransportSalesHeader) query.getSingleResult();
			return header;
		} catch (jakarta.persistence.NoResultException exc) {
			return null;
		}
	}

	/**
	 * Find a TransportSalesHeader by order number.
	 * @param orderNum
	 * @return
	 */
	public TransportSalesHeader findByOrderNum(String orderNum) {
		Query query = em
		    .createNativeQuery("SELECT max(orig_doc_reference) FROM I_TRANSPORT_VENDU WHERE order_reference = ?1");
		query.setParameter(1, orderNum);
		String docReference = (String) query.getSingleResult();
		if (docReference == null) return null;
		return this.getOne(docReference);
	}

}
