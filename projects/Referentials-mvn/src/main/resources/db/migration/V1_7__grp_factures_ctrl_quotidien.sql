-- Adding the "invoice grouping" for "Contrôle Quotidien"
-- consists mainly in altering structures defined in V1_4__import_vente_transport.sql


-- I_TRANSPORT_VENDU definition

ALTER TABLE `I_TRANSPORT_VENDU` ADD
  `orig_doc_reference` varchar(32) DEFAULT NULL
  -- = new column to keep track of the original value of "doc_reference"
  -- not adding an index on it (yet), since it is essentially to preserve info, not supposed to be matched directly
;

BEGIN;
UPDATE I_TRANSPORT_VENDU set 
  orig_doc_reference = doc_reference;
COMMIT;

ALTER TABLE I_TRANSPORT_VENDU MODIFY COLUMN orig_doc_reference varchar(32) NOT NULL;

CREATE INDEX I_TRANSPORT_VENDU_orig_doc_reference_IDX USING BTREE ON I_TRANSPORT_VENDU (orig_doc_reference);



-- VIEWS FOR EMULATING CONTROL ENTITIES
-- (updates)
create or replace view V_TRANSPORT_ORDER
as
select
max(id) as id,
doc_reference, order_reference,
max(orig_doc_reference) as orig_doc_reference, -- OK, since same or less than distinct "order_reference"
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


-- equivalent of Named Query "TransportSalesHeader_as_INVOICE"
create or replace view V_TRANSPORT_INVOICE
as
select
max(id) as id,
doc_reference,
group_concat(orig_doc_reference ORDER BY orig_doc_reference SEPARATOR ';' ) as orig_doc_reference,
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


