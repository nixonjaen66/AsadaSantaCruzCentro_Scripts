--Creaci�n de la base de datos

USE master
IF DB_ID('ASADA_SC') IS NOT NULL
BEGIN 
DROP DATABASE ASADA_SC
END
GO
CREATE DATABASE ASADA_SC
ON PRIMARY
(
  NAME = ASADA_SC_Data,
  FILENAME = 'C:\SqlData\ASADA_SC_Data.mdf',
  SIZE = 4GB,
  MAXSIZE = 7GB,
  FILEGROWTH = 1GB
)
LOG ON
(
  NAME = ASADA_SC_Log,
  FILENAME = 'C:\SQLlog\ASADA_SC_Log.ldf',
  SIZE = 800MB,
  MAXSIZE = 3GB,
  FILEGROWTH = 200MB
)
GO

EXEC sp_helpdb ASADA_SC
GO

--Creaci�n de Auditorias

USE master
GO
ALTER DATABASE ASADA_SC ADD FILEGROUP Operativo;
GO
ALTER DATABASE  ASADA_SC ADD FILEGROUP Historico;
GO
ALTER DATABASE  ASADA_SC ADD FILEGROUP Auditorias;
GO


--Tama�o de los filegroup

ALTER DATABASE ASADA_SC
ADD FILE
(
  NAME = 'Operativo_Data',
  FILENAME = 'C:\SqlData\Operativo_Data.ndf',
  SIZE = 200MB,
  MAXSIZE = 1GB,
  FILEGROWTH = 100MB
)TO FILEGROUP Operativo
go

exec sp_helpfilegroup Operativo
go


ALTER DATABASE ASADA_SC
ADD FILE
(
  NAME = 'Auditorias_Data',
  FILENAME = 'C:\SqlData\Auditorias_Data.ndf',
  SIZE = 200MB,
  MAXSIZE = 1GB,
  FILEGROWTH = 100MB
)TO FILEGROUP Auditorias
go

exec sp_helpfilegroup Auditorias
go


ALTER DATABASE ASADA_SC
ADD FILE
(
  NAME = 'Historico_Data',
  FILENAME = 'C:\SqlData\Historico_Data.ndf',
  SIZE = 100MB,
  MAXSIZE = 800MB,
  FILEGROWTH = 50MB
)TO FILEGROUP Historico
go

exec sp_helpfilegroup Historico
go

--Creaci�n de tablas 

use ASADA_SC
go

CREATE TABLE TipoConexion(
    id_tipoConexion     INT IDENTITY(1,1) NOT NULL,
    nombre              VARCHAR(20) NOT NULL,
    estado              BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_TipoConexion PRIMARY KEY (id_tipoConexion),
    CONSTRAINT UQ_TipoConexion_nombre UNIQUE(nombre)
) 
GO
EXECUTE sp_help TipoConexion
GO

CREATE TABLE Periodo(
    id_periodo  INT IDENTITY(1,1) NOT NULL,
    anio        INT NOT NULL,
    mes         INT NOT NULL,
    fecha_corte DATETIME NULL,
    CONSTRAINT PK_Periodo PRIMARY KEY (id_periodo),
    CONSTRAINT CK_Periodo_mes CHECK (mes BETWEEN 1 AND 12),
    CONSTRAINT UQ_Periodo_anio_mes UNIQUE (anio, mes)
) 
GO
EXECUTE sp_help Periodo
GO

CREATE TABLE Abonado(
    id_abonado   INT IDENTITY(1,1) NOT NULL,
    nombre       VARCHAR(50) NOT NULL,
    ape1         VARCHAR(20) NOT NULL,
    ape2         VARCHAR(20) NULL,
    direccion    VARCHAR(255) NOT NULL,
    telefono     VARCHAR(20) NULL,
    fecha_inicio DATETIME NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Abonado PRIMARY KEY (id_abonado),

) 
GO
EXECUTE sp_help Abonado
GO

CREATE TABLE Empleado(
    id_empleado        INT IDENTITY(1,1) NOT NULL,
    nombre             VARCHAR(50) NOT NULL,
    ape1               VARCHAR(20) NOT NULL,
    ape2               VARCHAR(20) NULL,
    telefono           VARCHAR(20) NULL,
    correo_electronico VARCHAR(100) NULL,
    CONSTRAINT PK_Empleado PRIMARY KEY (id_empleado),
    CONSTRAINT UQ_Empleado_correo UNIQUE (correo_electronico)
) 
GO
EXECUTE sp_help Empleado
GO

