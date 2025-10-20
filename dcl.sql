-- Active: 1760719758384@@127.0.0.1@3309@ecommerce_zapatos
-- SELECT user, host, plugin FROM mysql.user;

CREATE USER 'vendedor'@'%' IDENTIFIED BY 's3gur4.';
CREATE USER 'vendedor1'@'%' IDENTIFIED WITH caching_sha2_password  BY 's3gur4.';
CREATE USER 'vendedor2'@'%' IDENTIFIED WITH sha256_password  BY 's3gur4.';

FLUSH PRIVILEGES;

GRANT SELECT ON ecommerce_zapatos.Usuarios TO 'vendedor'@'%';

GRANT SELECT ON ecommerce_zapatos.* TO 'vendedor1'@'%';
GRANT SELECT ON *.* TO 'vendedor2'@'%';
REVOKE SELECT ON *.* FROM 'vendedor2'@'%';
FLUSH PRIVILEGES;

SELECT USER();

SHOW GRANTS FOR 'vendedor2'@'%';

DESCRIBE Pedidos;
-- INSERT INTO Pedidos VALUES(NULL, 1, NOW(),0.00);

CREATE USER 'administrador'@'%' IDENTIFIED WITH sha256_password  BY 's3gur4.';
GRANT ALL PRIVILEGES ON ecommerce_zapatos.* TO 'administrador'@'%';
FLUSH PRIVILEGES;

CREATE USER 'ejemplo'@'%' IDENTIFIED BY 's3gur4.';

GRANT SELECT(nombre, precio_unitario, precio_venta) ON
ecommerce_zapatos.Productos TO 'ejemplo'@'%';
FLUSH PRIVILEGES;
SHOW GRANTS FOR 'administrador'@'%';