package com.acadiainfo.jaxrs;

import com.acadiainfo.comptatransport.Toto;

import jakarta.ejb.Stateless;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;

@Stateless
@Path("/testo")
public class TestEJB {
	
	@PersistenceContext(unitName = "ComptaTransportPU")
	private EntityManager emo;
	
	@GET
	public String truc() {
		
		Toto t = new Toto();
		t.setName("Georges");
		
		emo.persist(t);
		emo.flush();
		
		return "hello world, " + t.sayHello();
	}

}