CREATE TABLE Conexion(
    id_conexion         INT IDENTITY(1,1) NOT NULL,
    nis                  VARCHAR(10) NOT NULL,
    direccion_servicio  VARCHAR(255) NOT NULL,
    fecha_ini           DATETIME NOT NULL DEFAULT SYSUTCDATETIME(),
    fecha_fin           DATETIME NULL,
    id_abonado          INT NOT NULL,
    id_tipoConexion     INT NOT NULL,
    CONSTRAINT PK_Conexion PRIMARY KEY (id_conexion),
    CONSTRAINT UQ_Conexion_nis UNIQUE (nis),
    CONSTRAINT FK_Conexion_Abonado FOREIGN KEY (id_abonado) REFERENCES Abonado(id_abonado),
    CONSTRAINT FK_Conexion_TipoConexion FOREIGN KEY (id_tipoConexion) REFERENCES TipoConexion(id_tipoConexion)
) ON Operativo
GO
EXECUTE sp_help Conexion
GO

CREATE TABLE Medidor(
    id_medidor  INT IDENTITY(1,1) NOT NULL,
    serial      VARCHAR(10) NOT NULL,
    estado      BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Medidor PRIMARY KEY (id_medidor),
    CONSTRAINT UQ_Medidor_serial UNIQUE(serial)
) ON Operativo
GO
EXECUTE sp_help Medidor
GO

CREATE TABLE Tarifa(
    id_tarifa        INT IDENTITY(1,1) NOT NULL,
    tipo_tarifa     TEXT NOT NULL,            -- residencial, comercial, industrial
    cargo_fijo       DECIMAL(12,2) NOT NULL,
    fecha_ini        DATETIME NOT NULL,
    fecha_fin        DATETIME NULL,
    id_tipoConexion  INT NOT NULL,                    -- relaci�n con Tipo de Conexi�n
    CONSTRAINT PK_Tarifa PRIMARY KEY (id_tarifa),
    CONSTRAINT FK_Tarifa_TipoConexion FOREIGN KEY (id_tipoConexion) REFERENCES TipoConexion(id_tipoConexion)
) ON Operativo
GO
EXECUTE sp_help Tarifa
GO

CREATE TABLE TarifaTramo(
    id_tramo INT IDENTITY(1,1) NOT NULL,
    id_tarifa INT NOT NULL,
    desde_m3 INT NULL,
    hasta_m3 INT NULL,
    precio_m3 DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_TarifaTramo PRIMARY KEY (id_tramo),
    CONSTRAINT FK_TarifaTramo_Tarifa FOREIGN KEY (id_tarifa) REFERENCES Tarifa(id_tarifa)
) ON Operativo
GO
EXECUTE sp_help TarifaTramo
GO

CREATE TABLE Lectura(
    id_lectura       INT IDENTITY(1,1) NOT NULL,
    id_medidor       INT NOT NULL,
    id_periodo       INT NOT NULL,
    lectura_anterior DECIMAL(12,2) NOT NULL,
    lectura_actual   DECIMAL(12,2) NOT NULL,
    fecha_lectura    DATETIME NOT NULL DEFAULT SYSUTCDATETIME(),
    id_empleado      INT  NOT NULL,                -- responsable de la lectura
    CONSTRAINT PK_Lectura PRIMARY KEY (id_lectura),
    CONSTRAINT FK_Lectura_Medidor   FOREIGN KEY (id_medidor)  REFERENCES Medidor(id_medidor),
    CONSTRAINT FK_Lectura_Periodo   FOREIGN KEY (id_periodo)  REFERENCES Periodo(id_periodo),
    CONSTRAINT FK_Lectura_Empleado  FOREIGN KEY (id_empleado) REFERENCES Empleado(id_empleado)
) ON Operativo
GO
EXECUTE sp_help Lectura
GO

