package com.acadiainfo.comptatransport.data;

import java.time.LocalDateTime;
import java.util.logging.Logger;
import java.util.stream.Stream;

import com.acadiainfo.comptatransport.domain.AggShippingRevenue;
import com.acadiainfo.comptatransport.domain.Carrier;
import com.acadiainfo.comptatransport.domain.TransportSalesHeader;
import com.acadiainfo.util.persistence.CrudRepositoryImpl;

import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;

/**
 * Due to its sheer volume, AggShippingRevenue is not mapped as a child entity of Customer.
 * So it needs its own repository class.
 */
public class AggShippingRevenueRepository extends CrudRepositoryImpl<AggShippingRevenue, Long> {
	private static final Logger logger = Logger.getLogger(AggShippingRevenueRepository.class.getName());

	/**
	 * (Current impl. gives a new one at each call).
	 * @param em
	 * @return
	 */
	public static AggShippingRevenueRepository getInstance(EntityManager em) {
		return new AggShippingRevenueRepository(em);
	}

	private AggShippingRevenueRepository(EntityManager em) {
		super(em);
	}

	public Stream<TransportSalesHeader> getAllBetween(LocalDateTime start_date, LocalDateTime end_date) {
		Query query = em.createNamedQuery("AggShippingRevenue.findAllBetween");
		query.setParameter(1, start_date);
		query.setParameter(2, end_date);

		@SuppressWarnings("unchecked")
		Stream<TransportSalesHeader> stream = query.getResultStream();

		return stream;
	}
}
