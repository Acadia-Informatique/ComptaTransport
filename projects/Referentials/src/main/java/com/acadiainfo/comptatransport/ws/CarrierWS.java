package com.acadiainfo.comptatransport.ws;

import java.util.Set;
import java.util.logging.Logger;
import java.util.stream.Stream;

import com.acadiainfo.comptatransport.data.CarriersRepository;
import com.acadiainfo.comptatransport.domain.Carrier;
import com.acadiainfo.util.WSUtils;

import jakarta.ejb.Stateless;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.servlet.http.HttpServletRequest;

import jakarta.ws.rs.*;
import jakarta.ws.rs.core.*;
import jakarta.ws.rs.core.Response.Status;

@Stateless
@Path("/carriers")
public class CarrierWS {
	private Logger logger = Logger.getLogger(getClass().getName());

	@Context
	private HttpServletRequest servReq;

	@PersistenceContext(unitName = "ComptaTransportPU")
	private EntityManager em;


	@GET
	@Path("/{name}")
	@Produces(MediaType.APPLICATION_JSON)
	public Response getOne_WS(@PathParam("name") String name) {
		Carrier carrier = this.getOne(name);
		if (carrier != null) {
			return Response.ok().entity(carrier).build();
		} else {
			return WSUtils.response(Status.NOT_FOUND, servReq,
			  "Transporteur non-trouvé avec ce nom (Carrier.name).");
		}
	}

	public Carrier getOne(String name) {
		return CarriersRepository.getInstance(em).findById(name);
	}

	@GET
	@Produces(value = MediaType.APPLICATION_JSON)
	public StreamingOutput getAll_WS(@QueryParam("tag") Set<String> tags) {
		Stream<Carrier> carriers = getAll(tags);
		return WSUtils.entityJsonStreamingOutput(carriers);
	}

	public Stream<Carrier> getAll(@QueryParam("tag") Set<String> tags) {
		Stream<Carrier> carriers = CarriersRepository.getInstance(em).findAll();

		if (tags != null && !tags.isEmpty()) {
			logger.finer("tags detected : " + tags);
			carriers = carriers.filter(c -> c.getTags().containsAll(tags));
		}
		return carriers;
	}

	@POST
	@Consumes(value = MediaType.APPLICATION_JSON)
	public Response add_WS(Carrier carrier) {
		if (carrier == null) {
			return WSUtils.response(Status.BAD_REQUEST, servReq,
			  "Le corps du message n'a pas pu interprété comme un Transporteur (Carrier)");
		}
		if ("".equals(carrier.getName())) {
			return WSUtils.response(Status.BAD_REQUEST, servReq,
			  "Le nom du Transporteur ne peut pas être vide (Carrier.name)");
		}

		try {
			carrier = this.add(carrier);
			return Response.created(UriBuilder.fromUri("./carriers").path(carrier.getName()).build()).build();
		} catch (jakarta.persistence.EntityExistsException exc) {
			return WSUtils.response(Status.CONFLICT, servReq,
					"Le nom du Transporteur (Carrier.name) doit être unique.");
		}
	}

	public Carrier add(Carrier carrier) {
		CarriersRepository carriersRepo = CarriersRepository.getInstance(em);
		return carriersRepo.insert(carrier);
	}

	@PUT
	@Path("/{name}")
	@Consumes(value = MediaType.APPLICATION_JSON)
	public Response update_WS(@PathParam("name") String name, Carrier carrier) {
		// Carrier-specific : key is "name", so it is also provided in JSON payload
		if ("".equals(name) || !name.equals(carrier.getName())) {
			return WSUtils.response(Status.BAD_REQUEST, servReq,
			  "Nom de transporteur (Carrier.name) manquant ou incohérent dans l'URI et le corps du message."
			 +" Rappel : le nom ne peut pas être modifié après création.");
		}
		try {
			carrier = CarriersRepository.getInstance(em).update(carrier, false);
			return Response.noContent().entity(carrier).build();
		} catch (jakarta.persistence.OptimisticLockException exc) {
			return WSUtils.response(Status.CONFLICT, servReq,
			  "Transporteur peut-être modifié depuis (\"_v_lock\" non-concordant).");			
		} catch (jakarta.persistence.EntityNotFoundException exc) {
			return WSUtils.response(Status.NOT_FOUND, servReq,
			  "Transporteur peut-être supprimé depuis.");
		}
	}


	@DELETE
	@Path("/{name}")
	public Response delete_WS(@PathParam("name") String name) {
		try {
			CarriersRepository.getInstance(em).deleteById(name);
			return Response.noContent().build();
		} catch (jakarta.persistence.EntityNotFoundException exc) {
			return WSUtils.response(Status.NOT_FOUND, servReq,
			  "Transporteur peut-être supprimé depuis.");
		}
	}

}
