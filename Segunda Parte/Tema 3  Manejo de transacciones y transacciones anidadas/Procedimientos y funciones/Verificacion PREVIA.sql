USE Automotors;

-- Consultas de verificación PREVIA
PRINT '--- ESTADO ANTES ---';

-- 1. ¿Cuántas ventas hay en total?
SELECT COUNT(*) AS [Total Ventas Antes]
FROM dbo.Venta;

-- 2. ¿Cuánto stock tiene el Vehículo 1?
SELECT stock AS [Stock Vehiculo1 Antes]
FROM dbo.Vehiculo
WHERE id_vehiculo = 1;

