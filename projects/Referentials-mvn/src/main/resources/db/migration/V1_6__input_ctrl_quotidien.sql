
-- I_FORFAIT_TRSP_VENDU definition

CREATE TABLE `INPUT_CTRL_REVENUE` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,

  `doc_reference` varchar(32) NOT NULL,

-- override computation result
  `carrierOK_comment` varchar(256) NULL DEFAULT NULL COMMENT 'Commentaire Transport définitif : libre, pour info',
  `amountOK_comment` varchar(256) NULL DEFAULT NULL COMMENT 'Commentaire Montant définitif : libre, pour info',
  `carrierOK_override` TINYINT(2) NULL DEFAULT NULL COMMENT 'OK Transport définitif : valeur de 0 (KO) à 2 (OK), cf. mapping JPA',
  `amountOK_override` TINYINT(2) NULL DEFAULT NULL COMMENT 'OK Montant définitif : valeur de 0 (KO) à 2 (OK), cf. mapping JPA',

-- override computation input
  `is_b2c_override`             bool   NULL DEFAULT NULL COMMENT 'override Commande B2C',
  `is_nonstd_pack_override`     bool   NULL DEFAULT NULL COMMENT 'override Colis Hors-Normes',
  `carrier_override`     varchar(32) NULL DEFAULT NULL COMMENT 'override Transport choisi',
  `price_MAIN_override` decimal(10,2) NULL DEFAULT NULL COMMENT 'override Montant "base" issu de X3',

	`_v_lock` bigint unsigned NOT NULL DEFAULT '0' COMMENT '(technical: JPA @Version)',
	`_date_created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '(audit)',
	`_date_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '(audit)',

  PRIMARY KEY (`id`),
  KEY `INPUT_CTRL_REVENUE_doc_reference_IDX` (`doc_reference`) USING BTREE,
  KEY `INPUT_CTRL_REVENUE_CARRIER_OVERRIDE_FK` (`carrier_override`),
  CONSTRAINT `INPUT_CTRL_REVENUE_UNIQUE` UNIQUE KEY (doc_reference),
  CONSTRAINT `INPUT_CTRL_REVENUE_CARRIER_OVERRIDE_FK` FOREIGN KEY (carrier_override) REFERENCES `CARRIER` (name) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci  COMMENT='La partie saisissable dans le Contrôle Quotidien';


/*

BEGIN;
COMMIT;
*/