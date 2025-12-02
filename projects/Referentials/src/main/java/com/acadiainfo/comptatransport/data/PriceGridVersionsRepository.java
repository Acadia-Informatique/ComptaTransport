package com.acadiainfo.comptatransport.data;


import java.time.LocalDateTime;
import java.util.List;

import com.acadiainfo.comptatransport.domain.PriceGridVersion;
import com.acadiainfo.util.persistence.CrudRepositoryImpl;

import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;

public class PriceGridVersionsRepository extends CrudRepositoryImpl<PriceGridVersion, Long> {

	/**
	 * (Current impl. gives a new one at each call).
	 * @param em
	 * @return
	 */
	public static PriceGridVersionsRepository getInstance(EntityManager em) {
		return new PriceGridVersionsRepository(em);
	}

	private PriceGridVersionsRepository(EntityManager em) {
		super(em);
	}

	@Override
	protected Class<PriceGridVersion> getEntityClass() {
		return PriceGridVersion.class;
	}

	@Override
	protected Long getEntityKey(PriceGridVersion t) {
		return t.getId();
	}

	/**
	 * That TEXT column behaves weirdly regarding transactions, worth investigating.
	 */
	@Override
	protected boolean excludeFromPatchBean(String propertyName) {
		return "JsonContent".equalsIgnoreCase(propertyName);
	}

	/**
	 * Substitute to a OneToMany relationship (PriceGrid.versions).
	 * @param id - parent PriceGrid id
	 * @return
	 */
	public List<PriceGridVersion> findAllOfOnePriceGrid(Long id) {
		Query query = em
		    .createQuery("SELECT pgv FROM PriceGridVersion pgv WHERE pgv.priceGrid.id=:id ORDER BY pgv.version desc");
		query.setParameter("id", id);

		@SuppressWarnings("unchecked")
		List<PriceGridVersion> versions = query.getResultList();

		return versions;
	}

	/**
	 * Same as {@link #findAllOfOnePriceGrid(Long)}, only with an applicable date.
	 * @param id - parent PriceGrid id
	 * @param dtPublishedAt
	 * @return reversed-ordered by publishedDate
	 */
	public List<PriceGridVersion> findAllPublishedOfOnePriceGrid(Long id, LocalDateTime dtPublishedAt) {
		Query query = em.createQuery(
		        "SELECT pgv FROM PriceGridVersion pgv WHERE pgv.priceGrid.id=:id AND pgv.publishedDate <= :dtPublishedAt ORDER BY pgv.publishedDate desc");
		query.setParameter("id", id);
		query.setParameter("dtPublishedAt", dtPublishedAt);

		@SuppressWarnings("unchecked")
		List<PriceGridVersion> result = query.getResultList();
		return result;
	}


	/**
	 * Used for preemptive check on UNIQUE constraint.
	 * @param id
	 * @param version
	 * @return
	 */
	public PriceGridVersion findVersionOfOnePriceGrid(Long id, String version) {
		Query query = em.createQuery(
				"SELECT pgv FROM PriceGridVersion pgv WHERE pgv.priceGrid.id=:id AND pgv.version = :version");
		query.setParameter("id", id);
		query.setParameter("version", version);
		try {
			return (PriceGridVersion) query.getSingleResult();
		} catch (jakarta.persistence.NoResultException exc) {
			/* that is what we wanted : no duplicate */
			return null;
		}
	}
}
