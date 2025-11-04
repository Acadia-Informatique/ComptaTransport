-- ComptaTransport.PRICE_GRID definition

CREATE TABLE `PRICE_GRID` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(32) NOT NULL COMMENT 'Nom public de cette grille. Est référencée par les autres entités.',
  `description` varchar(256) DEFAULT NULL COMMENT 'Description libre',
  `tags` varchar(256) DEFAULT NULL COMMENT '"semicolon-separated string", qualification tech',
	`_v_lock` bigint unsigned NOT NULL DEFAULT '0' COMMENT '(technical: JPA @Version)',
	`_date_created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '(audit)',
	`_date_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '(audit)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `PRICE_GRID_NAME_UNIQUE` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Entête de Grille tarifaire. Les données proprement dites sont dans PRICE_GRID_VERSION.';


-- ComptaTransport.PRICE_GRID_VERSION definition

CREATE TABLE `PRICE_GRID_VERSION` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `price_grid_id` bigint unsigned NOT NULL,  
  `version` varchar(64) NOT NULL COMMENT 'Numéro de version "utilisateur", souvent la date de création',
  `description` varchar(256) DEFAULT NULL COMMENT 'Description libre',
  `published_date` datetime DEFAULT NULL COMMENT 'Nul si non-publiéee, peut être dans le futur. \r\nIndique la version applicable à un instant donné.',
  `json_content` MEDIUMTEXT COMMENT 'Le vrai contenu de la grille, au format défini par le moteur "price-grid.js"',
	`_v_lock` bigint unsigned NOT NULL DEFAULT '0' COMMENT '(technical: JPA @Version)',
	`_date_created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '(audit)',
	`_date_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '(audit)',  
  PRIMARY KEY (`id`),
  UNIQUE KEY `PRICE_GRID_VERSION_UNIQUE` (`price_grid_id`,`version`),
  CONSTRAINT `PRICE_GRID_VERSION_PRICE_GRID_FK` FOREIGN KEY (`price_grid_id`) REFERENCES `PRICE_GRID` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Une version donnée d''une grille tarifaire. L''équivalent d''un jeu de feuilles Excel.';


-- BEGIN;
-- pas de donnée d'init
-- COMMIT;