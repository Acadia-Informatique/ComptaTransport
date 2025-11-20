-- ComptaTransport.I_IMPORT definition
--

CREATE TABLE `I_IMPORT` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `type` varchar(32) NOT NULL,
  `_date_started` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP  COMMENT '(audit)',
  `_date_ended` datetime DEFAULT NULL  COMMENT '(audit)',
  PRIMARY KEY (`id`),
  KEY `I_IMPORT_type_IDX` (`type`,`_date_started`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Log de tous les jobs d''import, header commun des tables I_*';


-- ComptaTransport.I_TRANSPORT_VENTE definition

CREATE TABLE `I_TRANSPORT_VENDU` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `import_id` bigint unsigned NOT NULL,
  
  `code_societe` varchar(16) DEFAULT NULL,
  `order_reference` varchar(32) DEFAULT NULL,
  `doc_reference` varchar(32) DEFAULT NULL,
  `customer_erp_reference` varchar(16) DEFAULT NULL,
  `customer_label` varchar(64) DEFAULT NULL,
  `product_desc` varchar(64) DEFAULT NULL,
  `is_b2c` bool NOT NULL DEFAULT 0 COMMENT '(currently computed at import)', 
  `carrier_name` varchar(32) DEFAULT NULL,
  `ship_country` varchar(2) DEFAULT NULL,
  `ship_zipcode` varchar(16) DEFAULT NULL,
  `doc_date` datetime DEFAULT NULL,
  `salesrep` varchar(32) DEFAULT NULL,
  `total_weight` decimal(10,3) DEFAULT NULL,
  `total_price` decimal(10,2) DEFAULT NULL,

  PRIMARY KEY (`id`),
  KEY `I_TRANSPORT_VENTE_I_IMPORT_FK` (`import_id`),
  KEY `I_TRANSPORT_VENTE_order_reference_IDX` (`order_reference`) USING BTREE,
  KEY `I_TRANSPORT_VENTE_doc_reference_IDX` (`doc_reference`) USING BTREE,
  KEY `I_TRANSPORT_VENTE_customer_erp_reference_IDX` (`customer_erp_reference`) USING BTREE,
  KEY `I_TRANSPORT_VENTE_product_desc_IDX` (`product_desc`) USING BTREE,
  CONSTRAINT `I_TRANSPORT_VENTE_I_IMPORT_FK` FOREIGN KEY (`import_id`) REFERENCES `I_IMPORT` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci  COMMENT='Lignes importées d''export SEI Frais de port';


-- VIEWS FOR CONTROL ENTITIES

create or replace view V_TRANSPORT_ORDER
as 
select
max(id) as id,
doc_reference, order_reference,
max(customer_erp_reference) as customer_erp_reference,
max(customer_label) as customer_label,
max(carrier_name) as carrier_name,
max(ship_country) as ship_country,
max(ship_zipcode) as ship_zipcode,
max(doc_date) as doc_date,
max(salesrep) as salesrep,
max(total_weight) as total_weight
from I_TRANSPORT_VENDU
group by doc_reference, order_reference;



create or replace view V_TRANSPORT_INVOICE
as 
select
max(id) as id,
doc_reference, 
group_concat(order_reference ORDER BY order_reference SEPARATOR ';' ) as order_reference,
max(customer_erp_reference) as customer_erp_reference,
max(customer_label) as customer_label,
max(carrier_name) as carrier_name,
max(ship_country) as ship_country,
max(ship_zipcode) as ship_zipcode,
max(doc_date) as doc_date,
max(salesrep) as salesrep,
sum(total_weight) as total_weight
from V_TRANSPORT_ORDER
group by doc_reference;


/*

BEGIN;
COMMIT;
*/