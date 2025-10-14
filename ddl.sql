DROP DATABASE IF EXISTS `ecommerce_zapatos`;
CREATE DATABASE IF NOT EXISTS `ecommerce_zapatos`;
USE `ecommerce_zapatos`;


CREATE TABLE `Usuarios` (
  `usuario_id` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(50) DEFAULT NULL,
  `apellido` varchar(50) DEFAULT NULL,
  `correo` varchar(100) DEFAULT NULL, -- UNIQUE
  PRIMARY KEY (`usuario_id`),
  UNIQUE(`correo`)
);

ALTER TABLE `Usuarios` ADD CONSTRAINT usuarios_corre_uq UNIQUE(`correo`);

CREATE TABLE `Pedidos` (
  `pedido_id` int NOT NULL AUTO_INCREMENT,
  `usuario_id_fk` int DEFAULT NULL,
  `fecha_pedido` date DEFAULT NULL,
  `total` decimal(10,2) DEFAULT NULL,
  `estado` ENUM('preparacion','cancelado','en_camino','entregado','devuelto') DEFAULT 'preparacion',
  PRIMARY KEY (`pedido_id`),
  CONSTRAINT `Pedidos_ibfk_1` FOREIGN KEY (`usuario_id_fk`) REFERENCES `Usuarios` (`usuario_id`)
);

ALTER TABLE `Pedidos` MODIFY `fecha_pedido` date NOT NULL DEFAULT(CURRENT_DATE);

CREATE TABLE `Productos`(
    `producto_id` INT AUTO_INCREMENT,
    `nombre` VARCHAR(50) NOT NULL,
    `precio_unitario` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `precio_venta` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    PRIMARY KEY (`producto_id`)
);

ALTER TABLE `Productos` ADD CONSTRAINT producto_precio_chk CHECK(
  precio_unitario > 0 AND precio_venta >= precio_unitario
);

-- ALTER TABLE `Productos` DROP CONSTRAINT producto_precio_chk;


CREATE TABLE `PedidoProducto`(
    `pedido_id_fk` INT NOT NULL,
    `producto_id_fk` INT NOT NULL,
    `cantidad` INT NOT NULL DEFAULT 1 CHECK(cantidad >=1),
    PRIMARY KEY(`pedido_id_fk`, `producto_id_fk`),
    FOREIGN KEY(`pedido_id_fk`) REFERENCES `Pedidos`(`pedido_id`),
    FOREIGN KEY(`producto_id_fk`) REFERENCES `Productos`(`producto_id`)
);

ALTER TABLE `PedidoProducto` ADD CONSTRAINT pedido_producto_chk CHECK(cantidad >= 1);

CREATE INDEX idx_pedidos_usuario_fecha ON `Pedidos`(usuario_id_fk, fecha_pedido);

CREATE INDEX idx_productos_nombre ON `Productos`(`nombre`);

DROP INDEX idx_productos_nombre ON `Productos`;

-- Procedures


DELIMITER $$
CREATE PROCEDURE IF NOT EXISTS hola_mundo(IN p_nombre VARCHAR(100))
BEGIN
  SELECT CONCAT('Hola :', p_nombre) AS Saludo;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS hola_mundo;

-- Llamado
CALL nombre_procedure(...);

DELIMITER //
CREATE PROCEDURE IF NOT EXISTS calcular_empleado(IN p_ventas DECIMAL(10,2))
BEGIN
  IF p_ventas >= 100000 THEN
    SELECT 'El empleado cumplio con las ventas' as resultado;
  ELSEIF p_ventas >= 50000 THEN
    SELECT 'El empleado CASI cumplio con las ventas' as resultado;
  ELSE 
    SELECT 'El empleado efe de foca con las ventas' as resultado;
  END IF;
END
//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE mostrar_top_ventas(IN p_min DECIMAL(10,2), IN p_max DECIMAL(10,2))
BEGIN
  SELECT * FROM Pedidos WHERE total BETWEEN p_min AND p_max;
END //
DELIMITER ;
CALL mostrar_top_ventas(40.00, 100.00);


CREATE TABLE Cupones(
  cupon_id INT AUTO_INCREMENT,
  descuento DECIMAL(5,2) NOT NULL CHECK(descuento > 0 AND descuento <= 100),
  usuario_id_fk INT NOT NULL,
  PRIMARY KEY(cupon_id),
  FOREIGN KEY(usuario_id_fk) REFERENCES Usuarios(usuario_id)
);

-- DROP VIEW vw_.....
CREATE OR REPLACE VIEW vw_top_clientes_compras AS
SELECT CONCAT_WS(' ',u.apellido,u.nombre) as nombres, usuario_id, SUM(p.total) as total_pedidos, COUNT(p.pedido_id) as cantidad_pedidos, GROUP_CONCAT(p.fecha_pedido) as fechas
FROM Pedidos p
INNER JOIN Usuarios u ON p.usuario_id_fk = u.usuario_id
GROUP BY u.usuario_id ORDER BY total_pedidos DESC;


DELIMITER //

CREATE PROCEDURE aplicar_cupon_usuario(IN p_total_min DECIMAL(10,2), IN p_cantidad_min INT, IN p_descuento DECIMAL(5,2))
BEGIN
  DECLARE p_total_pedidos DECIMAL(10,2) DEFAULT (SELECT total_pedidos FROM vw_top_clientes_compras LIMIT 1);

  DECLARE p_usuario_id INT DEFAULT 0.00;

  SET p_usuario_id = (SELECT usuario_id FROM vw_top_clientes_compras LIMIT 1);

  CASE 
    WHEN p_total_min >= p_total_pedidos THEN
      INSERT INTO Cupones(descuento, usuario_id_fk) VALUES(p_descuento, p_usuario_id);
    ELSE
      SELECT 'No se le asigno ningun cupon por pato.' as Error;
  END CASE;
END 
//
DELIMITER ;

CALL aplicar_cupon_usuario(100.00, 0, 30.00);