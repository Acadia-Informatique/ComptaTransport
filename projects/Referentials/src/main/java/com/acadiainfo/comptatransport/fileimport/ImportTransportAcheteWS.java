package com.acadiainfo.comptatransport.fileimport;

import java.util.List;
import java.util.Map;
import java.util.logging.Logger;

import jakarta.ejb.Stateless;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Query;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Stateless
@jakarta.ws.rs.Path("/import-transport-achete")
public class ImportTransportAcheteWS {
	private static final Logger logger = Logger.getLogger(ImportTransportAcheteWS.class.getName());

	@PersistenceContext(unitName = "ComptaTransportPU")
	private EntityManager em;


	@GET
	@Path("/{type}")
	@Produces(value = MediaType.TEXT_PLAIN)
	public String startBatch(@PathParam("type") String type) {
		ConfigImport config = em.find(ConfigImport.class, type);
		if (config == null) {
			throw new IllegalArgumentException("No config with type=[" + type + "] found");
		}
		try {
			RowsProvider rowsProvider = new RowsProvider(config);
			Map<String, ArticleTransportAchete> refArticles = referenceMapOfArticleTransportAchete();


			Import importHeader = new Import();
			importHeader.setType(config.type);
			em.persist(importHeader);
			em.flush();

			RowImporter_TransportAchete rowImporter = new RowImporter_TransportAchete(em, importHeader, refArticles);
			rowsProvider.walkRows(rowImporter::process);
			em.flush();

			importHeader.setRowCount(rowImporter.getImportedCount());
			importHeader.setDateEnded(System.currentTimeMillis());

			return "rows imported : " + importHeader.getRowCount();

		} catch (Throwable exc) {
			logger.log(java.util.logging.Level.SEVERE, "Error importing " + config.type, exc);
			return "Error importing : " + exc.getMessage();
		}
	}

	private Map<String, ArticleTransportAchete> referenceMapOfArticleTransportAchete() {
		Query queryAll = em.createQuery("SELECT art FROM  ArticleTransportAchete art");

		@SuppressWarnings("unchecked")
		List<ArticleTransportAchete> res = queryAll.getResultList();

		Map<String, ArticleTransportAchete> map = new java.util.HashMap<>();
		for (ArticleTransportAchete item : res) {
			map.put(item.getArticlePath(), item);
		}
		return map;
	}
}
