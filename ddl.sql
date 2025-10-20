-- Active: 1760719758384@@127.0.0.1@3309@ecommerce_zapatos
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
SELECT CONCAT_WS(' ',u.apellido,u.nombre) as nombres, u.usuario_id, SUM(p.total) as total_pedidos, COUNT(p.pedido_id) as cantidad_pedidos, GROUP_CONCAT(p.fecha_pedido) as fechas
FROM Pedidos p
INNER JOIN Usuarios u ON p.usuario_id_fk = u.usuario_id
GROUP BY u.usuario_id ORDER BY total_pedidos DESC;


DELIMITER //
DROP PROCEDURE IF EXISTS aplicar_cupon_usuario//
CREATE PROCEDURE aplicar_cupon_usuario(IN p_total_min DECIMAL(10,2), IN p_cantidad_min INT, IN p_descuento DECIMAL(5,2))
BEGIN -- AYYY JUANDiiii
  DECLARE fin INT DEFAULT 0;
  DECLARE v_total_pedidos DECIMAL(10,2) DEFAULT 0.00;
  DECLARE v_usuario_id INT DEFAULT 0;
  DECLARE v_nombres VARCHAR(200) DEFAULT "";
  DECLARE v_cantidad_pedidos INT DEFAULT 0;
  DECLARE v_fechas VARCHAR(200) DEFAULT "";
  DECLARE cur CURSOR FOR SELECT nombres, usuario_id, total_pedidos, cantidad_pedidos, fechas FROM vw_top_clientes_compras;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET fin = 1;
  -- Abrir el CURSOR
  OPEN cur;
  registros : LOOP
    FETCH cur INTO v_nombres, v_usuario_id, v_total_pedidos, v_cantidad_pedidos, v_fechas;
    IF fin = 1 THEN LEAVE registros; END IF;

    CASE 
      WHEN  v_total_pedidos >= p_total_min THEN
        INSERT INTO Cupones(descuento, usuario_id_fk) VALUES(p_descuento, v_usuario_id);
      ELSE
        SELECT CONCAT_WS(': ','No se le asigno ningun cupon a', v_nombres)as Error;
    END CASE;
  END LOOP registros;
  -- Cerrar el CURSOR
  CLOSE cur;
END 
//
DELIMITER ;

CALL aplicar_cupon_usuario(100.00, 0, 15.00);


--- CREAR UN PROCEDIMIENTO DE ALMACENADO QUE CREE N PEDIDOS PARA UN USUARIO X CON UN VALOR DE 0 Y ESTADO DE PREPARACION
-- HACIENDO USO DE WHILE
DELIMITER //
DROP PROCEDURE IF EXISTS crear_pedidos//
CREATE PROCEDURE crear_pedidos(IN p_usuario_id INT, IN p_n INT)
  BEGIN
    DECLARE i INT DEFAULT 1;

  WHILE i <= p_n DO
    INSERT INTO Pedidos(usuario_id_fk, total)
    VALUES (p_usuario_id, 0.00);
    SET i = i + 1;
  END WHILE;
END
//

DELIMITER ;

CALL crear_pedidos(2,5);



