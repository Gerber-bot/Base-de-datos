/* =========================================================
   AUTOMOTORS - Esquema SQL Server (3FN + integridad + triggers)
   Versión corregida según Modelo/Diccionario del proyecto
   ========================================================= */

IF DB_ID(N'Automotors') IS NULL CREATE DATABASE Automotors;
GO
USE Automotors;
GO

/* Limpieza en orden de dependencias (triggers antes que tablas) */
IF OBJECT_ID('dbo.trg_RR_AIU_ReparacionesTotal','TR') IS NOT NULL DROP TRIGGER dbo.trg_RR_AIU_ReparacionesTotal;
IF OBJECT_ID('dbo.trg_DV_AIU_VentasTotal','TR')        IS NOT NULL DROP TRIGGER dbo.trg_DV_AIU_VentasTotal;
GO

IF OBJECT_ID('dbo.ReparacionRepuesto','U') IS NOT NULL DROP TABLE dbo.ReparacionRepuesto;
IF OBJECT_ID('dbo.Reparacion','U')        IS NOT NULL DROP TABLE dbo.Reparacion;
IF OBJECT_ID('dbo.Turno','U')             IS NOT NULL DROP TABLE dbo.Turno;
IF OBJECT_ID('dbo.DetalleVenta','U')      IS NOT NULL DROP TABLE dbo.DetalleVenta;
IF OBJECT_ID('dbo.Venta','U')             IS NOT NULL DROP TABLE dbo.Venta;
IF OBJECT_ID('dbo.Repuesto','U')          IS NOT NULL DROP TABLE dbo.Repuesto;
IF OBJECT_ID('dbo.Proveedor','U')         IS NOT NULL DROP TABLE dbo.Proveedor;
IF OBJECT_ID('dbo.Vehiculo','U')          IS NOT NULL DROP TABLE dbo.Vehiculo;
IF OBJECT_ID('dbo.Marca','U')             IS NOT NULL DROP TABLE dbo.Marca;
IF OBJECT_ID('dbo.Cliente','U')           IS NOT NULL DROP TABLE dbo.Cliente;
IF OBJECT_ID('dbo.Usuario','U')           IS NOT NULL DROP TABLE dbo.Usuario;
IF OBJECT_ID('dbo.Rol','U')               IS NOT NULL DROP TABLE dbo.Rol;
GO

/* =========================
   SISTEMA
   ========================= */

-- Roles (según diccionario)
CREATE TABLE dbo.Rol
(
    id_rol  INT IDENTITY(1,1) NOT NULL,
    nombre  VARCHAR(50)       NOT NULL,
    CONSTRAINT PK_Roles PRIMARY KEY (id_rol),
    CONSTRAINT UQ_Roles_nombre UNIQUE (nombre)
);

-- Usuarios (según diccionario)
CREATE TABLE dbo.Usuario
(
    id_usuario        INT IDENTITY(1,1) NOT NULL,
    nombre            VARCHAR(50)       NOT NULL,
    apellido          VARCHAR(50)       NOT NULL,
    dni               VARCHAR(15)       NOT NULL,
    fecha_nacimiento  DATE              NOT NULL,
    password_hash     VARBINARY(256)    NOT NULL,
    email             VARCHAR(100)      NOT NULL,
    id_rol            INT               NOT NULL,
    is_activo         BIT               NOT NULL CONSTRAINT DF_Usuario_IsActivo DEFAULT (1),
    creado_en         DATETIME2         NOT NULL CONSTRAINT DF_Usuario_CreadoEn DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_Usuario PRIMARY KEY (id_usuario),
    CONSTRAINT UQ_Usuario_email UNIQUE (email),
    CONSTRAINT UQ_Usuario_dni   UNIQUE (dni),
    CONSTRAINT FK_Usuario_Rol FOREIGN KEY (id_rol) REFERENCES dbo.Rol(id_rol)
);
-- (Seguridad app: opcionalmente agregar password_salt/algoritmo)

/* =========================
   MAESTROS (Ventas / Inventario)
   ========================= */

