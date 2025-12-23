-- moving MAP_TRANSPORT_INVOICE relationship 
-- from I_TRANSPORT_ACHETE (original imported rows)
-- to INPUT_CTRL_COSTS (user inputs about imported rows)

ALTER TABLE MAP_TRANSPORT_INVOICE ADD input_ctrl_costs_id BIGINT UNSIGNED DEFAULT 0 NOT NULL COMMENT 'FK vers collection owner';

BEGIN;
	-- create missing INPUT_CTRL_COSTS (from now created at import)
	insert into INPUT_CTRL_COSTS
	(tr_achete_id)
	(select imp.id from I_TRANSPORT_ACHETE imp
	left outer join INPUT_CTRL_COSTS uinput on uinput.tr_achete_id = imp.id
	where uinput.id is null); 

	-- transfer link from I_TRANSPORT_ACHETE to INPUT_CTRL_COSTS
	update MAP_TRANSPORT_INVOICE
	set input_ctrl_costs_id = (select id from INPUT_CTRL_COSTS where MAP_TRANSPORT_INVOICE.tr_achete_id = INPUT_CTRL_COSTS.tr_achete_id);
COMMIT;

ALTER TABLE MAP_TRANSPORT_INVOICE DROP FOREIGN KEY MAP_TRANSPORT_INVOICE_I_TRANSPORT_ACHETE_FK;
ALTER TABLE MAP_TRANSPORT_INVOICE DROP KEY MAP_TRANSPORT_INVOICE_UNIQUE;
ALTER TABLE MAP_TRANSPORT_INVOICE DROP COLUMN tr_achete_id;

ALTER TABLE MAP_TRANSPORT_INVOICE ADD CONSTRAINT MAP_TRANSPORT_INVOICE_UNIQUE UNIQUE KEY (input_ctrl_costs_id, doc_reference);
ALTER TABLE MAP_TRANSPORT_INVOICE ADD CONSTRAINT MAP_TRANSPORT_INVOICE_INPUT_CTRL_COSTS_FK FOREIGN KEY (input_ctrl_costs_id)
  REFERENCES INPUT_CTRL_COSTS(id) ON DELETE CASCADE;
  
ALTER TABLE MAP_TRANSPORT_INVOICE MODIFY COLUMN `doc_reference` varchar(32) NOT NULL  COMMENT 'pointe vers une facture Acadia (une valeur distincte de I_TRANSPORT_VENDU.[orig_]doc_reference)';



-- adding more info on that collection
-- (JPA String collection becomes an Embeddable collection)
ALTER TABLE MAP_TRANSPORT_INVOICE ADD `original_reference` VARCHAR(32) NULL COMMENT 'La référence remontée par import / calculée par le système';
ALTER TABLE MAP_TRANSPORT_INVOICE ADD `total_weight_override` DECIMAL(10,3) NULL COMMENT 'Poids de facture ACADIA défini manuellement par utilisateur';
ALTER TABLE MAP_TRANSPORT_INVOICE ADD `total_price_override` DECIMAL(10,2) NULL COMMENT 'Montant TTC de facture ACADIA défini manuellement par utilisateur';

