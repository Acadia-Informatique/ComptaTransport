package com.acadiainfo.comptatransport.domain;

import com.acadiainfo.util.persistence.CrudRepositoryImpl;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

/**
 * Handwritten implementation.
 * TODO JAKARTA DATA - remove when migrating to Jakarta EE 11
 */

@jakarta.enterprise.context.Dependent
public class CarriersImpl extends CrudRepositoryImpl<Carrier, String> implements Carriers {

	@PersistenceContext(unitName = "ComptaTransportPU")
	private EntityManager em;

	@Override
	protected EntityManager getEntityManager() {
		return em;
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
