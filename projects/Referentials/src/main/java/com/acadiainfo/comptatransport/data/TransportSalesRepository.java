package com.acadiainfo.comptatransport.data;

import java.time.LocalDateTime;
import java.util.logging.Logger;
import java.util.stream.Stream;

import com.acadiainfo.comptatransport.domain.TransportSalesHeader;

import jakarta.persistence.Column;
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

}
