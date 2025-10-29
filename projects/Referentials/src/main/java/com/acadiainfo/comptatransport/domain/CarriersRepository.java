package com.acadiainfo.comptatransport.domain;

import com.acadiainfo.util.persistence.CrudRepositoryImpl;

import jakarta.persistence.EntityManager;

public class CarriersRepository extends CrudRepositoryImpl<Carrier, String> {

	/**
	 * (Current impl. gives a new one at each call).
	 * @param em
	 * @return
	 */
	public static CarriersRepository getInstance(EntityManager em) {
		return new CarriersRepository(em);
	}

	private CarriersRepository(EntityManager em) {
		super(em);
	}

	@Override
	protected Class<Carrier> getEntityClass() {
		return Carrier.class;
	}

	@Override
	protected String getEntityKey(Carrier t) {
		return t.getName();
	}



}
