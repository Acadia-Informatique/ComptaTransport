
-- I_FORFAIT_TRSP_VENDU definition

CREATE TABLE `I_FORFAIT_TRSP_VENDU` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `import_id` bigint unsigned NOT NULL,

  `code_societe` varchar(16) DEFAULT NULL,
  `doc_reference` varchar(32) DEFAULT NULL,
  `customer_erp_reference` varchar(16) DEFAULT NULL,
  `customer_label` varchar(64) DEFAULT NULL,
  `product_code` varchar(16) DEFAULT NULL,
  `product_desc` varchar(64) DEFAULT NULL,
  `doc_date` datetime DEFAULT NULL,
  `salesrep` varchar(32) DEFAULT NULL,
  `total_price` decimal(10,2) DEFAULT NULL,

  PRIMARY KEY (`id`),
  KEY `I_FORFAIT_TRSP_VENDU_I_IMPORT_FK` (`import_id`),
  KEY `I_FORFAIT_TRSP_VENDU_customer_erp_reference_IDX` (`customer_erp_reference`) USING BTREE,
  KEY `I_FORFAIT_TRSP_VENDU_product_desc_IDX` (`product_desc`) USING BTREE,
  KEY `I_FORFAIT_TRSP_VENDU_doc_date_IDX` (`doc_date`) USING BTREE,
  CONSTRAINT `I_FORFAIT_TRSP_VENDU_I_IMPORT_FK` FOREIGN KEY (`import_id`) REFERENCES `I_IMPORT` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci  COMMENT='Lignes importées d''export SEI Frais de port mensuel';


-- Complement index for performance
CREATE INDEX AGG_SHIPPING_REVENUE_date_IDX USING BTREE ON AGG_SHIPPING_REVENUE (`date`);


/*

BEGIN;
COMMIT;
*/