package com.acadiainfo.comptatransport.ws;

import java.util.Set;
import java.util.logging.Logger;
import java.util.stream.Stream;

import com.acadiainfo.comptatransport.data.PriceGridVersionsRepository;
import com.acadiainfo.comptatransport.data.PriceGridsRepository;
import com.acadiainfo.comptatransport.domain.PriceGrid;
import com.acadiainfo.comptatransport.domain.PriceGridVersion;
import com.acadiainfo.util.WSUtils;

import jakarta.ejb.Stateless;
import jakarta.persistence.EntityManager;
import jakarta.persistence.NamedQuery;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Query;
import jakarta.servlet.http.HttpServletRequest;

import jakarta.ws.rs.*;
import jakarta.ws.rs.core.*;
import jakarta.ws.rs.core.Response.Status;

@Stateless
@Path("/price-grids")
public class PriceGridWS {
	private Logger logger = Logger.getLogger(getClass().getName());

	@Context
	private HttpServletRequest servReq;

	@PersistenceContext(unitName = "ComptaTransportPU")
	private EntityManager em;


	@GET
	@Path("/{id}")
	@Produces(MediaType.APPLICATION_JSON)
	public Response getOne_WS(@PathParam("id") Long id) {
		PriceGrid priceGrid = this.getOne(id);
		if (priceGrid != null) {
			return Response.ok().entity(priceGrid).build();
		} else {
			return WSUtils.response(Status.NOT_FOUND, servReq,
			  "Grille Tarifaire non-trouvée avec cet identifiant.");
		}
	}

	public PriceGrid getOne(Long id) {
		return PriceGridsRepository.getInstance(em).findById(id);
	}

	@GET
	@Produces(value = MediaType.APPLICATION_JSON)
	public StreamingOutput getAll_WS() {
		Stream<PriceGrid> priceGrids = getAll();
		return WSUtils.entityJsonStreamingOutput(priceGrids);
	}

	public Stream<PriceGrid> getAll() {
		Stream<PriceGrid> priceGrids = PriceGridsRepository.getInstance(em).findAll();
		return priceGrids;
	}

	@POST
	@Consumes(value = MediaType.APPLICATION_JSON)
	public Response add_WS(PriceGrid priceGrid) {
		try {
			priceGrid = this.add(priceGrid);
			java.net.URI uri = UriBuilder.fromUri("./price-grids").path(String.valueOf(priceGrid.getId())).build();
			return Response.created(uri).build();
		} catch (IllegalArgumentException exc) {
			return WSUtils.response(Status.BAD_REQUEST, servReq, exc.getMessage());
		} catch (jakarta.persistence.EntityExistsException exc) {
			return WSUtils.response(Status.CONFLICT, servReq, exc.getMessage());
		}
	}

	public PriceGrid add(PriceGrid priceGrid) {		
		PriceGridsRepository priceGridsRepo = PriceGridsRepository.getInstance(em);
		
		if (priceGrid == null) {
			throw new IllegalArgumentException("Le corps du message n'a pas pu interprété comme une Grille Tarifaire (PriceGrid)");
		}
		if ("".equals(priceGrid.getName())) {
			throw new IllegalArgumentException("Le nom de la Grille Tarifaire ne peut pas être vide (PriceGrid.name)");
		}
				
		// Unusual : id is not supposed to be provided
		if (priceGrid.getId() != null) {
			if (priceGridsRepo.find(priceGrid) != null){
				throw new jakarta.persistence.EntityExistsException("Une Grille Tarifaire possède déjà le même identifiant."
				  +" Il est recommandé de ne pas l'inclure dans le corps du message.");
			}
		}
		
		if (priceGridsRepo.findByName(priceGrid.getName()) != null) {
			throw new jakarta.persistence.EntityExistsException("Une autre Grille Tarifaire possède déjà le même nom.");
		}
		
		return priceGridsRepo.insert(priceGrid);
	}

