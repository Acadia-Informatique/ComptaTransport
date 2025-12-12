-- Since no cleaning for Carrier invoices import,
-- we need a way to preserve UNICITY OF IMPORT
ALTER TABLE I_TRANSPORT_ACHETE ADD CONSTRAINT I_TRANSPORT_ACHETE_UNIQUE UNIQUE KEY (article_id,carrier_order_num);


-- MAP_TRANSPORT_INVOICE definition
-- relationship table between 
--   - Carrier invoices (I_TRANSPORT_ACHETE)
--   - Acadia invoices (distinct doc_reference from I_TRANSPORT_VENDU)
CREATE TABLE `MAP_TRANSPORT_INVOICE` (  
  `tr_achete_id` bigint unsigned NOT NULL COMMENT 'pointe vers une ligne de facture Transporteur (une ligne de I_TRANSPORT_ACHETE)',
  `doc_reference` varchar(32) NULL DEFAULT NULL COMMENT 'pointe vers une facture Acadia (une valeur distincte de I_TRANSPORT_VENDU.doc_reference)',
  
  UNIQUE KEY `MAP_TRANSPORT_INVOICE_UNIQUE` (`tr_achete_id`, `doc_reference`),
    
  CONSTRAINT `MAP_TRANSPORT_INVOICE_I_TRANSPORT_ACHETE_FK` FOREIGN KEY (`tr_achete_id`) REFERENCES `I_TRANSPORT_ACHETE` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
  
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci  COMMENT='relation entre  I_TRANSPORT_ACHETE et I_TRANSPORT_VENDU';



-- INPUT_CTRL_COSTS definition

CREATE TABLE `INPUT_CTRL_COSTS` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,

  `tr_achete_id` bigint unsigned NOT NULL COMMENT 'pointe vers une ligne de facture Transporteur (une ligne de I_TRANSPORT_ACHETE)',

-- override computation result
  `theirAmountOK_comment` varchar(256) NULL DEFAULT NULL COMMENT 'Commentaire Prix tarifé transporteur : libre, pour info',
  `ourMarginOK_comment` varchar(256) NULL DEFAULT NULL COMMENT 'Commentaire Marge Acadia : libre, pour info',

  `theirAmountOK_override` TINYINT(2) NULL DEFAULT NULL COMMENT 'OK Prix tarifé  transporteur : valeur de 0 (KO) à 3 (OK), cf. LEVEL_OK dans costs.jsp',
  `ourMarginOK_override` TINYINT(2) NULL DEFAULT NULL COMMENT 'OK Marge Acadia  : valeur de 0 (KO) à 3 (OK), cf. LEVEL_OK dans costs.jsp',


	`_v_lock` bigint unsigned NOT NULL DEFAULT '0' COMMENT '(technical: JPA @Version)',
	`_date_created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '(audit)',
	`_date_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '(audit)',

  PRIMARY KEY (`id`),
  KEY `INPUT_CTRL_COSTS_I_TRANSPORT_ACHETE_FK` (`tr_achete_id`),
  CONSTRAINT `INPUT_CTRL_COSTS_I_TRANSPORT_ACHETE_FK` FOREIGN KEY (`tr_achete_id`) REFERENCES `I_TRANSPORT_ACHETE` (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci  COMMENT='La partie saisissable dans le Contrôle Quotidien';


/*
BEGIN;
COMMIT;
*/