-- Clientes
CREATE TABLE dbo.Cliente
(
    id_cliente INT IDENTITY(1,1) NOT NULL,
    dni        VARCHAR(15)       NOT NULL,
    nombre     VARCHAR(50)       NOT NULL,
    apellido   VARCHAR(50)       NOT NULL,
    telefono   VARCHAR(30)       NULL,
    email      VARCHAR(100)      NULL,
    direccion  VARCHAR(150)      NULL,
    CONSTRAINT PK_Cliente PRIMARY KEY (id_cliente),
    CONSTRAINT UQ_Cliente_dni UNIQUE (dni)
    -- NOTA: email/telefono son opcionales → índices únicos filtrados más abajo
);

-- Marcas
CREATE TABLE dbo.Marca
(
    id_marca INT IDENTITY(1,1) NOT NULL,
    nombre   VARCHAR(60)       NOT NULL,
    CONSTRAINT PK_Marca PRIMARY KEY (id_marca),
    CONSTRAINT UQ_Marca_nombre UNIQUE (nombre)
);

-- Vehículos
CREATE TABLE dbo.Vehiculo
(
    id_vehiculo INT IDENTITY(1,1) NOT NULL,
    id_marca    INT               NOT NULL,
    modelo      VARCHAR(80)       NOT NULL,
    anio        INT               NOT NULL,
    vin         VARCHAR(40)       NOT NULL,
    patente     VARCHAR(10)       NOT NULL,
    precio      DECIMAL(12,2)     NOT NULL,
    stock       INT               NOT NULL,
    estado      VARCHAR(20)       NOT NULL,
    CONSTRAINT PK_Vehiculo PRIMARY KEY (id_vehiculo),
    CONSTRAINT UQ_Vehiculo_vin UNIQUE (vin),
    CONSTRAINT UQ_Vehiculo_patente UNIQUE (patente),
    CONSTRAINT FK_Vehiculo_Marca FOREIGN KEY (id_marca) REFERENCES dbo.Marca(id_marca),
    CONSTRAINT CK_Veh_Anio_Rango  CHECK (anio BETWEEN 1900 AND YEAR(GETDATE()) + 1),
    CONSTRAINT CK_Veh_Precio_Pos  CHECK (precio >= 0),
    CONSTRAINT CK_Veh_Stock_NoNeg CHECK (stock >= 0),
    CONSTRAINT CK_Vehiculo_Estado CHECK (estado IN ('disponible','reservado','vendido','baja')),
    CONSTRAINT CK_Vin_Longitud    CHECK (LEN(vin) = 17),
    CONSTRAINT CK_Patente_Formato CHECK (
        -- AAA123 o AA123AA (formatos AR comunes); si no usan patentes locales, comentar este CHECK
        (patente LIKE '[A-Z][A-Z][A-Z][0-9][0-9][0-9]') OR
        (patente LIKE '[A-Z][A-Z][0-9][0-9][0-9][A-Z][A-Z]')
    )
);

/* =========================
   PROVEEDORES / REPUESTOS
   ========================= */

-- Proveedores
CREATE TABLE dbo.Proveedor
(
    id_proveedor INT IDENTITY(1,1) NOT NULL,
    nombre       VARCHAR(100)      NOT NULL,
    telefono     VARCHAR(30)       NULL,
    email        VARCHAR(100)      NULL,
    CONSTRAINT PK_Proveedor PRIMARY KEY (id_proveedor),
    CONSTRAINT UQ_Proveedor_nombre UNIQUE (nombre)
    -- NOTA: email/telefono opcionales → índices únicos filtrados más abajo
);

-- Repuestos
CREATE TABLE dbo.Repuesto
(
    id_repuesto  INT IDENTITY(1,1) NOT NULL,
    nombre       VARCHAR(80)       NOT NULL,
    precio       DECIMAL(12,2)     NOT NULL,
    id_proveedor INT               NOT NULL,
    CONSTRAINT PK_Repuesto PRIMARY KEY (id_repuesto),
    CONSTRAINT UQ_Repuesto_nombre UNIQUE (nombre),
    CONSTRAINT FK_Repuesto_Proveedor FOREIGN KEY (id_proveedor) REFERENCES dbo.Proveedor(id_proveedor),
    CONSTRAINT CK_Rep_Precio_Pos CHECK (precio >= 0)
);

/* =========================
   VENTAS
   ========================= */

