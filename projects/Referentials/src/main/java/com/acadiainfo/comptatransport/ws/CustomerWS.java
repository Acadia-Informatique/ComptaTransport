package com.acadiainfo.comptatransport.ws;

import java.util.Set;
import java.util.logging.Logger;
import java.util.stream.Stream;

import com.acadiainfo.comptatransport.data.CarriersRepository;
import com.acadiainfo.comptatransport.data.CustomersRepository;
import com.acadiainfo.comptatransport.domain.Carrier;
import com.acadiainfo.comptatransport.domain.Customer;
import com.acadiainfo.util.WSUtils;

import jakarta.ejb.Stateless;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.Response.Status;
import jakarta.ws.rs.core.StreamingOutput;
import jakarta.ws.rs.core.UriBuilder;

@Stateless
@Path("/customers")
public class CustomerWS {
	private Logger logger = Logger.getLogger(getClass().getName());

	@Context
	private HttpServletRequest servReq;

	@PersistenceContext(unitName = "ComptaTransportPU")
	private EntityManager em;


	@GET
	@Path("/{id}")
	@Produces(MediaType.APPLICATION_JSON)
	public Response getOne_WS(@PathParam("id") Long id) {
		try {
			Customer customer = this.getOne(id);
			return Response.ok(customer).build();
		} catch (jakarta.persistence.PersistenceException exc) {
			return ApplicationConfig.response(exc, servReq, Customer.class);
		}
	}

	/**
	 * Get customer by id.
	 * @param id
	 * @return Customer is exists
	 * @throws jakarta.persistence.EntityNotFoundException if not
	 */
	public Customer getOne(Long id) {
		Customer customer = CustomersRepository.getInstance(em).findById(id);
		if (customer != null) {
			return customer;
		} else {
			throw new jakarta.persistence.EntityNotFoundException("(id=" + id + ")");
		}
	}

	@GET
	@Produces(value = MediaType.APPLICATION_JSON)
	public StreamingOutput getAll_WS(@QueryParam("tag") Set<String> tags) {
		Stream<Customer> customers = getAll(tags);
		return WSUtils.entityJsonStreamingOutput(customers);
	}

	public Stream<Customer> getAll(Set<String> tags) {
		Stream<Customer> customers = CustomersRepository.getInstance(em).findAll();

		if (tags != null && !tags.isEmpty()) {
			logger.finer("tags detected : " + tags);
			customers = customers.filter(c -> c.getTags().containsAll(tags));
		}
		return customers;
	}

	@POST
	@Consumes(value = MediaType.APPLICATION_JSON)
	public Response add_WS(Customer customer) {
		try {
			customer = this.add(customer);
			java.net.URI uri = UriBuilder.fromUri("./customers").path(String.valueOf(customer.getId())).build();
			return Response.created(uri).build();
		} catch (IllegalArgumentException exc) {
			return WSUtils.response(Status.BAD_REQUEST, servReq, exc.getMessage());
		} catch (jakarta.persistence.PersistenceException exc) {
			return ApplicationConfig.response(exc, servReq, Customer.class);
		}
	}

	public Customer add(Customer customer) {
		CustomersRepository customersRepo = CustomersRepository.getInstance(em);

		if (customer == null) {
			throw new IllegalArgumentException("Le corps du message n'a pas pu interprété comme un Client");
		}
		if (customer.getErpReference() == null || customer.getErpReference().equals("")) {
			throw new IllegalArgumentException("La référence ERP du Client ne peut pas être vide.");
		}
		if (customer.getLabel() == null || customer.getLabel().equals("")) {
			throw new IllegalArgumentException("Le libellé du Client ne peut pas être vide.");
		}

		// Unusual : id is not supposed to be provided
		if (customer.getId() != null) {
			if (customersRepo.find(customer) != null) {
				throw new jakarta.persistence.EntityExistsException("Un Client possède déjà le même identifiant."
						+ " Il est recommandé de ne pas l'inclure dans le corps du message.");
			}
		}

		if (customersRepo.findByErpReference(customer.getErpReference()) != null) {
			throw new jakarta.persistence.EntityExistsException("Un autre Client possède déjà la même référence ERP.");
		}

		return customersRepo.insert(customer);
	}

