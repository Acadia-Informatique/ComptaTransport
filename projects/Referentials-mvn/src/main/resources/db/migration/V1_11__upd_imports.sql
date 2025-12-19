-- add 2nd Sales representative to I_TRANSPORT_VENDU

ALTER TABLE `I_TRANSPORT_VENDU` 
  ADD COLUMN `salesrep2` varchar(32) DEFAULT NULL;


-- VIEWS FOR EMULATING CONTROL ENTITIES
-- Not used in application since they don't use indexes, because of the "group by"...
-- but they can ease manual data querying.

-- equivalent of Named Query "TransportSalesHeader_as_ORDER"
create or replace view V_TRANSPORT_ORDER
as
select
max(id) as id,
max(doc_reference) AS doc_reference,
order_reference,
orig_doc_reference,
max(customer_erp_reference) as customer_erp_reference,
max(customer_label) as customer_label,
max(carrier_name) as carrier_name,
max(ship_country) as ship_country,
max(ship_zipcode) as ship_zipcode,
max(doc_date) as doc_date,
max(salesrep) as salesrep,
max(salesrep2) as salesrep2,
max(is_b2c) as is_b2c,
max(total_weight) as total_weight
from I_TRANSPORT_VENDU
group by doc_reference, order_reference;


-- equivalent of Named Query "TransportSalesHeader_as_INVOICE"
create or replace view V_TRANSPORT_INVOICE
as
select
max(id) as id,
max(doc_reference) as doc_reference,
orig_doc_reference as orig_doc_reference,
group_concat(order_reference ORDER BY order_reference SEPARATOR ';' ) as order_reference,
max(customer_erp_reference) as customer_erp_reference,
max(customer_label) as customer_label,
max(carrier_name) as carrier_name,
max(ship_country) as ship_country,
max(ship_zipcode) as ship_zipcode,
max(doc_date) as doc_date,
max(salesrep) as salesrep,
max(salesrep2) as salesrep2,
max(is_b2c) as is_b2c,
sum(total_weight) as total_weight
from V_TRANSPORT_ORDER
group by doc_reference;


BEGIN;
DELETE FROM I_CONFIG_IMPORT WHERE `type` = 'Forfait Transport Vendu';
DELETE FROM I_CONFIG_IMPORT WHERE `type` = 'Transport Vendu';
DELETE FROM I_CONFIG_IMPORT WHERE `type` = 'Facture Geodis EXPRESS';