-- Ventas (total mantenido por trigger)
CREATE TABLE dbo.Venta
(
    id_venta    INT IDENTITY(1,1) NOT NULL,
    id_cliente  INT               NOT NULL,
    id_usuario  INT               NOT NULL,
    fecha       DATETIME2         NOT NULL,
    total       DECIMAL(14,2)     NOT NULL CONSTRAINT DF_Venta_Total DEFAULT (0),
    medio_pago  VARCHAR(30)       NOT NULL,
    CONSTRAINT PK_Venta PRIMARY KEY (id_venta),
    CONSTRAINT FK_Venta_Cliente FOREIGN KEY (id_cliente) REFERENCES dbo.Cliente(id_cliente),
    CONSTRAINT FK_Venta_Usuario FOREIGN KEY (id_usuario) REFERENCES dbo.Usuario(id_usuario),
    CONSTRAINT CK_Venta_Total_Pos CHECK (total >= 0),
    CONSTRAINT CK_Venta_Fecha CHECK (fecha BETWEEN '2000-01-01' AND DATEADD(year,1,GETDATE())),
    CONSTRAINT CK_Venta_MedioPago CHECK (medio_pago IN ('efectivo','tarjeta','transferencia','cheque'))
);

-- DetalleVenta (subtotal calculado y persistido)
CREATE TABLE dbo.DetalleVenta
(
    id_detalle  INT IDENTITY(1,1) NOT NULL,
    id_venta    INT               NOT NULL,
    id_vehiculo INT               NOT NULL,
    cantidad    INT               NOT NULL,
    precio_unit DECIMAL(12,2)     NOT NULL,
    subtotal    AS (cantidad * precio_unit) PERSISTED,
    CONSTRAINT PK_DetalleVenta PRIMARY KEY (id_detalle),
    CONSTRAINT FK_DV_Venta    FOREIGN KEY (id_venta)    REFERENCES dbo.Venta(id_venta) ON DELETE CASCADE,
    CONSTRAINT FK_DV_Vehiculo FOREIGN KEY (id_vehiculo) REFERENCES dbo.Vehiculo(id_vehiculo),
    CONSTRAINT CK_DV_Cantidad_Pos CHECK (cantidad > 0),
    CONSTRAINT CK_DV_Precio_Pos   CHECK (precio_unit >= 0)
);
-- Regla de negocio: un vehículo no debe repetirse en una misma venta
CREATE UNIQUE INDEX UQ_DV_Venta_Vehiculo ON dbo.DetalleVenta(id_venta, id_vehiculo);

/* =========================
   TALLER
   ========================= */

-- Turnos
CREATE TABLE dbo.Turno
(
    id_turno    INT IDENTITY(1,1) NOT NULL,
    id_cliente  INT               NOT NULL,
    id_vehiculo INT               NOT NULL,
    fecha_hora  DATETIME2         NOT NULL,
    estado      VARCHAR(20)       NOT NULL,
    notas       VARCHAR(300)      NULL,
    CONSTRAINT PK_Turno PRIMARY KEY (id_turno),
    CONSTRAINT FK_Turno_Cliente  FOREIGN KEY (id_cliente)  REFERENCES dbo.Cliente(id_cliente),
    CONSTRAINT FK_Turno_Vehiculo FOREIGN KEY (id_vehiculo) REFERENCES dbo.Vehiculo(id_vehiculo),
    CONSTRAINT CK_Turno_Estado   CHECK (estado IN ('pendiente','confirmado','atendido','cancelado')),
    CONSTRAINT CK_Turno_Fecha    CHECK (fecha_hora BETWEEN '2000-01-01' AND DATEADD(year,1,GETDATE()))
);

-- Reparaciones (total mantenido por trigger)
CREATE TABLE dbo.Reparacion
(
    id_reparacion INT IDENTITY(1,1) NOT NULL,
    id_vehiculo   INT               NOT NULL,
    id_cliente    INT               NOT NULL,
    id_usuario    INT               NOT NULL,
    fecha_inicio  DATE              NOT NULL,
    fecha_fin     DATE              NULL,
    estado        VARCHAR(20)       NOT NULL,
    total         DECIMAL(12,2)     NOT NULL CONSTRAINT DF_Reparacion_Total DEFAULT (0),
    CONSTRAINT PK_Reparacion PRIMARY KEY (id_reparacion),
    CONSTRAINT FK_Rep_Vehiculos FOREIGN KEY (id_vehiculo) REFERENCES dbo.Vehiculo(id_vehiculo),
    CONSTRAINT FK_Rep_Clientes  FOREIGN KEY (id_cliente)  REFERENCES dbo.Cliente(id_cliente),
    CONSTRAINT FK_Rep_Usuarios  FOREIGN KEY (id_usuario)  REFERENCES dbo.Usuario(id_usuario),
    CONSTRAINT CK_Rep_Total_Pos CHECK (total >= 0),
    CONSTRAINT CK_Rep_Fechas    CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
    CONSTRAINT CK_Rep_Estado    CHECK (estado IN ('pendiente','en_proceso','finalizada','cancelada'))
);

