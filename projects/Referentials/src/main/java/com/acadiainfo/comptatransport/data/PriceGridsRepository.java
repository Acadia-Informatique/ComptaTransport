package com.acadiainfo.comptatransport.data;


import com.acadiainfo.comptatransport.domain.PriceGrid;
import com.acadiainfo.util.persistence.CrudRepositoryImpl;

import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;

public class PriceGridsRepository extends CrudRepositoryImpl<PriceGrid, Long> {

	/**
	 * (Current impl. gives a new one at each call).
	 * @param em
	 * @return
	 */
	public static PriceGridsRepository getInstance(EntityManager em) {
		return new PriceGridsRepository(em);
	}

	private PriceGridsRepository(EntityManager em) {
		super(em);
	}

	@Override
	protected Class<PriceGrid> getEntityClass() {
		return PriceGrid.class;
	}

	@Override
	protected Long getEntityKey(PriceGrid t) {
		return t.getId();
	}

	/**
	 * Used for preemptive check on UNIQUE constraint.
	 * @param name
	 * @return
	 */
	@SuppressWarnings("unchecked")
	public PriceGrid findByName(String name) {
		Query query = em.createQuery("SELECT pg FROM PriceGrid pg WHERE pg.name = :name");
		query.setParameter("name", name);

		return (PriceGrid) query.getResultStream().findFirst().orElse(null);
	}
}
