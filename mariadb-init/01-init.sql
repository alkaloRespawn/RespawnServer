-- Usuario y bases a prueba de recipe
DROP USER IF EXISTS 'alkalo'@'localhost';
DROP USER IF EXISTS 'alkalo'@'127.0.0.1';
DROP USER IF EXISTS 'alkalo'@'%';

CREATE USER 'alkalo'@'localhost' IDENTIFIED BY '123456';
CREATE USER 'alkalo'@'127.0.0.1' IDENTIFIED BY '123456';
CREATE USER 'alkalo'@'%' IDENTIFIED BY '123456';

CREATE DATABASE IF NOT EXISTS QBCore_A0764D
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

GRANT ALL PRIVILEGES ON `QBCore_A0764D`.* TO 'alkalo'@'localhost','alkalo'@'127.0.0.1','alkalo'@'%';
GRANT ALL PRIVILEGES ON `qbcore\_%`.*   TO 'alkalo'@'localhost','alkalo'@'127.0.0.1','alkalo'@'%';

FLUSH PRIVILEGES;
