USE Automotors;
GO

-------------------------------
--Verificación Previa (ROLLBACK)
-------------------------------


--Verificamos el ID de la próxima Venta a insertar (para demostrar que luego no existe)
SELECT ISNULL(MAX(id_venta), 0) + 1 AS ProximoIDVenta FROM Venta;

--Verificamos que el ID del vehículo a usar no exista
SELECT id_vehiculo FROM Vehiculo WHERE id_vehiculo = 9999;



-------------------------------
--Verificación Posterior (ROLLBACK)
-------------------------------

-- Verificamos si la Venta se registró (Debería ser el mismo ID de la captura 'ANTES' que NO existe)
SELECT TOP 1 id_venta, total, fecha FROM Venta ORDER BY id_venta DESC; 

-- Verificamos que no haya vehículos afectados (El Vehiculo ID 12 debe seguir 'vendido' del Escenario A)
SELECT id_vehiculo, estado FROM Vehiculo WHERE id_vehiculo = 12;