CREATE TABLE Factura(
    id_factura        INT IDENTITY(1,1) NOT NULL,
	 id_abonado          INT NOT NULL,
    id_conexion       INT NOT NULL,
    id_lectura        INT NOT NULL,
    id_tarifa         INT NOT NULL, -- la tarifa aplicada en el momento de la facturaci�n
    fecha_emision     DATETIME NOT NULL DEFAULT SYSUTCDATETIME(),
    fecha_vencimiento DATETIME NOT NULL,
    CONSTRAINT PK_Factura PRIMARY KEY (id_factura),
	 CONSTRAINT FK_Factura_Abonado FOREIGN KEY (id_abonado) REFERENCES Abonado(id_abonado),
    CONSTRAINT FK_Factura_Conexion FOREIGN KEY (id_conexion) REFERENCES Conexion(id_conexion),
    CONSTRAINT FK_Factura_Lectura  FOREIGN KEY (id_lectura)  REFERENCES Lectura(id_lectura),
    CONSTRAINT FK_Factura_Tarifa   FOREIGN KEY (id_tarifa)   REFERENCES Tarifa(id_tarifa)
) ON Operativo
GO
EXECUTE sp_help Factura
GO

CREATE TABLE Pago(
    id_pago      INT IDENTITY(1,1) NOT NULL,
    id_factura   INT NOT NULL,
    monto_pagado DECIMAL(12,2) NOT NULL,
    fecha_pago   DATETIME NOT NULL DEFAULT SYSUTCDATETIME(),
    recargo_mora DECIMAL(12,2) NOT NULL DEFAULT 0,
    CONSTRAINT PK_Pago PRIMARY KEY (id_pago),
    CONSTRAINT FK_Pago_Factura FOREIGN KEY (id_factura) REFERENCES Factura(id_factura)
) ON Operativo
GO
EXECUTE sp_help Pago

CREATE TABLE Mantenimientos(
    id_mantenimiento INT IDENTITY(1,1) NOT NULL,
    fecha_mantenimiento DATETIME NOT NULL DEFAULT SYSUTCDATETIME(),
    ubicacion          VARCHAR(255) NULL,
    estado             BIT NOT NULL DEFAULT 1,
    id_conexion        INT NULL,
    id_empleado        INT NULL,   -- responsable
    CONSTRAINT PK_Mantenimientos PRIMARY KEY (id_mantenimiento),
    CONSTRAINT FK_Mant_Conexion FOREIGN KEY (id_conexion) REFERENCES Conexion(id_conexion),
    CONSTRAINT FK_Mant_Empleado FOREIGN KEY (id_empleado) REFERENCES Empleado(id_empleado)
) ON Operativo
GO
EXECUTE sp_help Mantenimientos
GO

/* ---- Tablas hist�ricas / auditor�a: ON Historico ---- */
CREATE TABLE MedidorHistorico(
    id_medidor_historico INT IDENTITY(1,1) NOT NULL,
    id_medidor           INT NOT NULL,
    id_conexion          INT NOT NULL,
    fecha_instalacion    DATETIME  NOT NULL,
    fecha_retiro         DATETIME NULL,
    lectura_inicial      DECIMAL(12,2)  NOT NULL,
    lectura_final        DECIMAL(12,2) NULL,
    CONSTRAINT PK_MedidorHistorico PRIMARY KEY (id_medidor_historico),
    CONSTRAINT FK_MedHist_Medidor  FOREIGN KEY (id_medidor)  REFERENCES Medidor(id_medidor),
    CONSTRAINT FK_MedHist_Conexion FOREIGN KEY (id_conexion) REFERENCES Conexion(id_conexion)
) ON Historico
GO
EXECUTE sp_help MedidorHistorico
GO

CREATE TABLE DetalleMantenimiento(
    id_detalle          INT IDENTITY(1,1) NOT NULL,
    id_mantenimiento    INT NOT NULL,
    descripcion_trabajo VARCHAR(255) NOT NULL,
    id_empleado         INT  NOT NULL,  -- quien realiz�
    CONSTRAINT PK_DetalleMantenimiento PRIMARY KEY (id_detalle),
    CONSTRAINT FK_DetMant_Mant FOREIGN KEY (id_mantenimiento) REFERENCES Mantenimientos(id_mantenimiento),
    CONSTRAINT FK_DetMant_Empleado FOREIGN KEY (id_empleado) REFERENCES Empleado(id_empleado)
) ON Historico
GO
EXECUTE sp_help DetalleMantenimiento
GO


--Tablas de Auditoria


USE ASADA_SC
GO