INSERT INTO I_CONFIG_IMPORT (`type`,src_path,src_col_labels_rowid,src_data_rowid,dst_path,dst_mapping,src_col_condition) VALUES ('Forfait Transport Vendu','file:///Users/Robert.KWAN/Documents/ComptaTransport-input/MONTHLY.xlsx',3,4,NULL,'[

{
	"propertyName": "SOC_CODE",
	"datatype" : "STRING",
	"colIndex": 1,
	"colLabel": "Code"
},
{
	"propertyName": "NUM_DOC",
	"datatype" : "STRING",
	"colIndex": 2,
	"colLabel": "N° Document"
},
{
	"propertyName": "VENDU_A",
	"datatype" : "STRING",
	"colIndex": 3,
	"colLabel": "Vendu-à"
},
{
	"propertyName": "NOM_VENDU_A",
	"datatype" : "STRING",
	"colIndex": 4,
	"colLabel": "Nom Vendu-à"
},
{
	"propertyName": "CODE_PRODUIT",
	"datatype" : "STRING",
	"colIndex": 5,
	"colLabel": "Code"
},

{
	"propertyName": "DESCRIPTION_1",
	"datatype" : "STRING",
	"colIndex": 6,
	"colLabel": "Description 1"
},
{
	"propertyName": "DATE_COMPTA",
	"datatype" : "DATE",
	"colIndex": 7,
	"colLabel": "Date comptable"
},
{
	"propertyName": "SALESREP",
	"datatype" : "STRING",
	"colIndex": 8,
	"colLabel": "Nom du représentant 1"
},
{
	"propertyName": "MONTANT",
	"datatype" : "NUMBER",
	"colIndex": 9,
	"colLabel": "Montant GL"
}


]',0);
INSERT INTO I_CONFIG_IMPORT (`type`,src_path,src_col_labels_rowid,src_data_rowid,dst_path,dst_mapping,src_col_condition) VALUES ('Transport Vendu','file:///Users/Robert.KWAN/Documents/ComptaTransport-input/DAILY.xlsx',3,4,NULL,'[

{
	"propertyName": "SOC_CODE",
	"datatype" : "STRING",
	"colIndex": 1,
	"colLabel": "Code"
},
{
	"propertyName": "TYPE_DOC",
	"datatype" : "STRING",
	"colIndex": 2,
	"colLabel": "Type de pièce"
},
{
	"propertyName": "NUM_CMD",
	"datatype" : "STRING",
	"colIndex": 3,
	"colLabel": "Numéro de commande"
},
{
	"propertyName": "NUM_DOC",
	"datatype" : "STRING",
	"colIndex": 4,
	"colLabel": "N° Document"
},
{
	"propertyName": "VENDU_A",
	"datatype" : "STRING",
	"colIndex": 5,
	"colLabel": "Vendu-à"
},
{
	"propertyName": "NOM_VENDU_A",
	"datatype" : "STRING",
	"colIndex": 6,
	"colLabel": "Nom Vendu-à"
},
{
	"propertyName": "DESCRIPTION_1",
	"datatype" : "STRING",
	"colIndex": 7,
	"colLabel": "Description 1"
},
{
	"propertyName": "TRANSP_CODE",
	"datatype" : "STRING",
	"colIndex": 8,
	"colLabel": "Code"
},
{
	"propertyName": "PAYS",
	"datatype" : "STRING",
	"colIndex": 9,
	"colLabel": "Pays livraison"
},
{
	"propertyName": "ADR_FACTURATION",
	"datatype" : "STRING",
	"colIndex": 10,
	"colLabel": "Adresse de Facture 0"
},
{
	"propertyName": "ADR_LIVRAISON",
	"datatype" : "STRING",
	"colIndex": 11,
	"colLabel": "Adresse de Livraison 0"
},
{
	"propertyName": "CP",
	"datatype" : "STRING",
	"colIndex": 12,
	"colLabel": "Code postal livraison"
},

{
	"propertyName": "BRAND_CODE",
	"datatype" : "STRING",
	"colIndex": 13,
	"colLabel": "Groupe stat. 1"
},
{
	"propertyName": "BRAND_DESCRIPTION",
	"datatype" : "STRING",
	"colIndex": 14,
	"colLabel": "Desc de groupe stat. 1"
},
{
	"propertyName": "PROD_FAMILY_CODE",
	"datatype" : "STRING",
	"colIndex": 15,
	"colLabel": "Groupe stat. 2"
},
{
	"propertyName": "PROD_FAMILY_DESCRIPTION",
	"datatype" : "STRING",
	"colIndex": 16,
	"colLabel": "Desc de groupe stat. 2"
},
{
	"propertyName": "PRODUCT_CODE",
	"datatype" : "STRING",
	"colIndex": 17,
	"colLabel": "Groupe stat. 3"
},
{
	"propertyName": "PRODUCT_DESCRIPTION",
	"datatype" : "STRING",
	"colIndex": 18,
	"colLabel": "Desc de groupe stat. 3"
},

{
	"propertyName": "DATE_COMPTA",
	"datatype" : "DATE",
	"colIndex": 19,
	"colLabel": "Date comptable"
},
{
	"propertyName": "SALESREP",
	"datatype" : "STRING",
	"colIndex": 20,
	"colLabel": "Nom du représentant 1"
},
{
	"propertyName": "SALESREP2",
	"datatype" : "STRING",
	"colIndex": 21,
	"colLabel": "Nom du représentant 2"
},

{
	"propertyName": "POIDS",
	"datatype" : "NUMBER",
	"colIndex": 22,
	"colLabel": "Cumul poids"
},
{
	"propertyName": "MONTANT",
	"datatype" : "NUMBER",
	"colIndex": 23,
	"colLabel": "Montant GL"
}


]',0);


