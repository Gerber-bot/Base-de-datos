USE Automotors;

PRINT '--- INICIO DE LA TRANSACCIÓN EXITOSA ---';

-- 1. Se define los IDs que vamos a usar (IDs fijos de los datos cargados)
DECLARE @ClienteID INT = 1;
DECLARE @UsuarioID INT = 2; -- Asumimos que el ID 2 es un Vendedor
DECLARE @VehiculoID INT = 1; -- Asumimos que el Vehículo 1 tiene stock
DECLARE @PrecioDelVehiculo DECIMAL(12, 2) = 15000000.00; -- Ponemos un precio fijo
DECLARE @VentaID_Generada INT; -- Aquí guardaremos el ID de la nueva venta

-- 2. Iniciamos el bloque TRY-CATCH (Intentar)
BEGIN TRY

    -- 3. Iniciamos la transacción (la "zona segura")
    BEGIN TRANSACTION;
    PRINT '... Transacción iniciada ...';

    -- PASO 1: INSERTAR en la primera tabla (Venta)
    INSERT INTO dbo.Venta (id_cliente, id_usuario, fecha, medio_pago, total)
    VALUES (@ClienteID, @UsuarioID, GETDATE(), 'efectivo', 0);
    
    -- Capturamos el ID de la venta que acabamos de crear
    SET @VentaID_Generada = SCOPE_IDENTITY();
    PRINT 'Paso 1: Venta creada con ID: ' + CAST(@VentaID_Generada AS VARCHAR);

    -- PASO 2: INSERTAR en la segunda tabla (DetalleVenta)
    -- (Esto disparará el trigger que calcula el total)
    INSERT INTO dbo.DetalleVenta (id_venta, id_vehiculo, cantidad, precio_unit)
    VALUES (@VentaID_Generada, @VehiculoID, 1, @PrecioDelVehiculo);
    
    PRINT 'Paso 2: DetalleVenta creado.';

    -- PASO 3: ACTUALIZAR la tercera tabla (Vehiculo)
    UPDATE dbo.Vehiculo
    SET stock = stock - 1 -- Restamos 1 al stock
    WHERE id_vehiculo = @VehiculoID;
    
    PRINT 'Paso 3: Stock del Vehículo actualizado.';

    -- 4. Si todo salió bien, confirmamos los cambios
    COMMIT TRANSACTION;
    PRINT '... Transacción confirmada (COMMIT) ...';

END TRY
-- 5. Bloque CATCH (Si algo falla...)
BEGIN CATCH
    -- 6. Si algo falló, deshacemos TODOS los cambios
    PRINT '!!! Ocurrió un error. Iniciando ROLLBACK. !!!';
    
    IF @@TRANCOUNT > 0 -- (Solo si la transacción sigue abierta)
        ROLLBACK TRANSACTION;
        
    PRINT '... Transacción revertida (ROLLBACK) ...';
    
    -- Mostramos qué error fue
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;

PRINT '--- FIN DE LA PRUEBA ---';
GO


-------------------------------------------------------------------------------------------------------------------------------

PRINT '--- INICIO DE LA PRUEBA DE ERROR (ROLLBACK) ---';

-- 1. Definimos los IDs (los mismos que antes)
DECLARE @ClienteID INT = 1;
DECLARE @UsuarioID INT = 2; 
DECLARE @VehiculoID INT = 1; 
DECLARE @PrecioDelVehiculo DECIMAL(12, 2);
DECLARE @VentaID_Generada INT; 

SELECT @PrecioDelVehiculo = precio 
FROM dbo.Vehiculo 
WHERE id_vehiculo = @VehiculoID;

-- 2. Iniciamos el bloque TRY
BEGIN TRY

    -- 3. Iniciamos la transacción
    BEGIN TRANSACTION VentaVehiculo;
    PRINT '... Transacción iniciada ...';

    -- PASO 1: INSERTAR en Venta (Esto funcionará)
    INSERT INTO dbo.Venta (id_cliente, id_usuario, fecha, medio_pago, total)
    VALUES (@ClienteID, @UsuarioID, GETDATE(), 'efectivo', 0);
    
    SET @VentaID_Generada = SCOPE_IDENTITY();
    PRINT 'Paso 1: Venta creada con ID: ' + CAST(@VentaID_Generada AS VARCHAR);
    PRINT '... (Paso 1 completado exitosamente) ...';

    -- ========================================================
    --  ERROR INTENCIONAL
    -- ========================================================
    PRINT 'Inyectando error intencional...';
    RAISERROR('ERROR SIMULADO: Fallo en el sistema de pago.', 16, 1);
    -- (La severidad 16 es un error de usuario que activa el CATCH)
    -- ========================================================

    -- ESTAS LÍNEAS NUNCA SE EJECUTARÁN
    -- PASO 2: INSERTAR en DetalleVenta
    INSERT INTO dbo.DetalleVenta (id_venta, id_vehiculo, cantidad, precio_unit)
    VALUES (@VentaID_Generada, @VehiculoID, 1, @PrecioDelVehiculo);
    PRINT 'Paso 2: DetalleVenta creado.';

    -- PASO 3: ACTUALIZAR Vehiculo
    UPDATE dbo.Vehiculo
    SET stock = stock - 1 
    WHERE id_vehiculo = @VehiculoID;
    PRINT 'Paso 3: Stock del Vehículo actualizado.';

    -- 4. El COMMIT nunca se alcanzará
    COMMIT TRANSACTION VentaVehiculo;
    PRINT '... Transacción confirmada (COMMIT) ...'; -- (No veremos este mensaje)

END TRY
-- 5. Bloque CATCH (El error nos enviará aquí)
BEGIN CATCH
    PRINT '!!! Ocurrió un error. Iniciando ROLLBACK. !!!';
    
    -- 6. Se revierten TODOS los cambios (incluido el INSERT del Paso 1)
    IF @@TRANCOUNT > 0 
        ROLLBACK TRANSACTION VentaVehiculo;
        
    PRINT '... Transacción revertida (ROLLBACK) ...';
    
    -- Mostramos el error que simulamos
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;

PRINT '--- FIN DE LA PRUEBA ---';
GO