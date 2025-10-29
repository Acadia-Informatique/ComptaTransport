package com.acadiainfo.comptatransport.ws;

import java.util.Set;
import java.util.logging.Logger;
import java.util.stream.Stream;

import com.acadiainfo.comptatransport.domain.Carrier;
import com.acadiainfo.comptatransport.domain.CarriersRepository;
import com.acadiainfo.util.WSUtils;

import jakarta.ejb.Stateless;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.*;

@Stateless
@Path("/carriers")
public class CarrierWS {
	private Logger logger = Logger.getLogger(getClass().getName());

	@PersistenceContext(unitName = "ComptaTransportPU")
	private EntityManager em;


	@GET
	@Path("/{name}")
	@Produces(MediaType.APPLICATION_JSON)
	public Carrier getOne(@PathParam("name") String name) {

		Carrier carrier = CarriersRepository.getInstance(em).findById(name);
		if (carrier == null) {
			throw new jakarta.ws.rs.NotFoundException("Carrier not found with \"name\"=" + name);
		}
		return carrier;
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
			logger.info("tags detected : " + tags);
			carriers = carriers.filter(c -> c.getTags().containsAll(tags));
		}

		return carriers;
	}

	@POST
	@Consumes(value = MediaType.APPLICATION_JSON)
	public Response add(Carrier carrier) {
		try {
			carrier = CarriersRepository.getInstance(em).insert(carrier);
			return Response.created(UriBuilder.fromUri("./carriers").path(carrier.getName()).build()).build();
		} catch (jakarta.persistence.EntityExistsException exc) {
			throw new WebApplicationException("Carrier already exists with the same name", Response.Status.CONFLICT);
		} catch (com.acadiainfo.util.DataIntegrityViolationException exc) {
			throw new WebApplicationException(exc.getMessage(), Response.Status.BAD_REQUEST);
		}
	}

	@PUT
	@Path("/{name}")
	@Consumes(value = MediaType.APPLICATION_JSON)
	public Response update(@PathParam("name") String name, Carrier carrier) {
		try {
			// Carrier-specific : key is "name", so it is also provided in JSON payload
			if ("".equals(name) || !name.equals(carrier.getName())) {
				throw new BadRequestException("Missing or inconsistent name in URI and JSON payload"
						+ " (Carrier's name cannot be changed)");
			}

			carrier = CarriersRepository.getInstance(em).update(carrier, false);
			return Response.noContent().entity(carrier).build();
		} catch (jakarta.persistence.OptimisticLockException exc) {
			throw new WebApplicationException("Update error: " + exc.getMessage(), Response.Status.CONFLICT);
		} catch (com.acadiainfo.util.DataIntegrityViolationException exc) {
			throw new WebApplicationException(exc.getMessage(), Response.Status.BAD_REQUEST);
		}
	}


	@DELETE
	@Path("/{name}")
	@Produces(MediaType.APPLICATION_JSON)
	public Response delete(@PathParam("name") String name) {
		try {
			CarriersRepository.getInstance(em).deleteById(name);
			return Response.noContent().build();
		} catch (jakarta.persistence.EntityNotFoundException exc) {
			throw new NotFoundException("Carrier not found with \"name\"=" + name);
		} catch (com.acadiainfo.util.DataIntegrityViolationException exc) {
			throw new WebApplicationException(exc.getMessage(), Response.Status.BAD_REQUEST);
		}
	}

}