	@PUT
	@Path("/{id}")
	@Consumes(value = MediaType.APPLICATION_JSON)
	public Response update_WS(@PathParam("id") Long id, Customer customer_payload) {
		CustomersRepository customersRepo = CustomersRepository.getInstance(em);

		// payload check
		if (customer_payload.getId() != null && !customer_payload.getId().equals(id)) {
			return WSUtils.response(Status.BAD_REQUEST, servReq,
			  "Identifiant incohérent dans l'URI et le corps du message."
			 +" Il est possible (et recommandé) de ne pas l'inclure dans le corps du message.");
		}
		if (customer_payload.getErpReference() == null || customer_payload.getErpReference().equals("")) {
			return WSUtils.response(Status.BAD_REQUEST, servReq, "La référence ERP du Client ne peut pas être vide.");
		}
		if (customer_payload.getLabel() == null || customer_payload.getLabel().equals("")) {
			return WSUtils.response(Status.BAD_REQUEST, servReq, "Le libellé du Client ne peut pas être vide.");
		}

		// constraint check
		Customer otherCustomer = customersRepo.findByErpReference(customer_payload.getErpReference());
		if (otherCustomer != null && !otherCustomer.getId().equals(id)) {
			return WSUtils.response(Status.CONFLICT, servReq, "Un autre Client possède déjà la même référence ERP.");
		}

		try {
			customer_payload.setId(id);
			Customer customer = customersRepo.update(customer_payload, false);
			return Response.noContent().entity(customer).build(); // no_content with a content ;-)
		} catch (jakarta.persistence.OptimisticLockException exc) {
			return WSUtils.response(Status.CONFLICT, servReq,
					"Client peut-être modifié depuis (\"_v_lock\" non-concordant).");
		} catch (jakarta.persistence.EntityNotFoundException exc) {
			return WSUtils.response(Status.NOT_FOUND, servReq, "Client peut-être supprimé depuis.");
		}
	}

