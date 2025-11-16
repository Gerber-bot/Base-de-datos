USE Automotors;
GO

-------------------------------
--Escenario de Éxito (COMMIT)
-------------------------------

-- Definición de parámetros
DECLARE @ClienteID INT = 5;
DECLARE @VendedorID INT = 2; 
DECLARE @VehiculoID INT = 12;
DECLARE @MedioPagoID INT = 1; 
DECLARE @PrecioVenta DECIMAL(12,2);
DECLARE @VentaID INT;

-- Obtener el precio del vehículo
SELECT @PrecioVenta = precio 
FROM Vehiculo 
WHERE id_vehiculo = @VehiculoID AND estado = 'disponible'; 

-- --- INICIO DE LA TRANSACCIÓN ---
BEGIN TRANSACTION; 
BEGIN TRY
    
    -- PASO 1: Insertar la cabecera de la Venta
    INSERT INTO Venta (id_cliente, id_usuario, fecha, id_medio_pago)
    VALUES (@ClienteID, @VendedorID, SYSDATETIME(), @MedioPagoID);
    
    SET @VentaID = SCOPE_IDENTITY(); -- Captura el ID de la Venta

    -- PASO 2: Insertar el DetalleVenta (Dispara el trigger de cálculo de Total)
    INSERT INTO DetalleVenta (id_venta, id_vehiculo, cantidad, precio_unit)
    VALUES (@VentaID, @VehiculoID, 1, @PrecioVenta);
    
    -- PASO 3: Actualizar el estado del Vehículo
    UPDATE Vehiculo
    SET estado = 'vendido'
    WHERE id_vehiculo = @VehiculoID;

    -- CONFIRMACIÓN: Si todos los pasos fueron exitosos
    COMMIT TRANSACTION;
    PRINT 'TRANSACCIÓN A: ÉXITO. Venta registrada y vehículo ID 12 actualizado.';

END TRY
BEGIN CATCH
    -- REVERSIÓN: Si cualquier paso falló (ej. FK, CHECK, etc.)
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    PRINT 'FALLO: Transacción revertida. Mensaje: ' + ERROR_MESSAGE();
END CATCH;
GO



-------------------------------------------------------------------------------------------------------


-------------------------------
--Escenario de Error (ROLLBACK)
-------------------------------


DECLARE @ClienteID INT = 5;
DECLARE @VendedorID INT = 2; 
DECLARE @VehiculoID_INCORRECTO INT = 9999; -- ID que forzará la violación de FK
DECLARE @MedioPagoID INT = 1; 
DECLARE @PrecioFalso DECIMAL(12,2) = 1000000.00; 
DECLARE @VentaID INT;

BEGIN TRANSACTION; -- Inicia la unidad de trabajo
BEGIN TRY
    
    -- PASO 1: Insertar la cabecera de la Venta (Este paso es exitoso)
    INSERT INTO Venta (id_cliente, id_usuario, fecha, id_medio_pago)
    VALUES (@ClienteID, @VendedorID, SYSDATETIME(), @MedioPagoID);
    
    SET @VentaID = SCOPE_IDENTITY(); 
    
    -- PASO 2: Insertar el DetalleVenta (ESTE PASO VA A FALLAR POR LA FOREIGN KEY)
    INSERT INTO DetalleVenta (id_venta, id_vehiculo, cantidad, precio_unit)
    VALUES (@VentaID, @VehiculoID_INCORRECTO, 1, @PrecioFalso); -- ¡FALLA AQUÍ!
    
    -- Esta línea se alcanzaría si el Paso 2 no fallara.
    COMMIT TRANSACTION; 
    
    PRINT 'ERROR CRITICO: La Venta se registró incorrectamente.';

END TRY
BEGIN CATCH
    -- El bloque CATCH se activa tras el error de la FK (Paso 2)
    PRINT 'El error se capturó. Activando ROLLBACK...';
    
    -- Se ejecuta el ROLLBACK para deshacer el INSERT de la Venta (Paso 1)
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    PRINT 'TRANSACCIÓN B: REVERTIDA. El registro de venta fue deshecho.';
    PRINT 'Mensaje de error: ' + ERROR_MESSAGE();
END CATCH;
GO