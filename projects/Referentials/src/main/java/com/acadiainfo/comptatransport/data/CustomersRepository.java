package com.acadiainfo.comptatransport.data;

import java.util.stream.Stream;

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
		Query query = em.createNamedQuery("Customer.findByErpRef");
		query.setParameter("erpReference", erpReference);
		return (Customer) query.getResultStream().findFirst().orElse(null);
	}

	/**
	 * Find Customers matching given label (=name), some even remotely.
	 * @param label
	 * @return
	 */
	public Stream<Customer> findAllByLabel(String label) {
		Query query = em.createNamedQuery("Customer.findClosestByLabel");
		query.setParameter(1, label);

		@SuppressWarnings("unchecked")
		Stream<Customer> resultStream = query.getResultStream();
		return resultStream;
	}
}
