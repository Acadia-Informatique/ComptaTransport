package com.acadiainfo.comptatransport.ws;

import java.util.Optional;
import java.util.Set;
import java.util.logging.Logger;
import java.util.stream.Stream;

import com.acadiainfo.comptatransport.domain.Carrier;
import com.acadiainfo.comptatransport.domain.Carriers;
import com.acadiainfo.util.WSUtils;
import static com.acadiainfo.util.WSUtils.responseWithErrorMsg;

import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.StreamingOutput;

@Stateless
@Path("/carriers")
public class CarrierWS {
	private Logger logger = Logger.getLogger(getClass().getName());

	@Inject
	private Carriers carriersRepo;

	@GET
	@Path("/{name}")
	@Produces(MediaType.APPLICATION_JSON)
	public Response getOne(@PathParam("name") String name) {
		Optional<Carrier> optional = carriersRepo.findById(name);
		if (optional.isEmpty()) {
			return responseWithErrorMsg(Response.Status.NOT_FOUND, "Carrier not found with \"name\"=" + name).build();
		} else {
			return Response.ok(optional.get()).build();
		}
	}

	@GET
	@Produces(value = MediaType.APPLICATION_JSON)
	public Response getAll(@QueryParam("tag") Set<String> tags) {
		Stream<Carrier> carriers = carriersRepo.findAll();

		if (tags != null && !tags.isEmpty()) {
			logger.info("tags detected : " + tags);
			carriers = carriers.filter(c -> c.getTags().containsAll(tags));
		}

		StreamingOutput stream = WSUtils.entityJsonStreamingOutput(carriers);
		return Response.ok(stream).build();
	}

	@POST
	@Consumes(value = MediaType.APPLICATION_JSON)
	public Response add(Carrier carrier) {
		try {
			carrier = carriersRepo.insert(carrier);
			return Response.created(java.net.URI.create("/" + carrier.getName())).build();
		} catch (jakarta.data.exceptions.EntityExistsException exc) {
			return responseWithErrorMsg(Response.Status.CONFLICT, "Carrier already exists with the same name").build();
		}
	}

	@PUT
	@Path("/{name}")
	@Consumes(value = MediaType.APPLICATION_JSON)
	public Response update(@PathParam("name") String name, Carrier carrier) {
		try {
			// Carrier-specific : key is "name", so it is also provided in JSON payload
			if ("".equals(name) || !name.equals(carrier.getName())) {
				return responseWithErrorMsg(Response.Status.BAD_REQUEST,
						"Missing or inconsistent name in URI and JSON payload (name cannot be changed)").build();
			}
			carrier = carriersRepo.update(carrier);
			return Response.noContent().entity(carrier).build();
		} catch (jakarta.data.exceptions.OptimisticLockingFailureException exc) {
			return Response.status(Response.Status.CONFLICT).entity(exc.getMessage()).build();
		}
	}

//	@PUT
//	public Set<Fruit> add(Fruit fruit) {
//		fruits.add(fruit);
//		return fruits;
//	}

//

	@DELETE
	@Path("/{name}")
	@Produces(MediaType.APPLICATION_JSON)
	public Response delete(@PathParam("name") String name) {
		Optional<Carrier> oCarrier = carriersRepo.findById(name);
		if (oCarrier.isPresent()) {
			carriersRepo.deleteById(name);
			return Response.noContent().entity(oCarrier.get()).build(); // note: deleted returned for info
		} else {
			return responseWithErrorMsg(Response.Status.NOT_FOUND, "Carrier not found with \"name\"=" + name).build();
		}
	}

}
