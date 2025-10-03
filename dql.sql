USE `ecommerce_zapatos`;
SELECT `pedido_id`, `producto_id`, `cantidad` FROM `PedidoProductoCompuesta`
WHERE `pedido_id` = 1;

SELECT * FROM `Usuarios`;
SELECT * FROM `Pedidos`;
SELECT * FROM `PedidoProducto`
WHERE `pedido_id` = 1;

SELECT `pedido_id`, `producto_id`, `cantidad` FROM `PedidoProducto`
WHERE `pedido_id` = 1;


-- Mostrar pedidos de un Cliente (x)
SELECT u.*, p.*
FROM `Usuarios` as u, `Pedidos` p
WHERE u.usuario_id = p.usuario_id;

SELECT u.correo, p.fecha_pedido, p.pedido_id, pr.nombre, pr.precio_unitario, pr.precio_venta, pp.cantidad
FROM `Usuarios` as u
INNER JOIN `Pedidos` p ON u.usuario_id = p.usuario_id
INNER JOIN `PedidoProducto` pp ON p.pedido_id = pp.pedido_id
INNER JOIN `Productos` pr ON pp.producto_id = pr.producto_id;


SELECT u.correo, p.pedido_id, p.fecha_pedido, SUM(pp.cantidad) as 'total_items', pr.nombre
FROM `Usuarios` as u
INNER JOIN `Pedidos` p ON u.usuario_id = p.usuario_id
INNER JOIN `PedidoProducto` as pp ON p.pedido_id = pp.pedido_id
INNER JOIN `Productos` as pr ON pp.producto_id = pr.producto_id
WHERE u.correo = 'adrian@gmail.com'
GROUP BY p.pedido_id, pr.nombre;

-- Se requiere obtener el total de money de cada pedido realizado por nuestros usuarios

-- Se requiere saber la cantidad total de productos vendidos en una fecha especifica

-- Se requiere saber la cantidad de zapatos deportivos vendidos en un rango de fecha especifica [BETWEEN date1 AND date2]