	@DELETE
	@Path("/{id}")
	public Response delete_WS(@PathParam("id") Long id) {
		try {
			CustomersRepository.getInstance(em).deleteById(id);
			return Response.noContent().build();
		} catch (jakarta.persistence.PersistenceException exc) {
			return ApplicationConfig.response(exc, servReq, Customer.class);
		}
	}
//
//	/* ================================================================== */
//	/* WS on Versions of a grid */
//
//	/**
//	 * (utility for versions)
//	 * @param id
//	 * @return parent PriceGrid, throws {@link NotFoundException} if none found
//	 */
//	private PriceGrid ensureParentPricePrid(Long id) {
//		PriceGrid priceGrid = this.getOne(id);
//		if (priceGrid == null) {
//			throw new NotFoundException("Aucune Grille Tarifaire avec cet id");
//		}
//		return priceGrid;
//	}
//
//	/**
//	 *  (utility for versions)
//	 * @param v_id
//	 * @param priceGrid
//	 * @return PriceGridVersion, throws {@link NotFoundException} if none consistent found
//	 */
//	private PriceGridVersion ensureConsistentGridVersion(Long v_id, PriceGrid priceGrid) {
//		PriceGridVersionsRepository priceGridVersionsRepo = PriceGridVersionsRepository.getInstance(em);
//		PriceGridVersion priceGridVersion = priceGridVersionsRepo.findById(v_id);
//
//		if (priceGridVersion == null) {
//			throw new NotFoundException("Version de Grille Tarifaire peut-être supprimée depuis.");
//		}
//		if (!priceGrid.getId().equals(priceGridVersion.getPriceGrid().getId())) {
//			throw new NotFoundException("Version de Grille Tarifaire incohérente avec la Grille.");
//		}
//		return priceGridVersion;
//	}
//
//	/**
//	 * Get all versions of a PriceGrid
//	 * @param pgid - Parent PriceGrid id
//	 * @return
//	 */
//	@GET
//	@Path("/{id}/versions")
//	@Produces(MediaType.APPLICATION_JSON)
//	public StreamingOutput versions_getAll_WS(@PathParam("id") Long id) {
//		PriceGrid priceGrid = ensureParentPricePrid(id);
//
//		PriceGridVersionsRepository priceGridVersionsRepo = PriceGridVersionsRepository.getInstance(em);
//		Stream<PriceGridVersion> versions = priceGridVersionsRepo.findAllOfOnePriceGrid(id);
//		return WSUtils.entityJsonStreamingOutput(versions);
//	}
//
//
//	@POST
//	@Path("/{id}/versions")
//	@Consumes(value = MediaType.APPLICATION_JSON)
//	public Response versions_add_WS(@PathParam("id") Long id, PriceGridVersion priceGridVersion) {
//		PriceGrid priceGrid = ensureParentPricePrid(id);
//
//		try {
//			if (priceGridVersion == null) {
//				throw new IllegalArgumentException("Le corps du message n'a pas pu interprété comme une Version de Grille Tarifaire (PriceGridVersion)");
//			}
//			if (priceGridVersion.getVersion() == null || priceGridVersion.getVersion().equals("")) {
//				throw new IllegalArgumentException("La Version de Grille Tarifaire doit être renseignée (PriceGridVersion.version)");
//			}
//			if (priceGridVersion.getId() != null) {
//				throw new IllegalArgumentException("L'identifiant de Version de Grille Tarifaire ne doit pas être incluse dans le corps du message.");
//			}
//			if (priceGridVersion.getPriceGrid() != null) {
//				throw new IllegalArgumentException("Le corps de la requête ne doit pas comporter de Grille (\"priceGrid\").");
//			}
//
//			PriceGridVersionsRepository priceGridVersionsRepo = PriceGridVersionsRepository.getInstance(em);
//			PriceGridVersion duplicatePriceGridVersion = priceGridVersionsRepo
//			  .findVersionOfOnePriceGrid(id, priceGridVersion.getVersion());
//			if (duplicatePriceGridVersion != null) {
//				return WSUtils.response(Status.CONFLICT, servReq,
//				  "La Version doit rester unique pour chaque Grille Tarifaire.");
//			}
//
//			priceGridVersion.setPriceGrid(priceGrid);
//			em.persist(priceGridVersion);
//			em.flush();
//
//			java.net.URI uri = UriBuilder.fromUri("./price-grids").path(String.valueOf(priceGrid.getId()))
//					.path("versions").path(String.valueOf(priceGridVersion.getId())).build();
//			return Response.created(uri).build();
//		} catch (IllegalArgumentException exc) {
//			return WSUtils.response(Status.BAD_REQUEST, servReq, exc.getMessage());
//		}
//	}
//
//	@GET
//	@Path("/{id}/versions/{v_id}")
//	@Produces(MediaType.APPLICATION_JSON)
//	public Response versions_getOne_WS(@PathParam("id") Long id, @PathParam("v_id") Long v_id) {
//		PriceGrid priceGrid = ensureParentPricePrid(id);
//		PriceGridVersion priceGridVersion = ensureConsistentGridVersion(v_id, priceGrid);
//
//		return Response.ok(priceGridVersion).build();
//	}
//
//	@DELETE
//	@Path("/{id}/versions/{v_id}")
//	public Response versions_delete_WS(@PathParam("id") Long id, @PathParam("v_id") Long v_id) {
//		PriceGrid priceGrid = ensureParentPricePrid(id);
//		PriceGridVersion priceGridVersion = ensureConsistentGridVersion(v_id, priceGrid);
//		
//		PriceGridVersionsRepository priceGridVersionsRepo = PriceGridVersionsRepository.getInstance(em);
//		priceGridVersionsRepo.delete(priceGridVersion);
//
//		return Response.noContent().build();
//	}
//
//	@PUT
//	@Path("/{id}/versions/{v_id}")
//	@Consumes(value = MediaType.APPLICATION_JSON)
//	public Response versions_update_WS(@PathParam("id") Long id, @PathParam("v_id") Long v_id, PriceGridVersion priceGridVersion_payload) {
//		PriceGrid priceGrid = ensureParentPricePrid(id);
//		PriceGridVersion priceGridVersion = ensureConsistentGridVersion(v_id, priceGrid);
//		
//		// payload check		
//		if (priceGridVersion_payload.getId() != null && !priceGridVersion_payload.getId().equals(v_id)) {
//			return WSUtils.response(Status.BAD_REQUEST, servReq,
//			  "Identifiant incohérent dans l'URI et le corps du message."
//			 +" Il est possible (et recommandé) de ne pas l'inclure dans le corps du message.");
//		}
//		if (priceGridVersion_payload.getPriceGrid() != null) {
//			return WSUtils.response(Status.BAD_REQUEST, servReq,
//			  "Le corps de la requête ne doit pas comporter de Grille (\"priceGrid\"). Il est impossible de réattacher une Version à une autre Grille.");
//		}
//
//		// constraint check
//		PriceGridVersionsRepository priceGridVersionsRepo = PriceGridVersionsRepository.getInstance(em);
//		PriceGridVersion duplicatePriceGridVersion = priceGridVersionsRepo
//		  .findVersionOfOnePriceGrid(id, priceGridVersion.getVersion());
//		if (!duplicatePriceGridVersion.getId().equals(v_id)) {
//			return WSUtils.response(Status.CONFLICT, servReq,
//			  "La Version doit rester unique pour chaque Grille Tarifaire.");
//		}
//
//		try {
//			priceGridVersion_payload.setId(v_id);
//			priceGridVersion_payload.setPriceGrid(priceGrid);
//
//			priceGridVersionsRepo.update(priceGridVersion_payload, false);
//			return Response.noContent().build();
//		} catch (jakarta.persistence.OptimisticLockException exc) {
//			return WSUtils.response(Status.CONFLICT, servReq,
//			  "Grille Tarifaire peut-être modifiée depuis (\"_v_lock\" non-concordant).");			
//		} catch (jakarta.persistence.EntityNotFoundException exc) {
//			return WSUtils.response(Status.NOT_FOUND, servReq,
//			  "Grille Tarifaire peut-être supprimée depuis.");
//		}
//	}
//
//	@GET
//	@Path("/{id}/versions/{v_id}/jsonContent")
//	@Produces(value = MediaType.APPLICATION_JSON)
//	public String versions_getJsonContent(@PathParam("id") Long id, @PathParam("v_id") Long v_id) {
//		PriceGrid priceGrid = ensureParentPricePrid(id);
//		PriceGridVersion priceGridVersion = ensureConsistentGridVersion(v_id, priceGrid);
//		return priceGridVersion.getJsonContent();
//	}
//
//	@PUT
//	@Path("/{id}/versions/{v_id}/jsonContent")
//	@Consumes(value = MediaType.APPLICATION_JSON)
//	@jakarta.ejb.TransactionAttribute(jakarta.ejb.TransactionAttributeType.REQUIRES_NEW)
//	public Response versions_setJsonContent(@PathParam("id") Long id, @PathParam("v_id") Long v_id,
//			@QueryParam("_v_lock") Long _v_lock, String jsonContent) {
//		//BTW, we won't check the payload for JSON conformance
//		PriceGrid priceGrid = ensureParentPricePrid(id);
//		PriceGridVersion priceGridVersion = ensureConsistentGridVersion(v_id, priceGrid);
//
//		if (_v_lock == null) {
//			return WSUtils.response(Status.BAD_REQUEST, servReq,
//			  "Un numéro de version doit être passé en paramètre de requête (_v_lock)");
//		} else if (!_v_lock.equals(priceGridVersion.get_v_lock())) {
//			return WSUtils.response(Status.CONFLICT, servReq,
//			  "Version de Grille Tarifaire peut-être modifiée depuis (\"_v_lock\" non-concordant).");
//		}
//		
//		try {
//			priceGridVersion.setJsonContent(jsonContent);
//			em.flush(); // to make it fail faster, if needed
//			return Response.noContent().build();
//		} catch (jakarta.persistence.PersistenceException exc) {
//			return ApplicationConfig.response(exc, servReq, PriceGridVersion.class);
//		}
//	}
//
//	@POST
//	@Path("/{id}/versions/{v_id}/copy")
//	@Produces(value = MediaType.APPLICATION_JSON)
//	public Response versions_copyOne(@PathParam("id") Long id, @PathParam("v_id") Long v_id, @QueryParam("newVersion") String newVersion) {
//		PriceGrid priceGrid = ensureParentPricePrid(id);
//		PriceGridVersion priceGridVersion = ensureConsistentGridVersion(v_id, priceGrid);
//
//		
//		String newDescription = "COPIE DE " + priceGridVersion.getVersion();
//		if (priceGridVersion.getDescription() != null && !priceGridVersion.getDescription().equals("")) {
//			newDescription += " : \n" + priceGridVersion.getDescription();
//		}
//		if (newDescription.length() > 256) {
//			newDescription = newDescription.substring(0, 250) + "[...]";
//		}
//
//		PriceGridVersion priceGridVersionCopy = new PriceGridVersion();
//		// priceGridVersionCopy.setId();
//		priceGridVersionCopy.setPriceGrid(priceGrid);
//		priceGridVersionCopy.setVersion(newVersion);
//		priceGridVersionCopy.setPublishedDate(null);
//		priceGridVersionCopy.setDescription(newDescription);
//		priceGridVersionCopy.setJsonContent(priceGridVersion.getJsonContent()); // the most important
//		// priceGridVersionCopy.set_v_lock();
//		// priceGridVersionCopy.getAuditingInfo()id.setUser(...; TODO user management
//
//		try {
//			PriceGridVersionsRepository.getInstance(em).insert(priceGridVersionCopy);
//			em.flush();
//
//			java.net.URI uri = UriBuilder.fromUri("./price-grids").path(String.valueOf(priceGrid.getId()))
//					.path("versions").path(String.valueOf(priceGridVersionCopy.getId())).build();
//			return Response.created(uri).build();
//		} catch (jakarta.persistence.PersistenceException exc) {
//			return ApplicationConfig.response(exc, servReq, PriceGridVersion.class);
//		}
//	}

}
