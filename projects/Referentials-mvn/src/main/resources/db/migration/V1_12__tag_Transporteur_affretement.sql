
-- Note: overwriting existing tags
BEGIN;
UPDATE CARRIER set tags='Affrètement' where name = 'ARSILIATRANS';
UPDATE CARRIER set tags='Affrètement' where name = 'BEAU';
UPDATE CARRIER set tags='Affrètement' where name = 'SCHENKERAFFRET';
UPDATE CARRIER set tags='Affrètement' where name = 'TDL';

COMMIT;
