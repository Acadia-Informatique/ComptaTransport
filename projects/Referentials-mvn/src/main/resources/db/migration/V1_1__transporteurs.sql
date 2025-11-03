-- ComptaTransport.CARRIER definition

CREATE TABLE `CARRIER` (
  `name` varchar(32) NOT NULL COMMENT 'de X3',
  `short_name` varchar(16) DEFAULT NULL COMMENT 'de X3 (Pas très sûr de l''utilité...)',
  `label` varchar(64) NOT NULL COMMENT 'inspiré de X3',
  `description` varchar(256) DEFAULT NULL COMMENT 'libre, pour doc.',
  `group_name` varchar(32) DEFAULT NULL COMMENT 'Pour le contrôle, tiré de la feuille Excel',
  `tags` varchar(256) DEFAULT NULL COMMENT '"semicolon-separated string", qualification tech ou pour les préférences client',
  `warning_msg` varchar(64) DEFAULT NULL COMMENT 'Pour le contrôle',
  `_v_lock` bigint unsigned NOT NULL DEFAULT '0' COMMENT '(technical: JPA @Version)',
  `_date_created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '(audit)',
  `_date_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '(audit)',
  PRIMARY KEY (`name`)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci
COMMENT='Liste les transporteurs tels que définis dans l''ERP Sage X3, et en les complétant avec la vision Compta.';



BEGIN;

INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('ADEFINIR','A DEFINIR','A DEFINIR',NULL,NULL,'zero-fee','INUTILISÉ');
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('ARSILIATRANS','ARSILIA','ARSILIA GLOBAL SERVICES',NULL,NULL,NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('AVION','AVION','AVION',NULL,NULL,NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('BATEAU','BATEAU','BATEAU',NULL,NULL,NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('BEAU','BEAU','TRANSPORT BEAU',NULL,'BEAU',NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('CALBERAFFRET','CALAFFRET','CALBERSON AFFRET',NULL,'CALBERMSG',NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('CALBEREXPALETTE','CALEXPAL','CALBERSON EXPRESS PALETTE',NULL,'CALBEREXPRESS',NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('CALBEREXPRESS','CALEXPRESS','CALBERSON EXPRESS',NULL,'CALBEREXPRESS',NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('CALBERMESPALET','CALMESPAL','CALBERSON MESSAGERIE PALETTE',NULL,NULL,NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('CALBERMESSAGERI','CALMESSAGE','CALBERSON MESSAGERIE',NULL,'CALBERMSG',NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('CALEUROFIRST','CALEUROFIR','CALBERSON EUROFIRST',NULL,NULL,NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('CALXPKPART','CALXPKPART','CALBERSON XPK-PART',NULL,'XPK',NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('CALXPKPRO','CALXPKPRO','CALBERSON XPK-PRO',NULL,'XPK',NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('CHRONOPOSTPART','CHRONOPART','CHRONO PARTICULIER',NULL,'Chrono',NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('CHRONOPOSTPRO','CHRONOPRO','CHRONO PRO',NULL,'Chrono',NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('COLISSIMO','COLISSIMO','LA POSTE COLISSIMO',NULL,'COLISSIMO',NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('DROP','DROP','DROP',NULL,'DROP','zero-fee',NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('FEDEX','FEDEX','FEDEX EXPRESS',NULL,'Fedex',NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('FEDEXPALETTE','FEDEXPAL','FEDEX PALETTE',NULL,'FEDEXPALETTE',NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('INTEGRATION','INTEGR','INTEGRATION',NULL,'INTEGRATION',NULL,'TEMPORAIRE');
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('MAZETAFFRET','MAZETAFFR','MAZET AFFRETEMENT',NULL,NULL,NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('MAZETMESSAGERIE','MAZETMSG','MAZET MESSAGERIE',NULL,'MAZETMESSAGERIE',NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('PARCLIENT','PARCLIENT','PORT PAYE PAR CLIENT',NULL,'PARCLIENT','zero-fee',NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('PARCONSTRUCTEUR','PARCONSTRU','PAR CONSTRUCTEUR',NULL,NULL,NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('PARNOSSOINS','PARNOSSOIN','PAR NOS SOINS',NULL,'PARNOSSOINS','zero-fee',NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('SCHENKERAFFRET','SCHENKAFFR','SCHENKER AFFRET',NULL,NULL,NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('SCHENKERMESSAGE','SCHENKMESS','SCHENKER MESSAGERIE',NULL,'SCHENKER',NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('SCHENKERPREMIUM','SCHENKPREM','SCHENKER PREMIUM',NULL,'SCHENKER',NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('SCHENKERPREMPAL','SCHENKPPAL','SCHENKER PREMIUM PALETTE',NULL,'SCHENKER',NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('STKREV','STKREV','STOCK REVENDEUR',NULL,'STKREV','zero-fee',NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('SURPLACE','SURPLACE','SUR PLACE',NULL,'SURPLACE','zero-fee',NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('TDL',NULL,'TDL TRANSPORTS DISTR LOGISTIQUE',NULL,'TDL',NULL,'TEMP. - AFFRET');
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('TNTPART','TNT PART','TNT PART',NULL,NULL,NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('TNTTRACKING','TNT WS','TNT Numero Tracking',NULL,'TNT',NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('TRANSITAIRE','TRANSITAIR','TRANSITAIRE VRAC',NULL,'TRANSITAIRE','zero-fee',NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('TRANSITAIREAV','TRANSIT AV','TRANSITAIRE AVION',NULL,'TRANSITAIREAV','zero-fee',NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('TRANSITAIREBA','TRANSIT BA','TRANSITAIRE BATEAU (80*120)',NULL,NULL,'zero-fee',NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('TRANSITAIREBA1','TRANSIT BA','TRANSITAIRE BATEAU (100*120)',NULL,'TRANSITAIREBA1','zero-fee',NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('UPSPART','UPS','UPS',NULL,'UPS',NULL,NULL);
INSERT INTO ComptaTransport.CARRIER (name,short_name,label,description,group_name,tags,warning_msg) VALUES ('UPSSIGNATURE','UPSSIGNATU','UPS AVEC SIGNATURE',NULL,'UPS',NULL,NULL);


COMMIT;