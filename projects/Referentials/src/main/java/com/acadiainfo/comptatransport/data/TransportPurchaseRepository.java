package com.acadiainfo.comptatransport.data;

import java.time.LocalDateTime;
import java.util.stream.Stream;

import com.acadiainfo.comptatransport.domain.TransportPurchaseHeader;
import com.acadiainfo.util.persistence.CrudRepositoryImpl;

import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;

public class TransportPurchaseRepository extends CrudRepositoryImpl<TransportPurchaseHeader, Long> {
	// private static final Logger logger =
	// Logger.getLogger(TransportPurchaseRepository.class.getName());

	/**
	 * (Current impl. gives a new one at each call).
	 * @param em
	 * @return
	 */
	public static TransportPurchaseRepository getInstance(EntityManager em) {
		return new TransportPurchaseRepository(em);
	}

	private TransportPurchaseRepository(EntityManager em) {
		super(em);
	}

	@Override
	protected Class<TransportPurchaseHeader> getEntityClass() {
		return TransportPurchaseHeader.class;
	}

	@Override
	protected Long getEntityKey(TransportPurchaseHeader t) {
		return t.getId();
	}

	/**
	 * Get all rows of "Carrier invoices", regardless of  Company or Products,
	 * based on the date of invoice
	 * @param start_date - with .carrierInvoiceDate equals or after that
	 * @param end_date - with .carrierInvoiceDate strictly before that
	 * @return
	 */
	public Stream<TransportPurchaseHeader> getAllBetween(LocalDateTime start_date, LocalDateTime end_date) {
		// Query query = em.createNamedQuery("TransportSalesHeader_as_ORDER");
		/*
		 * Commented out in same entity. Not used, but it is simpler than _as_INVOICE.
		 * The relationship between xxxHeader and xxxDetail would change too (FK to
		 * doc(=invoice) -> order).
		 */
		Query query = em.createQuery("SELECT DISTINCT tph FROM TransportPurchaseHeader tph "
		   + " LEFT JOIN FETCH tph.article"
		   + " LEFT JOIN FETCH tph.userInputs uimp"
		   + " LEFT JOIN FETCH uimp.mappedInvoices"
		   + " WHERE tph.carrierInvoiceDate >= ?1 AND tph.carrierInvoiceDate < ?2");
		query.setParameter(1, start_date);
		query.setParameter(2, end_date);

		@SuppressWarnings("unchecked")
		Stream<TransportPurchaseHeader> stream = query.getResultStream();

		return stream;
	}
}
