
-- I_CONFIG_IMPORT (Generic import config table) definition

CREATE TABLE `I_CONFIG_IMPORT` (
  `type` varchar(32) NOT NULL,

  `src_path` varchar(256) DEFAULT NULL,
  `src_col_labels_rowid` int DEFAULT NULL COMMENT 'Numéro de ligne des entêtes de colonnes (commence à 1)',
  `src_data_rowid` int DEFAULT NULL COMMENT 'Numéro de ligne du début des données (commence à 1)',
  `src_property_condition` varchar(32) DEFAULT NULL COMMENT 'Nom de propriété (tel que défini dans dst_mapping) dont la présence marque les lignes valides',  
  `dst_path` varchar(256) DEFAULT NULL,
  `dst_mapping` varchar(4096) DEFAULT NULL,
  
	`_date_created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '(audit)',
	`_date_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '(audit)',
  PRIMARY KEY (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci  COMMENT='Configuration des imports, paramétage dev !';



-- I_ARTICLE_TRANSPORT_ACHETE definition
-- TODO build higher grouping on it, like "Carrier company", and/or relate to CARRIER ?... 
CREATE TABLE `I_ARTICLE_TRANSPORT_ACHETE` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
	
	`article_path` varchar(256) NOT NULL DEFAULT '' COMMENT 'Nom canonique du produit de transport',

	`pricegrid_path` varchar(128) NOT NULL DEFAULT '' COMMENT 'chemin de grille à appliquer, de la forme : [grille tarifaire]/[onglet]',
	
	`description` varchar(256) DEFAULT NULL COMMENT 'Commentaire libre du produit',

  PRIMARY KEY (`id`),
  UNIQUE KEY `I_ARTICLE_TRANSPORT_UNIQUE` (`article_path`),
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci  COMMENT='Table de référence "Produits commerciaux des transporteurs"';



-- I_TRANSPORT_ACHETE definition

CREATE TABLE `I_TRANSPORT_ACHETE` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `import_id` bigint unsigned NOT NULL,

  `article_id` bigint unsigned NOT NULL COMMENT 'Représente le produit de transport (du point de vue du transporteur)',
  

  `carrier_invoice_num` varchar(32) DEFAULT NULL COMMENT 'Numéro de facture Fournisseur(=Transporteur) - env. 1 par fichier',
  `carrier_invoice_date` datetime DEFAULT NULL COMMENT 'Date de facture Fournisseur(=Transporteur)',

  `carrier_order_num` varchar(32) DEFAULT NULL COMMENT 'Numéro de commande (ou éq.) Fournisseur (=Transporteur) - env. 1 par ligne de fichier',
  `carrier_order_date` datetime DEFAULT NULL COMMENT 'Date de commande (ou éq.) Fournisseur (=Transporteur)',

  `internal_reference` varchar(256) DEFAULT NULL COMMENT 'Référence Client (=ACADIA) fournie par Logistique au Transporteur : num facture parfois au pluriel, parfois num de commande, etc.',
  `doc_reference_list` varchar(512) DEFAULT NULL COMMENT '"colon-separated list" des factures ACADIA résolues à partir de la colonne "internal_reference"',

  
  `ship_customer_label` varchar(64) DEFAULT NULL,
  `ship_country` varchar(2) DEFAULT NULL,
  `ship_zipcode` varchar(16) DEFAULT NULL,
  `ship_comment` varchar(256) DEFAULT NULL COMMENT 'commentaire libre du Fournisseur (ou inspiré de)',


  `req_total_weight` decimal(10,3) DEFAULT NULL COMMENT '(optionnel) le poids déclaré par le Client (=ACADIA). Si dispo, elle devrait concorder avec le poids X3',
  `total_weight` decimal(10,3) NOT NULL COMMENT 'le poids utilisé par le Fournisseur (=Transporteur) comme base de facturation. Peut être un "poids volumique".',
  `parcel_count` int DEFAULT NULL COMMENT '(optionnel) le nombre de colis utilisé par le Fournisseur (=Transporteur) comme base de facturation.',
  

  PRIMARY KEY (`id`),
  KEY `I_TRANSPORT_ACHETE_I_IMPORT_FK` (`import_id`),
  KEY `I_TRANSPORT_ACHETE_I_TR_ACH_ARTICLE_FK` (`article_id`),
  CONSTRAINT `I_TRANSPORT_ACHETE_I_IMPORT_FK` FOREIGN KEY (`import_id`) REFERENCES `I_IMPORT` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `I_TRANSPORT_ACHETE_I_TR_ACH_ARTICLE_FK` FOREIGN KEY (`article_id`) REFERENCES `I_ARTICLE_TRANSPORT_ACHETE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci  COMMENT='Lignes importées des factures Transporteurs, retravaillées';




-- I_TRANSPORT_ACHETE_DETAIL definition

CREATE TABLE `I_TRANSPORT_ACHETE_DETAIL` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `tr_achete_id` bigint unsigned NOT NULL,


  `ssarticle_name` varchar(64) NOT NULL COMMENT 'le sous-article, c''est typiquement la décomposition en principal, option, taxes, frais gasoil, etc., défini librement par le transporteur',
  
  amount decimal(10,3) DEFAULT NULL COMMENT 'le montant au sens le plus basique, HT et TTC mélangés.',
  
  

  PRIMARY KEY (`id`),
  KEY `I_TRANSPORT_ACHETE_DETAIL_I_TRANSPORT_ACHETE_FK` (`tr_achete_id`),
  CONSTRAINT `I_TRANSPORT_ACHETE_DETAIL_I_TRANSPORT_ACHETE_FK` FOREIGN KEY (`tr_achete_id`) REFERENCES `I_TRANSPORT_ACHETE` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci  COMMENT='Lignes filles I_TRANSPORT_ACHETE, comportant tous les montants';


  




/*

BEGIN;
COMMIT;
*/