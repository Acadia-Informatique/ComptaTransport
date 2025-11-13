-- ComptaTransport.CUSTOMER definition

CREATE TABLE `CUSTOMER` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `erp_reference` varchar(16) NOT NULL COMMENT 'de X3, ex.: "C03372"',
  `label` varchar(64) NOT NULL COMMENT 'Pour lisibilité. Idéalement, utiliser le nom dans  l''ERP. Unicité non-garantie.',
  `tags` varchar(256) DEFAULT NULL COMMENT '"semicolon-separated string", qualification tech ou qualifications diverses',
  `description` varchar(256) DEFAULT NULL COMMENT 'libre, pour doc.',
	`_v_lock` bigint unsigned NOT NULL DEFAULT '0' COMMENT '(technical: JPA @Version)',
	`_date_created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '(audit)',
	`_date_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '(audit)',  
  PRIMARY KEY (`id`),
  UNIQUE KEY `CUSTOMER_ERP_REF_UNIQUE` (`erp_reference`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- ComptaTransport.CUSTOMER_SHIP_PREFERENCES definition

CREATE TABLE `CUSTOMER_SHIP_PREFERENCES` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `customer_id` bigint unsigned NOT NULL,
  `application_date` datetime NOT NULL COMMENT 'Indique les conditions applicables à un instant donné.',
  `override_price_grid` bigint unsigned DEFAULT NULL COMMENT '(optionel) La grille tarifaire particulière à ce client',
  `override_carriers` varchar(256) DEFAULT NULL COMMENT '"semicolon-separated string", FK virtuelle vers CARRIER. A priori le client n''utilisera QUE ces transporteurs.',
  `carrier_tags_whitelist` varchar(256) DEFAULT NULL COMMENT '(optionel) "semicolon-separated string", CARRIER.tags préférés du client',
  `carrier_tags_blacklist` varchar(256) DEFAULT NULL COMMENT '(optionel) "semicolon-separated string", CARRIER.tags que le client veut éviter',
	-- no modification : `_v_lock` bigint unsigned NOT NULL DEFAULT '0' COMMENT '(technical: JPA @Version)',
	`_date_created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '(audit)',
	`_date_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '(audit)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `CUSTOMER_SHIP_PREFERENCES_UNIQUE` (`customer_id`,`application_date`) USING BTREE,
  KEY `CUSTOMER_SHIP_PREFERENCES_PRICE_GRID_FK` (`override_price_grid`),
  CONSTRAINT `CUSTOMER_SHIP_PREFERENCES_CUSTOMER_FK` FOREIGN KEY (`customer_id`) REFERENCES `CUSTOMER` (`id`) ON DELETE CASCADE,
  CONSTRAINT `CUSTOMER_SHIP_PREFERENCES_PRICE_GRID_FK` FOREIGN KEY (`override_price_grid`) REFERENCES `PRICE_GRID` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Préférences du client en matière de transport';



-- ComptaTransport.CUSTOMER_SHIP_PREFERENCES definition

CREATE TABLE `CUSTOMER_SHIP_PREFERENCES` (
  `customer_id` bigint unsigned NOT NULL,
  `application_date` datetime NOT NULL COMMENT 'Indique les conditions applicables à un instant donné.',
  `override_price_grid` bigint unsigned DEFAULT NULL COMMENT '(optionel) La grille tarifaire particulière à ce client',
  `override_carriers` varchar(256) DEFAULT NULL COMMENT '"semicolon-separated string", FK virtuelle vers CARRIER. A priori le client n''utilisera QUE ces transporteurs.',
  `carrier_tags_whitelist` varchar(256) DEFAULT NULL COMMENT '(optionel) "semicolon-separated string", CARRIER.tags préférés du client',
  `carrier_tags_blacklist` varchar(256) DEFAULT NULL COMMENT '(optionel) "semicolon-separated string", CARRIER.tags que le client veut éviter',
	-- no modification lock on this one: `_v_lock` bigint unsigned NOT NULL DEFAULT '0' COMMENT '(technical: JPA @Version)',
  `_date_created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '(audit)',
  `_date_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '(audit)',
  PRIMARY KEY (`customer_id`,`application_date`),
  KEY `CUSTOMER_SHIP_PREFERENCES_PRICE_GRID_FK` (`override_price_grid`),
  CONSTRAINT `CUSTOMER_SHIP_PREFERENCES_CUSTOMER_FK` FOREIGN KEY (`customer_id`) REFERENCES `CUSTOMER` (`id`) ON DELETE CASCADE,
  CONSTRAINT `CUSTOMER_SHIP_PREFERENCES_PRICE_GRID_FK` FOREIGN KEY (`override_price_grid`) REFERENCES `PRICE_GRID` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Préférences du client en matière de transport';


-- ComptaTransport.AGG_SHIPPING_REVENUE definition

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


-- ComptaTransport.AGG_SHIPPING_COST definition

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

insert into CUSTOMER (erp_reference, label) values ('C00244/ACA', 'ASCII INFORMATIQUE');
insert into CUSTOMER (erp_reference, label) values ('C00106',	'ADEFI'                          );
insert into CUSTOMER (erp_reference, label) values ('C00775',	'FCC'                            );
insert into CUSTOMER (erp_reference, label) values ('C00846',	'GIGAHERTZ22'                    );
insert into CUSTOMER (erp_reference, label) values ('C01965',	'TATI MICRO'                     );
insert into CUSTOMER (erp_reference, label) values ('C01728',	'RIS RESEAU'                     );
insert into CUSTOMER (erp_reference, label) values ('C03105',	'ELECTRONIC PARTS'               );
insert into CUSTOMER (erp_reference, label) values ('C01263',	'MACROSS INFORMATIQUE'           );
insert into CUSTOMER (erp_reference, label) values ('C00569',	'DECLIC INFO'                    );
insert into CUSTOMER (erp_reference, label) values ('C01055',	'ISICOM.COM'                     );
insert into CUSTOMER (erp_reference, label) values ('C00149',	'ALBI TECHNOLOGIE SYSTEMES'      );
insert into CUSTOMER (erp_reference, label) values ('C03102',	'HardwareModding'                );
insert into CUSTOMER (erp_reference, label) values ('C01643',	'POINT MICRO DUNKERQUE'          );
insert into CUSTOMER (erp_reference, label) values ('C02409',	'KW DISTRIBUTION'                );
insert into CUSTOMER (erp_reference, label) values ('C00554',	'DAD INFORMATIQUE'               );
insert into CUSTOMER (erp_reference, label) values ('C02049',	'UPDATE INFORMATIQUE'            );
insert into CUSTOMER (erp_reference, label) values ('C00891',	'HARDWARE INFORMATIQUE'          );
insert into CUSTOMER (erp_reference, label) values ('C00496',	'COOKIE'                         );
insert into CUSTOMER (erp_reference, label) values ('C01651',	'PREMIUM-PC'                     );
insert into CUSTOMER (erp_reference, label) values ('C00339',	'BFC'                            );
insert into CUSTOMER (erp_reference, label) values ('C00794',	'FMS INFORMATIQUE'               );
insert into CUSTOMER (erp_reference, label) values ('C00476',	'COMPUCITY ( 13 ) ST MITRE'      );
insert into CUSTOMER (erp_reference, label) values ('C00622',	'DISTRI-ONE ( ATIS COMPUTER )'   );
insert into CUSTOMER (erp_reference, label) values ('C01331',	'MICRO GATE'                     );
insert into CUSTOMER (erp_reference, label) values ('C00963',	'INFO DISTRIB'                   );
insert into CUSTOMER (erp_reference, label) values ('C02280',	'MC2IT'                          );
insert into CUSTOMER (erp_reference, label) values ('C01145',	'LA PUCE INFORMATIQUE'           );
insert into CUSTOMER (erp_reference, label) values ('C01329',	'MICRO DIRECT 34'                );
insert into CUSTOMER (erp_reference, label) values ('C02045',	'UNICSTORE'                      );
insert into CUSTOMER (erp_reference, label) values ('C00477',	'COMPUCITY 69'                   );
insert into CUSTOMER (erp_reference, label) values ('C02389',	'MICRO INFO SERVICE'             );
insert into CUSTOMER (erp_reference, label) values ('C00490',	'CONNECTPLUS'                    );
insert into CUSTOMER (erp_reference, label) values ('C00276',	'ATID'                           );
insert into CUSTOMER (erp_reference, label) values ('C01639',	'POINT CEDRIC INFORMATIQUE'      );
insert into CUSTOMER (erp_reference, label) values ('C00989',	'INFORMAT'' SYSTEMS'             );
insert into CUSTOMER (erp_reference, label) values ('C02369',	'MD INFORMATIQUE (38)'           );


COMMIT;