CREATE TABLE Audit_Abonado (
  IdAudit           INT IDENTITY(1,1) PRIMARY KEY,
  NombreTabla       VARCHAR(30)   NOT NULL,   -- 'Abonado'
  Operacion         VARCHAR(10)   NOT NULL,   -- INSERT/UPDATE/DELETE
  IdAbonado         INT,
  Nombre            VARCHAR(50),
  Ape1              VARCHAR(20),
  Ape2              VARCHAR(20),
  Direccion         VARCHAR(255),
  Telefono          VARCHAR(20),
  Correo            VARCHAR(100),
  Estado            BIT,
  RealizadoPor      VARCHAR(100)  NULL,
  FechaDeEjecucion  DATETIME    NOT NULL DEFAULT SYSUTCDATETIME()
) ON Auditorias
GO



CREATE TABLE Audit_Conexion (
  IdAudit           INT IDENTITY(1,1) PRIMARY KEY,
  NombreTabla       VARCHAR(30) NOT NULL,     -- 'Conexion'
  Operacion         VARCHAR(10) NOT NULL,
  IdConexion        INT,
  NIS               VARCHAR(10),
  IdAbonado         INT,
  IdTipoConexion    INT,
  DireccionServicio VARCHAR(255),
  FechaIni          DATETIME,
  FechaFin          DATETIME,
  Estado            BIT,
  RealizadoPor      VARCHAR(100) NULL,
  FechaDeEjecucion  DATETIME2    NOT NULL DEFAULT SYSUTCDATETIME()
) ON Auditorias
GO


CREATE TABLE Audit_Lectura (
  IdAudit           INT IDENTITY(1,1) PRIMARY KEY,
  NombreTabla       VARCHAR(30) NOT NULL,     -- 'Lectura'
  Operacion         VARCHAR(10) NOT NULL,
  IdLectura         INT,
  IdConexion        INT,
  IdMedidor         INT,
  IdPeriodo         INT,
  LecturaAnterior   DECIMAL(12,2),
  LecturaActual     DECIMAL(12,2),
  FechaLectura      DATETIME2,
  IdEmpleado        INT,
  Observacion       VARCHAR(200),
  RealizadoPor      VARCHAR(100) NULL,
  FechaDeEjecucion  DATETIME2    NOT NULL DEFAULT SYSUTCDATETIME()
) ON Auditorias
GO


CREATE TABLE Audit_Factura (
  IdAudit            INT IDENTITY(1,1) PRIMARY KEY,
  NombreTabla        VARCHAR(30) NOT NULL,    -- 'Factura'
  Operacion          VARCHAR(10) NOT NULL,
  IdFactura          INT,
  IdConexion         INT,
  IdLectura          INT,
  IdTarifa           INT,
  Consumo_m3         DECIMAL(12,2),
  MontoTotal         DECIMAL(12,2),
  Estado            BIT,
  FechaEmision       DATETIME,
  FechaVencimiento   DATETIME,
  RealizadoPor       VARCHAR(100) NULL,
  FechaDeEjecucion   DATETIME   NOT NULL DEFAULT SYSUTCDATETIME()
) ON Auditorias
GO


CREATE TABLE Audit_Pago (
  IdAudit           INT IDENTITY(1,1) PRIMARY KEY,
  NombreTabla       VARCHAR(30) NOT NULL,     -- 'Pago'
  Operacion         VARCHAR(10) NOT NULL,
  IdPago            INT,
  IdFactura         INT,
  MontoPagado       DECIMAL(12,2),
  FechaPago         DATETIME,
  Metodo            VARCHAR(50),
  RecargoMora       DECIMAL(12,2),
  RealizadoPor      VARCHAR(100) NULL,
  FechaDeEjecucion  DATETIME    NOT NULL DEFAULT SYSUTCDATETIME()
) ON Auditorias
GO

CREATE TABLE Audit_Tarifa (
  IdAudit           INT IDENTITY(1,1) PRIMARY KEY,
  NombreTabla       VARCHAR(30) NOT NULL,     -- 'Tarifa'
  Operacion         VARCHAR(10) NOT NULL,
  IdTarifa          INT,
  TipoTarifa        VARCHAR(40),
  IdTipoConexion    INT,
  CargoFijo         DECIMAL(12,2),
  FechaIni          DATETIME,
  FechaFin          DATETIME,
  Estado            BIT,
  RealizadoPor      VARCHAR(100) NULL,
  FechaDeEjecucion  DATETIME   NOT NULL DEFAULT SYSUTCDATETIME()
) ON Auditorias
GO

