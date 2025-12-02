-- CUSTOMER definition

CREATE TABLE `CUSTOMER` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `erp_reference` varchar(16) NOT NULL COMMENT 'de X3, ex.: "C03372"',
  `label` varchar(64) NOT NULL COMMENT 'Pour lisibilité. Idéalement, utiliser le nom dans  l''ERP. Unicité non-garantie.',
  `tags` varchar(256) DEFAULT NULL COMMENT '"semicolon-separated string", qualification tech ou qualifications diverses',
  `salesrep` varchar(32) DEFAULT NULL COMMENT 'Responsable du compte client',
  `description` varchar(256) DEFAULT NULL COMMENT 'libre, pour doc.',
	`_v_lock` bigint unsigned NOT NULL DEFAULT '0' COMMENT '(technical: JPA @Version)',
	`_date_created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '(audit)',
	`_date_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '(audit)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `CUSTOMER_ERP_REF_UNIQUE` (`erp_reference`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- CUSTOMER_SHIP_PREFERENCES definition

CREATE TABLE `CUSTOMER_SHIP_PREFERENCES` (
  `customer_id` bigint unsigned NOT NULL,
  `application_date` datetime NOT NULL COMMENT 'Indique les conditions applicables à un instant donné.',
  `override_price_grid` bigint unsigned DEFAULT NULL COMMENT '(optionel) La grille tarifaire particulière à ce client',
  `override_carriers` varchar(256) DEFAULT NULL COMMENT '"semicolon-separated string", FK virtuelle vers CARRIER. A priori le client n''utilisera QUE ces transporteurs.',
  `tags` varchar(256) DEFAULT NULL COMMENT '(optionnel) "semicolon-separated string", preferences tags (such as B2C options)',
  `carrier_tags_whitelist` varchar(256) DEFAULT NULL COMMENT '(optionnel) "semicolon-separated string", CARRIER.tags préférés du client',
  `carrier_tags_blacklist` varchar(256) DEFAULT NULL COMMENT '(optionnel) "semicolon-separated string", CARRIER.tags que le client veut éviter',
	-- no modification lock on this one: `_v_lock` bigint unsigned NOT NULL DEFAULT '0' COMMENT '(technical: JPA @Version)',
  `_date_created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '(audit)',
  `_date_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '(audit)',
  PRIMARY KEY (`customer_id`,`application_date`),
  KEY `CUSTOMER_SHIP_PREFERENCES_PRICE_GRID_FK` (`override_price_grid`),
  CONSTRAINT `CUSTOMER_SHIP_PREFERENCES_CUSTOMER_FK` FOREIGN KEY (`customer_id`) REFERENCES `CUSTOMER` (`id`) ON DELETE CASCADE,
  CONSTRAINT `CUSTOMER_SHIP_PREFERENCES_PRICE_GRID_FK` FOREIGN KEY (`override_price_grid`) REFERENCES `PRICE_GRID` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Préférences du client en matière de transport';


-- AGG_SHIPPING_REVENUE definition

CREATE TABLE `AGG_SHIPPING_REVENUE` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `customer_id` bigint unsigned NOT NULL,
  `product` varchar(64) NOT NULL COMMENT 'Caractérise le produit du l''agrégat (forfait, frais de port, etc.). Défini par la logique d''analyse.',
  `date` date NOT NULL COMMENT 'Date de l''agrégat, à priori on en aura 1 par mois.',
  `amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT 'Montant de l''agrégat',
  `_date_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '(audit)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `AGG_SHIPPING_REVENUE_UNIQUE` (`customer_id`,`product`,`date`),
  CONSTRAINT `AGG_SHIPPING_REVENUE_CUSTOMER_FK` FOREIGN KEY (`customer_id`) REFERENCES `CUSTOMER` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Agrégat des revenus de transport par client/période/"type"';


-- AGG_SHIPPING_COST definition

CREATE TABLE `AGG_SHIPPING_COST` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `customer_id` bigint unsigned NOT NULL,
  `carrier_name` varchar(32) NOT NULL COMMENT 'Transporteur concerné',
  `date` date NOT NULL COMMENT 'Date de l''agrégat, à priori on en aura 1 par mois.',
  `amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT 'Montant de l''agrégat',
  `_date_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '(audit)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `AGG_SHIPPING_COST_UNIQUE` (`customer_id`,`carrier_name`,`date`),
  KEY `AGG_SHIPPING_COST_CARRIER_FK` (`carrier_name`),
  CONSTRAINT `AGG_SHIPPING_COST_CARRIER_FK` FOREIGN KEY (`carrier_name`) REFERENCES `CARRIER` (`name`),
  CONSTRAINT `AGG_SHIPPING_COST_CUSTOMER_FK` FOREIGN KEY (`customer_id`) REFERENCES `CUSTOMER` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Agrégat des coûts de transport par client/période/"type"';


BEGIN;

INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C00244/ACA','ASCII INFORMATIQUE','SOPHANY');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C00106','ADEFI','ALAIN MANIVONG');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C00775','FCC',NULL);
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C00846','GIGAHERTZ22',NULL);
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C01965','TATI MICRO','THIVAN');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C01728','RIS RESEAU',NULL);
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C03105','ELECTRONIC PARTS','MICHAEL');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C01263','MACROSS INFORMATIQUE','ALAIN MANIVONG');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C00569','DECLIC INFO','ALAIN MANIVONG');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C01055','ISICOM.COM','ALAIN MANIVONG');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C00149','ALBI TECHNOLOGIE SYSTEMES','THIVAN');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C03102','HardwareModding','SOPHANY');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C01643','POINT MICRO DUNKERQUE','ALAIN MANIVONG');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C02409','KW DISTRIBUTION','THIVAN');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C00554','DAD INFORMATIQUE','ALAIN MANIVONG');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C02049','UPDATE INFORMATIQUE','SOPHANY');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C00891','HARDWARE INFORMATIQUE','SOPHANY');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C00496','COOKIE','ALAIN MANIVONG');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C01651','PREMIUM-PC','ALAIN MANIVONG');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C00339','BFC','ALAIN MANIVONG');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C00794','FMS INFORMATIQUE','ALAIN MANIVONG');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C00476','COMPUCITY ( 13 ) ST MITRE','ALAIN MANIVONG');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C00622','DISTRI-ONE ( ATIS COMPUTER )','ALAIN MANIVONG');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C01331','MICRO GATE','ALAIN MANIVONG');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C00963','INFO DISTRIB','THIVAN');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C02280','MC2IT','THIVAN');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C01145','LA PUCE INFORMATIQUE','SOPHANY');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C01329','MICRO DIRECT 34','SOPHANY');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C02045','UNICSTORE','ALAIN MANIVONG');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C00477','COMPUCITY 69','ALAIN MANIVONG');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C02389','MICRO INFO SERVICE','MICHAEL');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C00490','CONNECTPLUS','ALAIN MANIVONG');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C00276','ATID','THIVAN');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C01639','POINT CEDRIC INFORMATIQUE','ALAIN MANIVONG');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C00989','INFORMAT'' SYSTEMS','SOPHANY');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C02369','MD INFORMATIQUE (38)','SOPHANY');
INSERT INTO CUSTOMER (erp_reference,label,salesrep) VALUES ('C03360','HYLAE','SOPHANY');

COMMIT;
