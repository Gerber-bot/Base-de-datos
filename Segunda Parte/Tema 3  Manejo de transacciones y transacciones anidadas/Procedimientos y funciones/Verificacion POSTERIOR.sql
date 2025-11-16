USE Automotors;

-- Consultas de verificación POSTERIOR
PRINT '--- ESTADO DESPUÉS DE LA TRANSACCIÓN ---';

-- 1. ¿Cuántas ventas hay en total?
SELECT COUNT(*) AS [Total Ventas Después]
FROM dbo.Venta;

-- 2. ¿Cuánto stock tiene el Vehículo 1?
SELECT stock AS [Stock Vehiculo1 Después]
FROM dbo.Vehiculo
WHERE id_vehiculo = 1;