	@PUT
	@Path("/{id}")
	@Consumes(value = MediaType.APPLICATION_JSON)
	public Response update_WS(@PathParam("id") Long id, PriceGrid priceGrid_payload) {
		PriceGridsRepository priceGridsRepo = PriceGridsRepository.getInstance(em);

		// payload check
		if (priceGrid_payload.getId() != null && !priceGrid_payload.getId().equals(id)) {
			return WSUtils.response(Status.BAD_REQUEST, servReq,
			  "Identifiant incohérent dans l'URI et le corps du message."
			 +" Il est possible (et recommandé) de ne pas l'inclure dans le corps du message.");
		}

		// constraint check
		PriceGrid otherPriceGrid = priceGridsRepo.findByName(priceGrid_payload.getName());
		if (otherPriceGrid != null && !otherPriceGrid.getId().equals(id)) {
			return WSUtils.response(Status.CONFLICT, servReq,
			  "Une autre Grille Tarifaire possède déjà le même nom.");
		}

		try {
			priceGrid_payload.setId(id);
			PriceGrid priceGrid = priceGridsRepo.update(priceGrid_payload, false);
			return Response.noContent().entity(priceGrid).build(); // no_content with a content ;-)
		} catch (jakarta.persistence.OptimisticLockException exc) {
			return WSUtils.response(Status.CONFLICT, servReq,
			  "Grille Tarifaire peut-être modifiée depuis (\"_v_lock\" non-concordant).");			
		} catch (jakarta.persistence.EntityNotFoundException exc) {
			return WSUtils.response(Status.NOT_FOUND, servReq,
			  "Grille Tarifaire peut-être supprimée depuis.");
		}
	}


	@DELETE
	@Path("/{id}")
	public Response delete_WS(@PathParam("id") Long id) {
		try {
			PriceGridsRepository.getInstance(em).deleteById(id);
			return Response.noContent().build();
		} catch (jakarta.persistence.EntityNotFoundException exc) {
			return WSUtils.response(Status.NOT_FOUND, servReq,
			  "Grille Tarifaire peut-être supprimée depuis.");
		}
	}

	/* ================================================================== */
	/* WS on Versions of a grid */

	/**
	 * (utility for versions)
	 * @param id
	 * @return parent PriceGrid, throws {@link NotFoundException} if none found
	 */
	private PriceGrid ensureParentPricePrid(Long id) {
		PriceGrid priceGrid = this.getOne(id);
		if (priceGrid == null) {
			throw new NotFoundException("Aucune Grille Tarifaire avec cet id");
		}
		return priceGrid;
	}

	/**
	 * Get all versions of a PriceGrid
	 * @param pgid - Parent PriceGrid id
	 * @return
	 */
	@GET
	@Path("/{id}/versions")
	@Produces(MediaType.APPLICATION_JSON)
	public StreamingOutput versions_getAll_WS(@PathParam("id") Long id) {
		PriceGrid priceGrid = ensureParentPricePrid(id);

		PriceGridVersionsRepository priceGridVersionsRepo = PriceGridVersionsRepository.getInstance(em);
		Stream<PriceGridVersion> versions = priceGridVersionsRepo.findAllOfOnePriceGrid(id);
		return WSUtils.entityJsonStreamingOutput(versions);
	}


	@POST
	@Path("/{id}/versions")
	@Consumes(value = MediaType.APPLICATION_JSON)
	public Response versions_add_WS(@PathParam("id") Long id, PriceGridVersion priceGridVersion) {
		PriceGrid priceGrid = ensureParentPricePrid(id);

		try {
			if (priceGridVersion == null) {
				throw new IllegalArgumentException("Le corps du message n'a pas pu interprété comme une Version de Grille Tarifaire (PriceGridVersion)");
			}
			if (priceGridVersion.getVersion() == null || priceGridVersion.getVersion().equals("")) {
				throw new IllegalArgumentException("La Version de Grille Tarifaire doit être renseignée (PriceGridVersion.version)");
			}
			if (priceGridVersion.getId() != null) {
				throw new IllegalArgumentException("L'identifiant de Version de Grille Tarifaire ne doit pas être incluse dans le corps du message.");
			}

			PriceGridVersionsRepository priceGridVersionsRepo = PriceGridVersionsRepository.getInstance(em);
			PriceGridVersion duplicatePriceGridVersion = priceGridVersionsRepo
			  .findVersionOfOnePriceGrid(id, priceGridVersion.getVersion());
			if (duplicatePriceGridVersion != null) {
				return WSUtils.response(Status.CONFLICT, servReq,
				  "La Version doit rester unique pour chaque Grille Tarifaire.");
			}

			priceGridVersion.setPriceGrid(priceGrid);
			em.persist(priceGridVersion);
			em.flush();

			java.net.URI uri = UriBuilder.fromUri("./price-grids").path(String.valueOf(priceGrid.getId()))
					.path("versions").path(String.valueOf(priceGridVersion.getId())).build();
			return Response.created(uri).build();
		} catch (IllegalArgumentException exc) {
			return WSUtils.response(Status.BAD_REQUEST, servReq, exc.getMessage());
		}
	}

