-- to be run as MySQL root user

CREATE USER 'mysqldump_user'@'%' IDENTIFIED BY 'mysqldump_user';
GRANT SELECT ON *.* TO 'mysqldump_user'@'%';
GRANT LOCK TABLES ON *.* TO 'mysqldump_user'@'%';
GRANT SHOW VIEW ON *.* TO 'mysqldump_user'@'%';
GRANT TRIGGER ON *.* TO 'mysqldump_user'@'%';
GRANT PROCESS ON *.* TO 'mysqldump_user'@'%';