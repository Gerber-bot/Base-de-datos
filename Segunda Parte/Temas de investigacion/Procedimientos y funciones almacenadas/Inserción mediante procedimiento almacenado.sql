USE Automotors;
GO


DECLARE @i INT = 1;
DECLARE @max INT = 5000;

WHILE (@i <= @max)
BEGIN
    DECLARE @dni VARCHAR(15) = RIGHT(CONCAT('00000000', CAST(40000000 + @i AS VARCHAR(15))), 8);
    DECLARE @nombre VARCHAR(50) = CONCAT('NombreProc', @i);
    DECLARE @apellido VARCHAR(50) = CONCAT('ApellidoProc', @i);
    DECLARE @telefono VARCHAR(30) = CONCAT('11', RIGHT(CONCAT('000000000', CAST(@i AS VARCHAR(15))), 8));
    DECLARE @email VARCHAR(100) = CONCAT('cliente_proc', @i, '@mail.com');
    DECLARE @direccion VARCHAR(150) = CONCAT('Dir ', @i);

    EXEC sp_InsertarCliente
        @dni = @dni,
        @nombre = @nombre,
        @apellido = @apellido,
        @telefono = @telefono,
        @email = @email,
        @direccion = @direccion;

    SET @i += 1;
END;
GO