CREATE TABLE Audit_TarifaTramo (
  IdAudit           INT IDENTITY(1,1) PRIMARY KEY,
  NombreTabla       VARCHAR(30) NOT NULL,     -- 'TarifaTramo'
  Operacion         VARCHAR(10) NOT NULL,
  IdTramo           INT,
  IdTarifa          INT,
  Desde_m3          DECIMAL(12,2),
  Hasta_m3          DECIMAL(12,2),
  Precio_m3         DECIMAL(12,4),
  RealizadoPor      VARCHAR(100) NULL,
  FechaDeEjecucion  DATETIME    NOT NULL DEFAULT SYSUTCDATETIME()
) ON Auditorias
GO


CREATE TABLE Audit_Mantenimientos (
  IdAudit              INT IDENTITY(1,1) PRIMARY KEY,
  NombreTabla          VARCHAR(30) NOT NULL,  -- 'Mantenimientos'
  Operacion            VARCHAR(10) NOT NULL,
  IdMantenimiento      INT,
  TipoMantenimiento    VARCHAR(60),
  FechaMantenimiento   DATETIME2,
  Ubicacion            VARCHAR(255),
  IdMedidor            INT,
  IdConexion           INT,
  IdEmpleado           INT,
  Estado               BIT,
  RealizadoPor         VARCHAR(100) NULL,
  FechaDeEjecucion     DATETIME  NOT NULL DEFAULT SYSUTCDATETIME()
) ON Auditorias
GO


CREATE TABLE Audit_DetalleMantenimiento (
  IdAudit             INT IDENTITY(1,1) PRIMARY KEY,
  NombreTabla         VARCHAR(30) NOT NULL,   -- 'DetalleMantenimiento'
  Operacion           VARCHAR(10) NOT NULL,
  IdDetalle           INT,
  IdMantenimiento     INT,
  DescripcionTrabajo  VARCHAR(255),
  Costo               DECIMAL(12,2),
  IdEmpleado          INT,
  FechaRealizacion    DATETIME,
  RealizadoPor        VARCHAR(100) NULL,
  FechaDeEjecucion    DATETIME   NOT NULL DEFAULT SYSUTCDATETIME()
) ON Auditorias
GO


CREATE TABLE Audit_Empleado (
  IdAudit       INT IDENTITY(1,1) PRIMARY KEY,
  NombreTabla      VARCHAR(30) NOT NULL,      
  Operacion        VARCHAR(10) NOT NULL,
  IdEmpleado       INT,
  Nombre           VARCHAR(50),
  Ape1             VARCHAR(20),
  Ape2             VARCHAR(20),
  Telefono         VARCHAR(20),
  Correo           VARCHAR(100),
  Estado           BIT,
  RealizadoPor     VARCHAR(100) NULL,
  FechaDeEjecucion DATETIME   NOT NULL DEFAULT SYSUTCDATETIME()
) ON Auditorias
GO

CREATE OR ALTER PROCEDURE dbo.sp_actualizarAbonado
  @id_abonado INT,
  @direccion  VARCHAR(255),
  @telefono   VARCHAR(20)
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE dbo.Abonado
  SET direccion = @direccion,
      telefono  = @telefono
  WHERE id_abonado = @id_abonado;
END;
GO




-- Evitar borrado si tiene facturas
CREATE OR ALTER TRIGGER dbo.trg_no_delete_abonado_con_facturas
ON dbo.Abonado
INSTEAD OF DELETE
AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (
    SELECT 1
      FROM deleted d
      JOIN dbo.Factura f ON f.id_abonado = d.id_abonado
  )
  BEGIN
    RAISERROR('No se puede eliminar el abonado: posee facturas.',16,1);
    RETURN;
  END;

  DELETE a
    FROM dbo.Abonado a
    JOIN deleted d ON d.id_abonado = a.id_abonado;
END;
GO


--Insert Abonado (Daniel) 

USE ASADA_SC;
GO

IF OBJECT_ID('dbo.CrearAbonado', 'P') IS NOT NULL
    DROP PROCEDURE dbo.CrearAbonado;
GO

