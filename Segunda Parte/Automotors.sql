DROP DATABASE IF EXISTS Automotors;
GO
CREATE DATABASE Automotors;
GO
USE Automotors;
GO


CREATE TABLE Rol (
    id_rol INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);
GO


CREATE TABLE Usuario (
    id_usuario INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    dni VARCHAR(15) NOT NULL UNIQUE,
    fecha_nacimiento DATE NOT NULL,
    password_hash VARBINARY(256) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    id_rol INT NOT NULL,
    is_activo BIT NOT NULL DEFAULT 1,
    creado_en DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Usuario_Rol FOREIGN KEY (id_rol)
        REFERENCES Rol(id_rol),

    CONSTRAINT CK_Usuario_DNI CHECK (
        dni NOT LIKE '%[^0-9]%' AND LEN(dni) BETWEEN 7 AND 9
    )
);
GO

CREATE TABLE Cliente (
    id_cliente INT IDENTITY(1,1) PRIMARY KEY,
    dni VARCHAR(15) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    telefono VARCHAR(30),
    email VARCHAR(100),
    direccion VARCHAR(150),

    CONSTRAINT CK_Cliente_DNI CHECK (
        dni NOT LIKE '%[^0-9]%' AND LEN(dni) BETWEEN 7 AND 9
    )
);
GO

CREATE TABLE Marca (
    id_marca INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(60) NOT NULL UNIQUE
);
GO

CREATE TABLE Vehiculo (
    id_vehiculo INT IDENTITY(1,1) PRIMARY KEY,
    id_marca INT NOT NULL,
    modelo VARCHAR(80) NOT NULL,
    anio INT NOT NULL,
    vin VARCHAR(40) NOT NULL UNIQUE,
    patente VARCHAR(10) UNIQUE,
    precio DECIMAL(12,2) NOT NULL,
    estado VARCHAR(20) NOT NULL,
    kilometraje INT NOT NULL DEFAULT 0,

    CONSTRAINT FK_Vehiculo_Marca FOREIGN KEY (id_marca)
        REFERENCES Marca(id_marca),

    CONSTRAINT CK_Vehiculo_Anio CHECK (anio BETWEEN 1900 AND YEAR(GETDATE()) + 1),

    CONSTRAINT CK_Vehiculo_Estado CHECK (estado IN ('disponible','reservado','vendido','baja')),

    CONSTRAINT CK_VIN_Longitud CHECK (LEN(vin) = 17),

    CONSTRAINT CK_Patente_Formato CHECK (
        patente IS NULL OR
        patente LIKE '[A-Z][A-Z][A-Z][0-9][0-9][0-9]' OR
        patente LIKE '[A-Z][A-Z][0-9][0-9][0-9][A-Z][A-Z]'
    ),

    CONSTRAINT CK_Precio_Pos CHECK (precio > 0),
    CONSTRAINT CK_Km CHECK (kilometraje >= 0)
);
GO

CREATE TABLE Proveedor (
    id_proveedor INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    telefono VARCHAR(30),
    email VARCHAR(100)
);
GO

CREATE TABLE Repuesto (
    id_repuesto INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL UNIQUE,
    precio DECIMAL(12,2) NOT NULL CHECK (precio >= 0),
    id_proveedor INT NOT NULL,

    CONSTRAINT FK_Repuesto_Proveedor FOREIGN KEY (id_proveedor)
        REFERENCES Proveedor(id_proveedor)
);
GO

CREATE TABLE MedioPago (
    id_medio_pago INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);
GO

CREATE TABLE Venta (
    id_venta INT IDENTITY(1,1) PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_usuario INT NOT NULL,
    fecha DATETIME2 NOT NULL,
    id_medio_pago INT NOT NULL,
    total DECIMAL(14,2) NOT NULL DEFAULT 0 CHECK (total >= 0),

    CONSTRAINT FK_Venta_Cliente FOREIGN KEY (id_cliente)
        REFERENCES Cliente(id_cliente),

    CONSTRAINT FK_Venta_Usuario FOREIGN KEY (id_usuario)
        REFERENCES Usuario(id_usuario),

    CONSTRAINT FK_Venta_MedioPago FOREIGN KEY (id_medio_pago)
        REFERENCES MedioPago(id_medio_pago)
);
GO

CREATE TABLE DetalleVenta (
    id_detalle INT IDENTITY(1,1) PRIMARY KEY,
    id_venta INT NOT NULL,
    id_vehiculo INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad = 1),
    precio_unit DECIMAL(12,2) NOT NULL CHECK (precio_unit > 0),

    subtotal AS (cantidad * precio_unit) PERSISTED,

    CONSTRAINT FK_DV_Venta FOREIGN KEY (id_venta)
        REFERENCES Venta(id_venta) ON DELETE CASCADE,

    CONSTRAINT FK_DV_Vehiculo FOREIGN KEY (id_vehiculo)
        REFERENCES Vehiculo(id_vehiculo)
);
GO

CREATE TABLE Turno (
    id_turno INT IDENTITY(1,1) PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_vehiculo INT NOT NULL,
    fecha_hora DATETIME2 NOT NULL,
    estado VARCHAR(20) NOT NULL CHECK (estado IN ('pendiente','realizado','cancelado')),
    notas VARCHAR(300),

    CONSTRAINT FK_Turno_Cliente FOREIGN KEY (id_cliente)
        REFERENCES Cliente(id_cliente),

    CONSTRAINT FK_Turno_Vehiculo FOREIGN KEY (id_vehiculo)
        REFERENCES Vehiculo(id_vehiculo)
);
GO

CREATE TABLE Reparacion (
    id_reparacion INT IDENTITY(1,1) PRIMARY KEY,
    id_vehiculo INT NOT NULL,
    id_cliente INT NOT NULL,
    id_usuario INT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NULL,
    estado VARCHAR(20) NOT NULL CHECK (estado IN ('pendiente','en_proceso','finalizada','cancelada')),
    total DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (total >= 0),

    CONSTRAINT FK_Rep_Vehiculo FOREIGN KEY (id_vehiculo)
        REFERENCES Vehiculo(id_vehiculo),

    CONSTRAINT FK_Rep_Cliente FOREIGN KEY (id_cliente)
        REFERENCES Cliente(id_cliente),

    CONSTRAINT FK_Rep_Usuario FOREIGN KEY (id_usuario)
        REFERENCES Usuario(id_usuario)
);
GO

CREATE TABLE ReparacionRepuesto (
    id_detalle INT IDENTITY(1,1) PRIMARY KEY,
    id_reparacion INT NOT NULL,
    id_repuesto INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unit DECIMAL(12,2) NOT NULL CHECK (precio_unit >= 0),

    subtotal AS (cantidad * precio_unit) PERSISTED,

    CONSTRAINT FK_RR_Reparacion FOREIGN KEY (id_reparacion)
        REFERENCES Reparacion(id_reparacion) ON DELETE CASCADE,

    CONSTRAINT FK_RR_Repuesto FOREIGN KEY (id_repuesto)
        REFERENCES Repuesto(id_repuesto)
);
GO