-- ReparacionRepuesto (subtotal calculado y persistido)
CREATE TABLE dbo.ReparacionRepuesto
(
    id_detalle     INT IDENTITY(1,1) NOT NULL,
    id_reparacion  INT               NOT NULL,
    id_repuesto    INT               NOT NULL,
    cantidad       INT               NOT NULL,
    precio_unit    DECIMAL(12,2)     NOT NULL,
    subtotal       AS (cantidad * precio_unit) PERSISTED,
    CONSTRAINT PK_ReparacionRepuesto PRIMARY KEY (id_detalle),
    CONSTRAINT FK_RR_Reparacion FOREIGN KEY (id_reparacion) REFERENCES dbo.Reparacion(id_reparacion) ON DELETE CASCADE,
    CONSTRAINT FK_RR_Repuesto    FOREIGN KEY (id_repuesto)    REFERENCES dbo.Repuesto(id_repuesto),
    CONSTRAINT CK_RR_Cantidad_Pos CHECK (cantidad > 0),
    CONSTRAINT CK_RR_Precio_Pos   CHECK (precio_unit >= 0)
);
-- Regla: un repuesto no debe repetirse en una misma reparación
CREATE UNIQUE INDEX UQ_RR_Rep_Repuesto ON dbo.ReparacionRepuesto(id_reparacion, id_repuesto);
GO

/* =========================
   ÍNDICES (consultas/reportes típicos + FKs)
   ========================= */
-- Filtros por fecha / joins frecuentes
CREATE INDEX IX_Ventas_Fecha              ON dbo.Venta(fecha);
CREATE INDEX IX_DV_Venta                  ON dbo.DetalleVenta(id_venta);
CREATE INDEX IX_Turnos_FechaHora          ON dbo.Turno(fecha_hora);
CREATE INDEX IX_Reparaciones_FechaIni     ON dbo.Reparacion(fecha_inicio);
CREATE INDEX IX_RR_Reparacion             ON dbo.ReparacionRepuesto(id_reparacion);
CREATE INDEX IX_Repuestos_Proveedor       ON dbo.Repuesto(id_proveedor);
CREATE INDEX IX_Vehiculos_MarcaModeloAnio ON dbo.Vehiculo(id_marca, modelo, anio);
CREATE INDEX IX_Vehiculos_Estado          ON dbo.Vehiculo(estado);

-- Índices para FKs de acceso y reportes
CREATE INDEX IX_Venta_IdCliente   ON dbo.Venta(id_cliente);
CREATE INDEX IX_Venta_IdUsuario   ON dbo.Venta(id_usuario);
CREATE INDEX IX_Turno_IdCliente   ON dbo.Turno(id_cliente);
CREATE INDEX IX_Turno_IdVehiculo  ON dbo.Turno(id_vehiculo);
CREATE INDEX IX_Rep_IdCliente     ON dbo.Reparacion(id_cliente);
CREATE INDEX IX_Rep_IdVehiculo    ON dbo.Reparacion(id_vehiculo);
CREATE INDEX IX_Rep_IdUsuario     ON dbo.Reparacion(id_usuario);
CREATE INDEX IX_Repuesto_IdProv   ON dbo.Repuesto(id_proveedor);

-- Únicos filtrados para campos opcionales (varios NULL permitidos)
CREATE UNIQUE INDEX UQ_Cliente_email    ON dbo.Cliente(email)     WHERE email    IS NOT NULL;
CREATE UNIQUE INDEX UQ_Cliente_telefono ON dbo.Cliente(telefono)  WHERE telefono IS NOT NULL;
CREATE UNIQUE INDEX UQ_Proveedor_email  ON dbo.Proveedor(email)   WHERE email    IS NOT NULL;
CREATE UNIQUE INDEX UQ_Proveedor_tel    ON dbo.Proveedor(telefono)WHERE telefono IS NOT NULL;

