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
import jakarta.json.Json;
import jakarta.json.JsonArrayBuilder;
import jakarta.json.JsonBuilderFactory;
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
			return Response.ok(priceGrid).build();
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
	public StreamingOutput getAll_WS(@QueryParam("tag") Set<String> tags) {
		Stream<PriceGrid> priceGrids = getAll(tags);
		return WSUtils.entityJsonStreamingOutput(priceGrids);
	}

	public Stream<PriceGrid> getAll(Set<String> tags) {
		Stream<PriceGrid> priceGrids = PriceGridsRepository.getInstance(em).findAll();

		if (tags != null && !tags.isEmpty()) {
			logger.finer("tags detected : " + tags);
			priceGrids = priceGrids.filter(c -> c.getTags().containsAll(tags));
		}
		return priceGrids;
	}

	@POST
	@Consumes(value = MediaType.APPLICATION_JSON)
	public Response add_WS(PriceGrid priceGrid) {
		try {
			/* invalidate tags cache */ TAGS_JSON_timestamp = 0L;
			priceGrid = this.add(priceGrid);
			java.net.URI uri = UriBuilder.fromUri("./price-grids").path(String.valueOf(priceGrid.getId())).build();
			return Response.created(uri).build();
		} catch (IllegalArgumentException exc) {
			return WSUtils.response(Status.BAD_REQUEST, servReq, exc.getMessage());
		} catch (jakarta.persistence.PersistenceException exc) {
			return ApplicationConfig.response(exc, servReq, PriceGrid.class);
		}
	}

	public PriceGrid add(PriceGrid priceGrid) {
		PriceGridsRepository priceGridsRepo = PriceGridsRepository.getInstance(em);

		if (priceGrid == null) {
			throw new IllegalArgumentException("Le corps du message n'a pas pu interprété comme une Grille Tarifaire.");
		}
		if ("".equals(priceGrid.getName())) {
			throw new IllegalArgumentException("Le nom de la Grille Tarifaire ne peut pas être vide.");
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
			/* invalidate tags cache */ TAGS_JSON_timestamp = 0L;
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
			/* invalidate tags cache */ TAGS_JSON_timestamp = 0L;
			PriceGridsRepository.getInstance(em).deleteById(id);
			return Response.noContent().build();
		} catch (jakarta.persistence.PersistenceException exc) {
			return ApplicationConfig.response(exc, servReq, PriceGrid.class);
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
	 *  (utility for versions)
	 * @param v_id
	 * @param priceGrid
	 * @return PriceGridVersion, throws {@link NotFoundException} if none consistent found
	 */
	private PriceGridVersion ensureConsistentGridVersion(Long v_id, PriceGrid priceGrid) {
		PriceGridVersionsRepository priceGridVersionsRepo = PriceGridVersionsRepository.getInstance(em);
		PriceGridVersion priceGridVersion = priceGridVersionsRepo.findById(v_id);

		if (priceGridVersion == null) {
			throw new NotFoundException("Version de Grille Tarifaire peut-être supprimée depuis.");
		}
		if (!priceGrid.getId().equals(priceGridVersion.getPriceGrid().getId())) {
			throw new NotFoundException("Version de Grille Tarifaire incohérente avec la Grille.");
		}
		return priceGridVersion;
	}

	/**
	 * Get all versions of a PriceGrid
	 * @param pgid - Parent PriceGrid id
	 * @return
	 */
	@GET
	@Path("/{id}/versions")
	@Produces(MediaType.APPLICATION_JSON)
	public StreamingOutput versions_getAll_WS(@PathParam("id") Long id, @QueryParam("publishedAt") String publishedAt) {
		/* PriceGrid priceGrid = */ ensureParentPricePrid(id);

		PriceGridVersionsRepository priceGridVersionsRepo = PriceGridVersionsRepository.getInstance(em);
		Stream<PriceGridVersion> versions;
		if (publishedAt != null) {
			try {
				java.time.LocalDateTime dtPublishedAt = WSUtils.parseParamDate(publishedAt);
				versions = priceGridVersionsRepo.findAllPublishedOfOnePriceGrid(id, dtPublishedAt);

			} catch (java.time.format.DateTimeParseException exc) {
				throw new IllegalArgumentException("Erreur d'analyse du paramètre \"publishedAt\" = " + publishedAt
				    + "\", détail: " + exc.getMessage());
			}
		} else {
			versions = priceGridVersionsRepo.findAllOfOnePriceGrid(id);
		}
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
			if (priceGridVersion.getPriceGrid() != null) {
				throw new IllegalArgumentException("Le corps de la requête ne doit pas comporter de Grille (\"priceGrid\").");
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
		PriceGridVersion priceGridVersion = ensureConsistentGridVersion(v_id, priceGrid);

		return Response.ok(priceGridVersion).build();
	}

	@DELETE
	@Path("/{id}/versions/{v_id}")
	public Response versions_delete_WS(@PathParam("id") Long id, @PathParam("v_id") Long v_id) {
		PriceGrid priceGrid = ensureParentPricePrid(id);
		PriceGridVersion priceGridVersion = ensureConsistentGridVersion(v_id, priceGrid);

		PriceGridVersionsRepository priceGridVersionsRepo = PriceGridVersionsRepository.getInstance(em);
		priceGridVersionsRepo.delete(priceGridVersion);

		return Response.noContent().build();
	}

	@PUT
	@Path("/{id}/versions/{v_id}")
	@Consumes(value = MediaType.APPLICATION_JSON)
	public Response versions_update_WS(@PathParam("id") Long id, @PathParam("v_id") Long v_id, PriceGridVersion priceGridVersion_payload) {
		PriceGrid priceGrid = ensureParentPricePrid(id);
		PriceGridVersion priceGridVersion = ensureConsistentGridVersion(v_id, priceGrid);

		// payload check
		if (priceGridVersion_payload.getId() != null && !priceGridVersion_payload.getId().equals(v_id)) {
			return WSUtils.response(Status.BAD_REQUEST, servReq,
			  "Identifiant incohérent dans l'URI et le corps du message."
			 +" Il est possible (et recommandé) de ne pas l'inclure dans le corps du message.");
		}
		if (priceGridVersion_payload.getPriceGrid() != null) {
			return WSUtils.response(Status.BAD_REQUEST, servReq,
			  "Le corps de la requête ne doit pas comporter de Grille (\"priceGrid\"). Il est impossible de réattacher une Version à une autre Grille.");
		}

		// constraint check
		PriceGridVersionsRepository priceGridVersionsRepo = PriceGridVersionsRepository.getInstance(em);
		PriceGridVersion duplicatePriceGridVersion = priceGridVersionsRepo
		  .findVersionOfOnePriceGrid(id, priceGridVersion.getVersion());
		if (!duplicatePriceGridVersion.getId().equals(v_id)) {
			return WSUtils.response(Status.CONFLICT, servReq,
			  "La Version doit rester unique pour chaque Grille Tarifaire.");
		}

		try {
			priceGridVersion_payload.setId(v_id);
			priceGridVersion_payload.setPriceGrid(priceGrid);

			priceGridVersionsRepo.update(priceGridVersion_payload, false);
			return Response.noContent().build();
		} catch (jakarta.persistence.OptimisticLockException exc) {
			return WSUtils.response(Status.CONFLICT, servReq,
			  "Grille Tarifaire peut-être modifiée depuis (\"_v_lock\" non-concordant).");
		} catch (jakarta.persistence.EntityNotFoundException exc) {
			return WSUtils.response(Status.NOT_FOUND, servReq,
			  "Grille Tarifaire peut-être supprimée depuis.");
		}
	}

	@GET
	@Path("/{id}/versions/{v_id}/jsonContent")
	@Produces(value = MediaType.APPLICATION_JSON)
	public String versions_getJsonContent(@PathParam("id") Long id, @PathParam("v_id") Long v_id) {
		PriceGrid priceGrid = ensureParentPricePrid(id);
		PriceGridVersion priceGridVersion = ensureConsistentGridVersion(v_id, priceGrid);
		return priceGridVersion.getJsonContent();
	}

	@PUT
	@Path("/{id}/versions/{v_id}/jsonContent")
	@Consumes(value = MediaType.APPLICATION_JSON)
	@jakarta.ejb.TransactionAttribute(jakarta.ejb.TransactionAttributeType.REQUIRES_NEW)
	public Response versions_setJsonContent(@PathParam("id") Long id, @PathParam("v_id") Long v_id,
			@QueryParam("_v_lock") Long _v_lock, String jsonContent) {
		//BTW, we won't check the payload for JSON conformance
		PriceGrid priceGrid = ensureParentPricePrid(id);
		PriceGridVersion priceGridVersion = ensureConsistentGridVersion(v_id, priceGrid);

		if (_v_lock == null) {
			return WSUtils.response(Status.BAD_REQUEST, servReq,
			  "Un numéro de version doit être passé en paramètre de requête (_v_lock)");
		} else if (!_v_lock.equals(priceGridVersion.get_v_lock())) {
			return WSUtils.response(Status.CONFLICT, servReq,
			  "Version de Grille Tarifaire peut-être modifiée depuis (\"_v_lock\" non-concordant).");
		}

		try {
			priceGridVersion.setJsonContent(jsonContent);
			em.flush(); // to make it fail faster, if needed
			return Response.noContent().build();
		} catch (jakarta.persistence.PersistenceException exc) {
			return ApplicationConfig.response(exc, servReq, PriceGridVersion.class);
		}
	}

	@POST
	@Path("/{id}/versions/{v_id}/copy")
	@Produces(value = MediaType.APPLICATION_JSON)
	public Response versions_copyOne(@PathParam("id") Long id, @PathParam("v_id") Long v_id, @QueryParam("newVersion") String newVersion) {
		PriceGrid priceGrid = ensureParentPricePrid(id);
		PriceGridVersion priceGridVersion = ensureConsistentGridVersion(v_id, priceGrid);


		String newDescription = "COPIE DE " + priceGridVersion.getVersion();
		if (priceGridVersion.getDescription() != null && !priceGridVersion.getDescription().equals("")) {
			newDescription += " : \n" + priceGridVersion.getDescription();
		}
		if (newDescription.length() > 256) {
			newDescription = newDescription.substring(0, 250) + "[...]";
		}

		PriceGridVersion priceGridVersionCopy = new PriceGridVersion();
		// priceGridVersionCopy.setId();
		priceGridVersionCopy.setPriceGrid(priceGrid);
		priceGridVersionCopy.setVersion(newVersion);
		priceGridVersionCopy.setPublishedDate(null);
		priceGridVersionCopy.setDescription(newDescription);
		priceGridVersionCopy.setJsonContent(priceGridVersion.getJsonContent()); // the most important
		// priceGridVersionCopy.set_v_lock();
		// priceGridVersionCopy.getAuditingInfo()id.setUser(...; TODO user management

		try {
			PriceGridVersionsRepository.getInstance(em).insert(priceGridVersionCopy);
			em.flush();

			java.net.URI uri = UriBuilder.fromUri("./price-grids").path(String.valueOf(priceGrid.getId()))
					.path("versions").path(String.valueOf(priceGridVersionCopy.getId())).build();
			return Response.created(uri).build();
		} catch (jakarta.persistence.PersistenceException exc) {
			return ApplicationConfig.response(exc, servReq, PriceGridVersion.class);
		}
	}

	/**
	 * Tag listing service, with static cache.
	 */
	private static String TAGS_JSON = "";
	private static volatile long TAGS_JSON_timestamp = 0L;
	private static final long TAGS_JSON_ttl = 60000L; /* 1 min */

	private static final java.util.List<String> INTERNAL_TAGS, EXTERNAL_TAGS;
	static {
		INTERNAL_TAGS = new java.util.ArrayList<String>();
		INTERNAL_TAGS.add("Standard ACADIA");
		INTERNAL_TAGS.add("Tarif Spécial");
		EXTERNAL_TAGS = new java.util.ArrayList<String>();
		EXTERNAL_TAGS.add("Transporteur");
	}

	@GET
	@Path("/*/tags")
	@Produces(value = MediaType.APPLICATION_JSON)
	public String getCollectedTags() {

		/* rebuild cache if stale (concurrent build is allowed) */
		if (System.currentTimeMillis() - TAGS_JSON_timestamp > TAGS_JSON_ttl) {
			logger.fine("Build TAGS_JSON cache");

			// collect custom tags already set
			Set<String> collectedTags = java.util.Collections.synchronizedSet(new java.util.TreeSet<String>());
			this.getAll(null).forEach(t -> collectedTags.addAll(t.getTags()));
			collectedTags.removeAll(INTERNAL_TAGS);
			collectedTags.removeAll(EXTERNAL_TAGS);

			// build Json String to cache
			JsonBuilderFactory factory = Json.createBuilderFactory(null);
			JsonArrayBuilder internalTagsB = factory.createArrayBuilder();
			for (String tag : INTERNAL_TAGS) {
				internalTagsB.add(tag);
			}
			JsonArrayBuilder externalTagsB = factory.createArrayBuilder();
			for (String tag : EXTERNAL_TAGS) {
				externalTagsB.add(tag);
			}
			JsonArrayBuilder collectedTagsB = factory.createArrayBuilder();
			for (String tag : collectedTags) {
				collectedTagsB.add(tag);
			}
			String newValue = Json.createObjectBuilder()
			    .add("internal", internalTagsB)
				.add("external", externalTagsB)
				.add("collected", collectedTagsB)
			    .build().toString();

			synchronized (this.getClass()) {
				TAGS_JSON = newValue;
				TAGS_JSON_timestamp = System.currentTimeMillis();
			}
		}

		synchronized (this.getClass()) {
			return TAGS_JSON;
		}

	}
}
