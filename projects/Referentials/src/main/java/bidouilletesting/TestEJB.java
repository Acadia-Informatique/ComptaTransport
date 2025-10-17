package bidouilletesting;

import jakarta.ejb.Stateless;
import jakarta.json.bind.JsonbBuilder;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Stateless
@Path("/testo")
public class TestEJB {
	
	@PersistenceContext(unitName = "ComptaTransportPU")
	private EntityManager em;
	
//	@jakarta.inject.Inject
//	private com.acadiainfo.comptatransport.domain.Carriers carriers;

	@GET
	@Produces(value = MediaType.APPLICATION_JSON)
	public Toto truc() {
		
		Toto t = new Toto();
		t.setName("Georges");
		t.addAdjective("big");
		t.addAdjective("bright");
		t.addAdjective("yellow");
		t.addAdjective("big");
		t.addAdjective("bright");
		t.addAdjective("sun");
		
		em.persist(t);
		em.flush();
		
		java.util.logging.Logger.getLogger(this.getClass().getName()).info(t.sayHello());

		Toto titi = em.find(Toto.class, 33L);
		java.util.logging.Logger.getLogger(this.getClass().getName()).info(titi.sayHello());

		return t;
	}

	@GET
	@Path(value = "/bidule")
	@Produces(value = MediaType.APPLICATION_JSON)
	public java.util.List<com.acadiainfo.comptatransport.domain.Carrier> bidule(String patternStr) {
		return new java.util.ArrayList<com.acadiainfo.comptatransport.domain.Carrier>();// carriers.findByNameLike(patternStr);
	}

	public static class Commande {
		public String productCode;
		public int quantity;

		@Override
		public String toString() {
			return "une commande de " + quantity + " #" + productCode;
		}
	}

	@POST
	@Path(value = "json")
	@Consumes(value = MediaType.APPLICATION_JSON)	
	public String jsonPayloadStrict(Commande c) {
		return "joie : " + c;
	}

	@POST
	@Path(value = "json-relax")
	@Consumes(value = MediaType.TEXT_PLAIN)
	public String jsonPayloadPermissive(String c) {
		JsonbBuilder j = null;
		Commande parsedC = null;
		return "paix : " + parsedC;
	}
}