INSERT INTO I_CONFIG_IMPORT (`type`,src_path,src_col_labels_rowid,src_data_rowid,dst_path,dst_mapping,src_col_condition) VALUES ('Facture Geodis EXPRESS','file:///Users/Robert.KWAN/Documents/ComptaTransport-input/Factures/Geodis/GEODIS%20EXPRESS.xlsx#Détail',4,5,NULL,'[
{
	"propertyName": "CARRIER_INVOICE_NUM",
	"datatype" : "STRING",
	"colIndex": 1,
	"colLabel": "N° pièce"
},
{
	"propertyName": "CARRIER_INVOICE_DATE",
	"datatype" : "DATE",
	"colIndex": 2,
	"colLabel": "Date pièce"
},
{
	"propertyName": "INTERNAL_REFERENCE",
	"datatype" : "STRING",
	"colIndex": 7,
	"colLabel": "Référence 1"
},
{
	"propertyName": "CARRIER_ORDER_NUM",
	"datatype" : "STRING",
	"colIndex": 9,
	"colLabel": "N° récépissé"
},
{
	"propertyName": "CARRIER_ORDER_DATE",
	"datatype" : "DATE_AS_ISO_LOCAL_DATE",
	"colIndex": 10,
	"colLabel": "Date récépissé"
},

{
	"propertyName": "ARTICLE_COMPANY",
	"datatype" : "STRING",
	"colIndex": -1,
	"colLabel": "GEODIS"
},
{
	"propertyName": "ARTICLE_ITEM",
	"datatype" : "STRING",
	"colIndex": 11,
	"colLabel": "Code produit"
},
{
	"propertyName": "SHIP_CUSTOMER_LABEL",
	"datatype" : "STRING",
	"colIndex": 21,
	"colLabel": "Nom destinataire"
},
{
	"propertyName": "SHIP_COUNTRY",
	"datatype" : "STRING",
	"colIndex": 24,
	"colLabel": "Code pays destinataire"
},
{
	"propertyName": "SHIP_ZIPCODE",
	"datatype" : "STRING",
	"colIndex": 26,
	"colLabel": "Code postal destinataire"
},
{
	"propertyName": "SHIP_COMMENT",
	"datatype" : "STRING",
	"colIndex": 12,
	"colLabel": "Instruction livraison 1"
},


{
	"propertyName": "REQ_TOTAL_WEIGHT",
	"datatype" : "NUMBER",
	"colIndex": 30,
	"colLabel": "Poids origine (kg)"
},
{
	"propertyName": "TOTAL_WEIGHT",
	"datatype" : "NUMBER",
	"colIndex": 31,
	"colLabel": "Poids repesé (kg)"
},
{
	"propertyName": "PARCEL_COUNT",
	"datatype" : "NUMBER",
	"colIndex": 29,
	"colLabel": "Nb Colis"
},
{
	"propertyName": "TOTAL_AMOUNT",
	"datatype" : "NUMBER",
	"colIndex": 44,
	"colLabel": "Montant TTC"
},
{
	"propertyName": "SUBARTICLE@MAIN",
	"datatype" : "STRING",
	"colIndex": -1,
	"colLabel": "Transport"
},
{
	"propertyName": "AMOUNT@MAIN",
	"datatype" : "NUMBER",
	"colIndex": 38,
	"colLabel": "Mt HT /EXO Transport"
},

{
	"propertyName": "SUBARTICLE@OPTS",
	"datatype" : "STRING",
	"colIndex": -1,
	"colLabel": "Options"
},
{
	"propertyName": "AMOUNT@OPTS",
	"datatype" : "NUMBER",
	"colIndex": 39,
	"colLabel": "Mt HT/EXO Options et autres"
},

{
	"propertyName": "SUBARTICLE@FUELINDEX",
	"datatype" : "STRING",
	"colIndex": -1,
	"colLabel": "Surcharge Carburant"
},
{
	"propertyName": "AMOUNT@FUELINDEX",
	"datatype" : "NUMBER",
	"colIndex": 41,
	"colLabel": "Surcharge Carburant (HT)"
},

{
	"propertyName": "SUBARTICLE@ECOTAX",
	"datatype" : "STRING",
	"colIndex": -1,
	"colLabel": "Eco-participation"
},
{
	"propertyName": "AMOUNT@ECOTAX",
	"datatype" : "NUMBER",
	"colIndex": 42,
	"colLabel": "Participation Sûreté & Environnement (HT)"
},


{
	"propertyName": "SUBARTICLE@VAT",
	"datatype" : "STRING",
	"colIndex": -1,
	"colLabel": "TVA"
},
{
	"propertyName": "AMOUNT@VAT",
	"datatype" : "NUMBER",
	"colIndex": 43,
	"colLabel": "Montant TVA"
},


{
	"propertyName": "SUBARTICLE@EXTRADELIVERY",
	"datatype" : "STRING",
	"colIndex": -1,
	"colLabel": "Supplément Livraison Paris"
},
{
	"propertyName": "AMOUNT@EXTRADELIVERY",
	"datatype" : "NUMBER",
	"colIndex": 58,
	"colLabel": "Livraison Paris - Région parisienne (HT)"
}
]',0);

COMMIT;