-- Sanitizado básico de DNI (solo dígitos y rango típico AR)
ALTER TABLE dbo.Cliente
  ADD CONSTRAINT CK_Cliente_DNI_Formato CHECK (dni NOT LIKE '%[^0-9]%' AND LEN(dni) BETWEEN 7 AND 9);
ALTER TABLE dbo.Usuario
  ADD CONSTRAINT CK_Usuario_DNI_Formato CHECK (dni NOT LIKE '%[^0-9]%' AND LEN(dni) BETWEEN 7 AND 9);
GO

/* =========================
   TRIGGERS de consistencia (CORREGIDOS: Usan Tablas Temporales)
   ========================= */

-- Recalcula Ventas.total ante inserción/actualización/borrado en DetalleVenta
CREATE TRIGGER dbo.trg_DV_AIU_VentasTotal
ON dbo.DetalleVenta
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Usamos una tabla temporal (#Afectadas) que persiste
    -- durante todo el trigger, en lugar de una CTE (WITH).
    SELECT id_venta
    INTO #Afectadas
    FROM inserted
    UNION
    SELECT id_venta FROM deleted;

    -- Statement 1: Actualiza totales de ventas con detalles
    UPDATE v
      SET v.total = ISNULL(x.suma, 0)
    FROM dbo.Venta v
    JOIN (
        SELECT dv.id_venta, SUM(dv.subtotal) AS suma
        FROM dbo.DetalleVenta dv
        JOIN #Afectadas a ON a.id_venta = dv.id_venta
        GROUP BY dv.id_venta
    ) AS x ON x.id_venta = v.id_venta
    WHERE v.id_venta IN (SELECT id_venta FROM #Afectadas);

    -- Statement 2: Actualiza a 0 ventas que quedaron sin detalles
    -- (Ahora #Afectadas SÍ existe para esta sentencia)
    UPDATE v
      SET v.total = 0
    FROM dbo.Venta v
    WHERE v.id_venta IN (SELECT id_venta FROM #Afectadas)
      AND NOT EXISTS (SELECT 1 FROM dbo.DetalleVenta dv WHERE dv.id_venta = v.id_venta);

    -- Limpiamos la tabla temporal
    DROP TABLE #Afectadas;
END;
GO

-- Recalcula Reparaciones.total ante inserción/actualización/borrado en ReparacionRepuesto
CREATE TRIGGER dbo.trg_RR_AIU_ReparacionesTotal
ON dbo.ReparacionRepuesto
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Usamos una tabla temporal
    SELECT id_reparacion
    INTO #AfectadasRep
    FROM inserted
    UNION
    SELECT id_reparacion FROM deleted;

    -- Statement 1: Actualiza totales
    UPDATE r
      SET r.total = ISNULL(x.suma, 0)
    FROM dbo.Reparacion r
    JOIN (
        SELECT rr.id_reparacion, SUM(rr.subtotal) AS suma
        FROM dbo.ReparacionRepuesto rr
        JOIN #AfectadasRep a ON a.id_reparacion = rr.id_reparacion
        GROUP BY rr.id_reparacion
    ) AS x ON x.id_reparacion = r.id_reparacion
    WHERE r.id_reparacion IN (SELECT id_reparacion FROM #AfectadasRep);

    -- Statement 2: Actualiza a 0
    UPDATE r
      SET r.total = 0
    FROM dbo.Reparacion r
    WHERE r.id_reparacion IN (SELECT id_reparacion FROM #AfectadasRep)
      AND NOT EXISTS (SELECT 1 FROM dbo.ReparacionRepuesto rr WHERE rr.id_reparacion = r.id_reparacion);

    -- Limpiamos la tabla temporal
    DROP TABLE #AfectadasRep;
END;
GO

/* =========================
   Vistas de control (auditoría de totales)
   ========================= */
CREATE OR ALTER VIEW dbo.VentasConTotalCalc AS
SELECT v.*,
       (SELECT ISNULL(SUM(dv.subtotal),0) FROM dbo.DetalleVenta dv WHERE dv.id_venta = v.id_venta) AS total_calc
FROM dbo.Venta v;
GO

CREATE OR ALTER VIEW dbo.ReparacionesConTotalCalc AS
SELECT r.*,
       (SELECT ISNULL(SUM(rr.subtotal),0) FROM dbo.ReparacionRepuesto rr WHERE rr.id_reparacion = r.id_reparacion) AS total_calc
FROM dbo.Reparacion r;
GO