DELIMITER $$
DROP FUNCTION fn_total_pedido $$
CREATE FUNCTION fn_total_pedido(p_pedido_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
  DECLARE v_total DECIMAL(10,2);

  SELECT IFNULL(SUM(pp.cantidad * pr.precio_venta), 0.00) INTO v_total FROM Pedidos p 
  INNER JOIN PedidoProducto pp ON p.pedido_id = pp.pedido_id_fk
  INNER JOIN Productos pr ON pp.producto_id_fk = pr.producto_id
  WHERE p.pedido_id = p_pedido_id;
  
  RETURN v_total;
END
$$
DELIMITER ;

SELECT p.pedido_id, p.fecha_pedido, fn_total_pedido(p.pedido_id) as TotalPedido 
FROM Pedidos p;





DELIMITER $$
DROP FUNCTION fn_cantidad_pedido $$
CREATE FUNCTION fn_cantidad_pedido(p_pedido_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
  DECLARE v_total INT;

  SELECT SUM(pp.cantidad) INTO v_total FROM PedidoProducto pp
  WHERE pp.pedido_id_fk = p_pedido_id;

  RETURN IFNULL(v_total, 0);
END
$$
DELIMITER ;

SELECT p.pedido_id, p.fecha_pedido, fn_cantidad_pedido(p.pedido_id) as TotalCantidad,
fn_total_pedido(p.pedido_id) as TotalPedido
FROM Pedidos p;


-- SE REQUIERE UNA FUNCION QUE RETORNE LA CANTIDAD DE DINERO DE PEDIDOS POR UN RANGO DE FECHAS ESPECIFICOS.
-- SE REQUIERE UNA FUNCION PARA SABER LA CANTIDAD POR PRODUCTOS VENDIDOS

DELIMITER $$
DROP FUNCTION IF EXISTS fn_total_ventas_rango $$
CREATE FUNCTION fn_total_ventas_rango(p_fecha_inicio DATE, p_fecha_fin DATE)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
  DECLARE v_total DECIMAL(10,2);

  SELECT SUM(pp.cantidad * pr.precio_venta) INTO v_total
  FROM Pedidos p 
  INNER JOIN PedidoProducto pp ON p.pedido_id = pp.pedido_id_fk
  INNER JOIN Productos pr ON pp.producto_id_fk = pr.producto_id
  WHERE p.fecha_pedido BETWEEN p_fecha_inicio AND p_fecha_fin;

  RETURN v_total;
END $$
DELIMITER ;

SELECT fn_total_ventas_rango('2023-10-03', CURRENT_DATE) as TotalVentas;
SELECT fn_total_ventas_rango('2023-10-05', '2023-10-06') as TotalVentas;

SELECT * FROM `PedidoProducto`;
SELECT * FROM `Pedidos`;

DELIMITER $$
CREATE TRIGGER tg_calcular_total_item_pedido
AFTER INSERT ON `PedidoProducto`
FOR EACH ROW
BEGIN
  -- OLD - Valores Antiguos
  -- NEW - Valores Nuevos
  
  DECLARE v_precio_unitario DECIMAL(10,2);
  SET v_precio_unitario = (SELECT precio_venta FROM `Productos` WHERE producto_id = NEW.producto_id_fk);
  UPDATE `Pedidos` SET total = total + (NEW.cantidad * v_precio_unitario) WHERE pedido_id = NEW.pedido_id_fk;
END
$$
DELIMITER ;
SELECT * FROM Pedidos WHERE pedido_id = 15; -- 15
SELECT * FROM `Productos` WHERE producto_id = 2;
INSERT INTO PedidoProducto VALUES(15, 2, 1);

DELIMITER $$
CREATE TRIGGER tg_re_calcular_total_item_pedido
AFTER DELETE ON `PedidoProducto`
FOR EACH ROW
BEGIN
  DECLARE v_precio_unitario DECIMAL(10,2);

  SET v_precio_unitario = (SELECT precio_venta FROM `Productos` WHERE producto_id = OLD.producto_id_fk);

  UPDATE `Pedidos` SET total = total - (OLD.cantidad * v_precio_unitario) WHERE pedido_id = OLD.pedido_id_fk;
END
$$

DELIMITER ;

SELECT * FROM Pedidos WHERE pedido_id = 15; -- 15

DELETE FROM `PedidoProducto` WHERE producto_id_fk = 2;


DELIMITER $$
CREATE TRIGGER tg_update_calcular_total_item_pedido
AFTER UPDATE ON `PedidoProducto`
FOR EACH ROW
BEGIN
  DECLARE v_precio_unitario DECIMAL(10,2);
  DECLARE v_precio_old DECIMAL(10,2);
  DECLARE v_precio_new DECIMAL(10,2);
  -- OLD.producto_id_fk = NEW.producto_id_fk
  SET v_precio_unitario = (SELECT precio_venta FROM `Productos` WHERE producto_id = OLD.producto_id_fk);

  SET v_precio_old = OLD.cantidad * v_precio_unitario;
  SET v_precio_new = NEW.cantidad * v_precio_unitario;

  UPDATE `Pedidos` SET total = (total - v_precio_old) + v_precio_new WHERE pedido_id = OLD.pedido_id_fk;

END
$$

DELIMITER ;


SELECT * FROM Pedidos WHERE pedido_id = 15;

SELECT * FROM PedidoProducto WHERE pedido_id_fk = 15; -- 15
UPDATE PedidoProducto SET cantidad = 5 WHERE pedido_id_fk = 15 AND producto_id_fk = 1;


DELIMITER $$
CREATE TRIGGER tg_update_check_total_item_pedido
BEFORE UPDATE ON `PedidoProducto`
FOR EACH ROW
BEGIN
  DECLARE v_precio_unitario DECIMAL(10,2);
  DECLARE v_precio_old DECIMAL(10,2);
  DECLARE v_total_actual DECIMAL(10,2);
  -- OLD.producto_id_fk = NEW.producto_id_fk
  SET v_precio_unitario = (SELECT precio_venta FROM `Productos` WHERE producto_id = OLD.producto_id_fk);
  SET v_total_actual = (SELECT total FROM `Pedidos` WHERE pedido_id = OLD.pedido_id_fk);
  SET v_precio_old = OLD.cantidad * v_precio_unitario;
  IF OLD.producto_id_fk <> NEW.producto_id_fk THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El producto_id_fk son diferentes';
  END IF;
  IF (v_total_actual - v_precio_old) < 0 THEN
      SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'El total no se puede calcular porque la diferencia es negativa';
  END IF;
END
$$
DELIMITER ;

SELECT * FROM Pedidos WHERE pedido_id = 15;

SELECT * FROM PedidoProducto WHERE pedido_id_fk = 15; -- 15
UPDATE PedidoProducto SET cantidad = 1 WHERE pedido_id_fk = 15 AND producto_id_fk = 1;

UPDATE `Productos` SET precio_venta = 150 WHERE producto_id = 1;