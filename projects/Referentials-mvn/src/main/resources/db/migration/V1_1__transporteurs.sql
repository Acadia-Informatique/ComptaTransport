CREATE TABLE ComptaTransport.CARRIER (
	name varchar(32) NOT NULL COMMENT 'de X3',
	short_name varchar(16) NULL COMMENT 'de X3 (Pas très sûr de l''utilité...)',
	label varchar(64) NOT NULL COMMENT 'inspiré de X3',
	description varchar(256) NULL COMMENT 'libre, pour doc.',
	group_name varchar(32) NULL COMMENT 'Pour le contrôle, tiré de la feuille Excel', 
	zero_charge BOOL NOT NULL COMMENT 'Pour le contrôle',
	warning_msg varchar(64) NULL COMMENT 'Pour le contrôle',
	_v_lock BIGINT UNSIGNED DEFAULT 0 NOT NULL COMMENT '(technical: JPA @Version)',
	CONSTRAINT CARRIER_PK PRIMARY KEY (name)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci
COMMENT='Liste les transporteurs tels que définis dans l''ERP Sage X3, et en les complétant avec la vision Compta.';


BEGIN;

INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('ADEFINIR','A DEFINIR','A DEFINIR',NULL,NULL,1,'INUTILISÉ');
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('ARSILIATRANS','ARSILIA','ARSILIA GLOBAL SERVICES',NULL,NULL,0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('AVION','AVION','AVION',NULL,NULL,0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('BATEAU','BATEAU','BATEAU',NULL,NULL,0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('BEAU','BEAU','TRANSPORT BEAU',NULL,'BEAU',0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('CALBERAFFRET','CALAFFRET','CALBERSON AFFRET',NULL,'CALBERMSG',0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('CALBEREXPALETTE','CALEXPAL','CALBERSON EXPRESS PALETTE',NULL,'CALBEREXPRESS',0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('CALBEREXPRESS','CALEXPRESS','CALBERSON EXPRESS',NULL,'CALBEREXPRESS',0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('CALBERMESPALET','CALMESPAL','CALBERSON MESSAGERIE PALETTE',NULL,NULL,0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('CALBERMESSAGERI','CALMESSAGE','CALBERSON MESSAGERIE',NULL,'CALBERMSG',0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('CALEUROFIRST','CALEUROFIR','CALBERSON EUROFIRST',NULL,NULL,0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('CALXPKPART','CALXPKPART','CALBERSON XPK-PART',NULL,'XPK',0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('CALXPKPRO','CALXPKPRO','CALBERSON XPK-PRO',NULL,'XPK',0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('CHRONOPOSTPART','CHRONOPART','CHRONO PARTICULIER',NULL,'Chrono',0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('CHRONOPOSTPRO','CHRONOPRO','CHRONO PRO',NULL,'Chrono',0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('COLISSIMO','COLISSIMO','LA POSTE COLISSIMO',NULL,'COLISSIMO',0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('DROP','DROP','DROP',NULL,'DROP',1,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('FEDEX','FEDEX','FEDEX EXPRESS',NULL,'Fedex',0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('FEDEXPALETTE','FEDEXPAL','FEDEX PALETTE',NULL,'FEDEXPALETTE',0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('INTEGRATION','INTEGR','INTEGRATION',NULL,'INTEGRATION',0,'TEMPORAIRE');
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('MAZETAFFRET','MAZETAFFR','MAZET AFFRETEMENT',NULL,NULL,0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('MAZETMESSAGERIE','MAZETMSG','MAZET MESSAGERIE',NULL,'MAZETMESSAGERIE',0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('PARCLIENT','PARCLIENT','PORT PAYE PAR CLIENT',NULL,'PARCLIENT',1,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('PARCONSTRUCTEUR','PARCONSTRU','PAR CONSTRUCTEUR',NULL,NULL,0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('PARNOSSOINS','PARNOSSOIN','PAR NOS SOINS',NULL,'PARNOSSOINS',1,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('SCHENKERAFFRET','SCHENKAFFR','SCHENKER AFFRET',NULL,NULL,0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('SCHENKERMESSAGE','SCHENKMESS','SCHENKER MESSAGERIE',NULL,'SCHENKER',0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('SCHENKERPREMIUM','SCHENKPREM','SCHENKER PREMIUM',NULL,'SCHENKER',0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('SCHENKERPREMPAL','SCHENKPPAL','SCHENKER PREMIUM PALETTE',NULL,'SCHENKER',0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('STKREV','STKREV','STOCK REVENDEUR',NULL,'STKREV',1,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('SURPLACE','SURPLACE','SUR PLACE',NULL,'SURPLACE',1,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('TDL',NULL,'TDL TRANSPORTS DISTR LOGISTIQUE',NULL,'TDL',0,'TEMP. - AFFRET');
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('TNTPART','TNT PART','TNT PART',NULL,NULL,0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('TNTTRACKING','TNT WS','TNT Numero Tracking',NULL,'TNT',0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('TRANSITAIRE','TRANSITAIR','TRANSITAIRE VRAC',NULL,'TRANSITAIRE',1,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('TRANSITAIREAV','TRANSIT AV','TRANSITAIRE AVION',NULL,'TRANSITAIREAV',1,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('TRANSITAIREBA','TRANSIT BA','TRANSITAIRE BATEAU (80*120)',NULL,NULL,1,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('TRANSITAIREBA1','TRANSIT BA','TRANSITAIRE BATEAU (100*120)',NULL,'TRANSITAIREBA1',1,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('UPSPART','UPS','UPS',NULL,'UPS',0,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,zero_charge,warning_msg) VALUES ('UPSSIGNATURE','UPSSIGNATU','UPS AVEC SIGNATURE',NULL,'UPS',0,NULL);


COMMIT;