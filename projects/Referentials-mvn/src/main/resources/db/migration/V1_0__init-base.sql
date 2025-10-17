-- to be run as MySQL root user

/* Creation done by FlyWay plugin */
-- CREATE DATABASE `ComptaTransport` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;


CREATE USER 'app-user'@'%' IDENTIFIED BY 'whatever'; -- TODO better change me in prod
GRANT DELETE ON ComptaTransport.* TO 'app-user'@'%';
GRANT INSERT ON ComptaTransport.* TO 'app-user'@'%';
GRANT SELECT ON ComptaTransport.* TO 'app-user'@'%';
GRANT UPDATE ON ComptaTransport.* TO 'app-user'@'%';
GRANT EXECUTE ON ComptaTransport.* TO 'app-user'@'%';
GRANT TRIGGER ON ComptaTransport.* TO 'app-user'@'%';
GRANT LOCK TABLES ON ComptaTransport.* TO 'app-user'@'%';

