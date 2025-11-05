USE Automotors;
GO

CREATE OR ALTER PROCEDURE dbo.sp_InsertarCliente
  @dni VARCHAR(15),
  @nombre VARCHAR(50),
  @apellido VARCHAR(50),
  @telefono VARCHAR(30) = NULL,
  @email VARCHAR(100) = NULL,
  @direccion VARCHAR(150) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO dbo.Cliente (dni, nombre, apellido, telefono, email, direccion)
  VALUES (@dni, @nombre, @apellido, @telefono, @email, @direccion);

  SELECT SCOPE_IDENTITY() AS id_insertado;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ModificarCliente
  @id_cliente INT,
  @telefono VARCHAR(30) = NULL,
  @email VARCHAR(100) = NULL,
  @direccion VARCHAR(150) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE dbo.Cliente
  SET telefono = @telefono,
      email = @email,
      direccion = @direccion
  WHERE id_cliente = @id_cliente;

  SELECT @@ROWCOUNT AS filas_afectadas;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_EliminarCliente
  @id_cliente INT
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM dbo.Cliente WHERE id_cliente = @id_cliente;
  SELECT @@ROWCOUNT AS filas_eliminadas;
END;
GO