	@GET
	@Path("/{id}/versions/{v_id}")
	@Produces(MediaType.APPLICATION_JSON)
	public Response versions_getOne_WS(@PathParam("id") Long id, @PathParam("v_id") Long v_id) {
		PriceGrid priceGrid = ensureParentPricePrid(id);

		PriceGridVersionsRepository priceGridVersionsRepo = PriceGridVersionsRepository.getInstance(em);
		PriceGridVersion priceGridVersion = priceGridVersionsRepo.findById(v_id);
		
		if (priceGridVersion == null) {
			return WSUtils.response(Status.NOT_FOUND, servReq,
			  "Version de Grille Tarifaire non-trouvée avec ces identifiants.");
		}
		if (!priceGrid.getId().equals(priceGridVersion.getPriceGrid().getId())) {
			return WSUtils.response(Status.NOT_FOUND, servReq,
			  "Version de Grille Tarifaire incohérente avec la Grille.");
		}

		return Response.ok().entity(priceGridVersion).build();
	}

	@DELETE
	@Path("/{id}/versions/{v_id}")
	public Response versions_delete_WS(@PathParam("id") Long id, @PathParam("v_id") Long v_id) {
		PriceGrid priceGrid = ensureParentPricePrid(id);

		PriceGridVersionsRepository priceGridVersionsRepo = PriceGridVersionsRepository.getInstance(em);
		PriceGridVersion priceGridVersion = priceGridVersionsRepo.findById(v_id);
		
		if (priceGridVersion == null) {
			return WSUtils.response(Status.NOT_FOUND, servReq,
			  "Version de Grille Tarifaire peut-être supprimée depuis.");
		}
		if (!priceGrid.getId().equals(priceGridVersion.getPriceGrid().getId())) {
			return WSUtils.response(Status.NOT_FOUND, servReq,
			  "Version de Grille Tarifaire incohérente avec la Grille.");
		}
		
		em.remove(priceGridVersion);
		em.flush();
		return Response.noContent().build();
	}

	@PUT
	@Path("/{id}/versions/{v_id}")
	@Consumes(value = MediaType.APPLICATION_JSON)
	public Response versions_update_WS(@PathParam("id") Long id, @PathParam("v_id") Long v_id, PriceGridVersion priceGridVersion_payload) {
		PriceGrid priceGrid = ensureParentPricePrid(id);

		PriceGridVersionsRepository priceGridVersionsRepo = PriceGridVersionsRepository.getInstance(em);
		PriceGridVersion priceGridVersion = priceGridVersionsRepo.findById(v_id);
		
		if (priceGridVersion == null) {
			return WSUtils.response(Status.NOT_FOUND, servReq,
			  "Version de Grille Tarifaire peut-être supprimée depuis.");
		}
		if (!priceGrid.getId().equals(priceGridVersion.getPriceGrid().getId())) {
			return WSUtils.response(Status.NOT_FOUND, servReq,
			  "Version de Grille Tarifaire incohérente avec la Grille.");
		}
		
		// payload check		
		if (priceGridVersion_payload.getId() != null && !priceGridVersion_payload.getId().equals(v_id)) {
			return WSUtils.response(Status.BAD_REQUEST, servReq,
			  "Identifiant incohérent dans l'URI et le corps du message."
			 +" Il est possible (et recommandé) de ne pas l'inclure dans le corps du message.");
		}
		if (priceGridVersion_payload.getPriceGrid() != null) {
			return WSUtils.response(Status.BAD_REQUEST, servReq,
			  "Le corps de la requête ne doit pas comporter de Grille. Il est impossible de la réattacher une Version à une autre Grille.");
		}

		// constraint check
		PriceGridVersion duplicatePriceGridVersion = priceGridVersionsRepo
		  .findVersionOfOnePriceGrid(id, priceGridVersion.getVersion());
		if (!duplicatePriceGridVersion.getId().equals(v_id)) {
			return WSUtils.response(Status.CONFLICT, servReq,
			  "La Version doit rester unique pour chaque Grille Tarifaire.");
		}

		try {

			priceGridVersion.set_v_lock(priceGridVersion_payload.get_v_lock());
			priceGridVersion.setVersion(priceGridVersion_payload.getVersion());
			priceGridVersion.setPublishedDate(priceGridVersion_payload.getPublishedDate());
			em.flush();

			// probably a bug involving the json_content @Lob
			// priceGridVersionsRepo.update(priceGridVersion_payload, false);
			return Response.noContent().build();
		} catch (jakarta.persistence.OptimisticLockException exc) {
			return WSUtils.response(Status.CONFLICT, servReq,
			  "Grille Tarifaire peut-être modifiée depuis (\"_v_lock\" non-concordant).");			
		} catch (jakarta.persistence.EntityNotFoundException exc) {
			return WSUtils.response(Status.NOT_FOUND, servReq,
			  "Grille Tarifaire peut-être supprimée depuis.");
		}
	}


}
