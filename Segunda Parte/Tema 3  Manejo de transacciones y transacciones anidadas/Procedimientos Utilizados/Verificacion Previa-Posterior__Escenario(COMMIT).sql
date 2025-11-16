USE Automotors;
GO

-------------------------------
--Verificación Previa (COMMIT)
-------------------------------

-- 1. Actualiza el estado del vehículo ID 12 a 'disponible' para realizar ejemplo
UPDATE Vehiculo
SET estado = 'disponible'
WHERE id_vehiculo = 12;

--Verificamos el estado del vehículo ID 12 ('disponible')
SELECT id_vehiculo, modelo, estado, precio
FROM Vehiculo
WHERE id_vehiculo = 12;


-------------------------------
--Verificación Posterior (COMMIT)
-------------------------------


-- 1. Verificamos el estado del vehículo (Debería ser 'vendido')
SELECT 
    id_vehiculo, 
    modelo, 
    estado, 
    precio
FROM Vehiculo
WHERE id_vehiculo = 12;

-- 2. Verificamos la nueva Venta (Debe existir y tener un Total calculado)
SELECT TOP 1 
    V.id_venta, 
    V.total, 
    V.fecha, 
    D.id_vehiculo 
FROM Venta V 
JOIN DetalleVenta D ON V.id_venta = D.id_venta
ORDER BY V.id_venta DESC;