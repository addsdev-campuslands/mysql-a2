DROP DATABASE IF EXISTS `ecommerce_zapatos`;
CREATE DATABASE IF NOT EXISTS `ecommerce_zapatos`;
USE `ecommerce_zapatos`;


CREATE TABLE `Usuarios` (
  `usuario_id` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(50) DEFAULT NULL,
  `apellido` varchar(50) DEFAULT NULL,
  `correo` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`usuario_id`)
);

CREATE TABLE `Pedidos` (
  `pedido_id` int NOT NULL AUTO_INCREMENT,
  `usuario_id_fk` int DEFAULT NULL,
  `fecha_pedido` date DEFAULT NULL,
  `total` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`pedido_id`),
  CONSTRAINT `Pedidos_ibfk_1` FOREIGN KEY (`usuario_id_fk`) REFERENCES `Usuarios` (`usuario_id`)
);

CREATE TABLE `Productos`(
    `producto_id` INT AUTO_INCREMENT,
    `nombre` VARCHAR(50) NOT NULL,
    `precio_unitario` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `precio_venta` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    PRIMARY KEY (`producto_id`)
);

CREATE TABLE `PedidoProducto`(
    `pedido_id_fk` INT NOT NULL,
    `producto_id_fk` INT NOT NULL,
    `cantidad` INT NOT NULL DEFAULT 1,
    PRIMARY KEY(`pedido_id_fk`, `producto_id_fk`),
    FOREIGN KEY(`pedido_id_fk`) REFERENCES `Pedidos`(`pedido_id`),
    FOREIGN KEY(`producto_id_fk`) REFERENCES `Productos`(`producto_id`)
);