CREATE PROCEDURE dbo.CrearAbonado
    @cedula VARCHAR(20),
    @nombre VARCHAR(50),
    @ape1 VARCHAR(20),
    @ape2 VARCHAR(20) = NULL,
    @direccion VARCHAR(255),
    @telefono VARCHAR(20) = NULL,
    @correo_electronico VARCHAR(100) = NULL,
    @contrasena VARCHAR(255),
    @rol VARCHAR(20) = 'Abonado'
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar cédula única
    IF EXISTS (SELECT 1 FROM Abonado WHERE cedula = @cedula)
    BEGIN
        RAISERROR('El abonado con cédula %s ya existe.', 16, 1, @cedula);
        RETURN;
    END

    -- Validar correo único
    IF @correo_electronico IS NOT NULL AND EXISTS (SELECT 1 FROM Abonado WHERE correo_electronico = @correo_electronico)
    BEGIN
        RAISERROR('El correo electrónico %s ya está en uso.', 16, 1, @correo_electronico);
        RETURN;
    END

    INSERT INTO Abonado (cedula, nombre, ape1, ape2, direccion, telefono, correo_electronico, contrasena, rol, fecha_inicio)
    VALUES (@cedula, @nombre, @ape1, @ape2, @direccion, @telefono, @correo_electronico, @contrasena, @rol, SYSDATETIME());
END
GO

-- Insert tipo de conexi�n (Daniel)

CREATE PROCEDURE AgregarTipoConexion
    @nombre VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM TipoConexion WHERE nombre = @nombre)
    BEGIN
        RAISERROR('El nombre del TipoConexion ya existe', 16, 1);
        RETURN;
    END

    INSERT INTO TipoConexion (nombre, estado)
    VALUES (@nombre, 1);


    SELECT SCOPE_IDENTITY() AS idTipoConexion;
END
GO

-- Update tipo de conexi�n (Daniel)

CREATE PROCEDURE ActualizarTipoConexion
    @idTipoConexion INT,
    @nuevoNombre VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM TipoConexion WHERE id_tipoConexion = @idTipoConexion)
    BEGIN
        RAISERROR('El TipoConexion con ese ID no existe', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM TipoConexion WHERE nombre = @nuevoNombre AND id_tipoConexion <> @idTipoConexion)
    BEGIN
        RAISERROR('El nombre del TipoConexion ya existe', 16, 1);
        RETURN;
    END

    UPDATE TipoConexion
    SET nombre = @nuevoNombre
    WHERE id_tipoConexion = @idTipoConexion;

    SELECT id_tipoConexion, nombre 
    FROM TipoConexion 
    WHERE id_tipoConexion = @idTipoConexion;
END
GO

-- Update estado tipo de conexi�n (Daniel)

CREATE PROCEDURE ActualizarEstadoTipoConexion
    @idTipoConexion INT,
    @nuevoEstado BIT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM TipoConexion WHERE id_tipoConexion = @idTipoConexion)
    BEGIN
        RAISERROR('El TipoConexion con ese ID no existe', 16, 1);
        RETURN;
    END

    UPDATE TipoConexion
    SET estado = @nuevoEstado
    WHERE id_tipoConexion = @idTipoConexion;

END
GO

-- Insert empeleado (Daniel)

CREATE PROCEDURE [dbo].[CrearEmpleado]
    @cedula VARCHAR(20),
    @nombre VARCHAR(50),
    @ape1 VARCHAR(20),
    @ape2 VARCHAR(20) = NULL,
    @telefono VARCHAR(20) = NULL,
    @correo_electronico VARCHAR(100) = NULL,
    @contrasena VARCHAR(255),
    @rol VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    -- Verificar cédula única
    IF EXISTS (SELECT 1 FROM Empleado WHERE cedula = @cedula)
    BEGIN
        RAISERROR('El empleado con cédula ya existe', 16, 1);
        RETURN;
    END

    -- Verificar correo único
    IF @correo_electronico IS NOT NULL AND EXISTS (SELECT 1 FROM Empleado WHERE correo_electronico = @correo_electronico)
    BEGIN
        RAISERROR('El correo electrónico ya está en uso', 16, 1);
        RETURN;
    END

    -- Insertar empleado
    INSERT INTO Empleado (cedula, nombre, ape1, ape2, telefono, correo_electronico, contrasena, rol)
    VALUES (@cedula, @nombre, @ape1, @ape2, @telefono, @correo_electronico, @contrasena, @rol);
