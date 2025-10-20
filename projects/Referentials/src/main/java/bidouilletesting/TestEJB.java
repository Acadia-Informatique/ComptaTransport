package bidouilletesting;

import jakarta.ejb.Stateless;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;

@Stateless
@Path("/testo")
public class TestEJB {

	@PersistenceContext(unitName = "ComptaTransportPU")
	private EntityManager em;



	// --------------------------------------------------------
	//

	// @Path("/{name: [a-zA-Z][a-zA-Z_0-9]*}")

	public static class Commande {
		public String productCode;
		public int quantity;

		@Override
		public String toString() {
			return "une commande de " + quantity + " #" + productCode;
		}
	}

	@GET
	@Path("/qs")
	public String testQueryString(@QueryParam("name") String name, @Context UriInfo uriInfo) {
		// TODO use uriInfo.getPathParameters() and list of @QueryParam annotated args

		return "My name is " + name;
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
	public Response jsonPayloadPermissive(String s) {
		jakarta.json.bind.Jsonb jsonb = jakarta.json.bind.JsonbBuilder.create();
		try {
			Commande parsedC = jsonb.fromJson(s, Commande.class);
			return Response.ok("paix : " + parsedC).build();
		} catch (jakarta.json.bind.JsonbException exc) {
			StringBuilder errorMsg = new StringBuilder();
			Throwable t = exc;
			do {
				errorMsg.append(t.getClass());
				errorMsg.append(" : ");
				errorMsg.append(t.getMessage());

				t = t.getCause();
				if (t != null) {
					errorMsg.append(" <- ");
				}
			} while (t != null);
			return Response.status(400).entity("terrible ! On a eu : " + errorMsg.toString()).build();
		}
	}
}
