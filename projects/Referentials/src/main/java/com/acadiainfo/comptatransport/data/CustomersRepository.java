package com.acadiainfo.comptatransport.data;

import com.acadiainfo.comptatransport.domain.Customer;
import com.acadiainfo.util.persistence.CrudRepositoryImpl;

import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;

public class CustomersRepository extends CrudRepositoryImpl<Customer, Long> {

	/**
	 * (Current impl. gives a new one at each call).
	 * @param em
	 * @return
	 */
	public static CustomersRepository getInstance(EntityManager em) {
		return new CustomersRepository(em);
	}

	private CustomersRepository(EntityManager em) {
		super(em);
	}

	@Override
	protected Class<Customer> getEntityClass() {
		return Customer.class;
	}

	@Override
	protected Long getEntityKey(Customer t) {
		return t.getId();
	}

	/**
	 * Excluding "Customer.shipPreferences" to preserve them in a "normal" update.
	 * They are never removed, so for WS we would add them with a special PATCH service.
	 */
	@Override
	protected boolean excludeFromPatchBean(String propertyName) {
		return "ShipPreferences".equals(propertyName);
	}

	/**
	 * Used for preemptive check on UNIQUE constraint.
	 * @param erpReference
	 * @return
	 */
	@SuppressWarnings("unchecked")
	public Customer findByErpReference(String erpReference) {
		EntityManager em = this.getEntityManager();
		Query query = em.createQuery("SELECT c FROM Customer c WHERE c.erpReference = :erpReference");
		query.setParameter("erpReference", erpReference);

		return (Customer) query.getResultStream().findFirst().orElse(null);
	}

}