END
GO


-- Auditoría abonado
CREATE OR ALTER TRIGGER dbo.trg_auditoriaAbonado
ON dbo.Abonado
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
  SET NOCOUNT ON;

  /* ============== INSERT ============== */
  INSERT INTO dbo.Audit_Abonado
  (
      NombreTabla, Operacion, IdAbonado,
      Nombre, Ape1, Ape2, Direccion, Telefono,
      Correo,  -- en Abonado no existe -> guardamos NULL
      Estado,  -- en Abonado no existe -> guardamos NULL
      RealizadoPor
      -- FechaDeEjecucion usa DEFAULT (SYSUTCDATETIME())
  )
  SELECT
      'Abonado'       AS NombreTabla,
      'INSERT'        AS Operacion,
      i.id_abonado,
      i.nombre,
      i.ape1,
      i.ape2,
      i.direccion,
      i.telefono,
      NULL            AS Correo,     -- <--- reemplaza por i.correo_electronico si existe
      NULL            AS Estado,     -- <--- reemplaza por i.estado si existe
      SYSTEM_USER     AS RealizadoPor
  FROM inserted i
  LEFT JOIN deleted d
    ON d.id_abonado = i.id_abonado
  WHERE d.id_abonado IS NULL;

  /* ============== UPDATE ============== */
  INSERT INTO dbo.Audit_Abonado
  (
      NombreTabla, Operacion, IdAbonado,
      Nombre, Ape1, Ape2, Direccion, Telefono,
      Correo,
      Estado,
      RealizadoPor
  )
  SELECT
      'Abonado',
      'UPDATE',
      i.id_abonado,
      i.nombre,
      i.ape1,
      i.ape2,
      i.direccion,
      i.telefono,
      NULL,           -- <--- reemplaza por i.correo_electronico si existe
      NULL,           -- <--- reemplaza por i.estado si existe
      SYSTEM_USER
  FROM inserted i
  INNER JOIN deleted d
    ON d.id_abonado = i.id_abonado;

  /* ============== DELETE ============== */
  INSERT INTO dbo.Audit_Abonado
  (
      NombreTabla, Operacion, IdAbonado,
      Nombre, Ape1, Ape2, Direccion, Telefono,
      Correo,
      Estado,
      RealizadoPor
  )
  SELECT
      'Abonado',
      'DELETE',
      d.id_abonado,
      d.nombre,
      d.ape1,
      d.ape2,
      d.direccion,
      d.telefono,
      NULL,           -- <--- reemplaza por d.correo_electronico si existe
      NULL,           -- <--- reemplaza por d.estado si existe
      SYSTEM_USER
  FROM deleted d
  LEFT JOIN inserted i
    ON i.id_abonado = d.id_abonado
  WHERE i.id_abonado IS NULL;
END;
GO



-- Abonados con facturas pendientes/vencidas
CREATE OR ALTER VIEW dbo.vw_facturaAbonado
AS
SELECT 
    a.id_abonado,
    a.nombre,
    a.ape1,
    a.ape2,
    f.id_factura,
    f.fecha_emision,
    f.fecha_vencimiento,
    -- Calculamos estado según vencimiento
    CASE 
        WHEN f.fecha_vencimiento < GETDATE() THEN 'Vencida'
        ELSE 'Pendiente'
    END AS estado
FROM dbo.Factura AS f
INNER JOIN dbo.Abonado AS a 
    ON a.id_abonado = f.id_abonado;
GO


-- Abonados con mayor recargo acumulado
CREATE OR ALTER VIEW dbo.vw_morosidadAbonado
AS
SELECT 
    a.id_abonado,
    a.nombre,
    a.ape1,
    a.ape2,
    SUM(ISNULL(p.recargo_mora, 0)) AS total_recargos
FROM dbo.Abonado AS a
LEFT JOIN dbo.Factura AS f 
    ON f.id_abonado = a.id_abonado
LEFT JOIN dbo.Pago AS p 
    ON p.id_factura = f.id_factura
GROUP BY 
    a.id_abonado, a.nombre, a.ape1, a.ape2
HAVING 
    SUM(ISNULL(p.recargo_mora, 0)) > 0;
GO

