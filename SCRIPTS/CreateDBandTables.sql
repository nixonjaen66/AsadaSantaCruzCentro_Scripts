--Creación de la base de datos

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

--Creación de Auditorias

USE master
GO
ALTER DATABASE ASADA_SC ADD FILEGROUP Operativo;
GO
ALTER DATABASE  ASADA_SC ADD FILEGROUP Historico;
GO
ALTER DATABASE  ASADA_SC ADD FILEGROUP Auditorias;
GO


--Tamaño de los filegroup

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

--Creación de tablas 

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
    id_tipoConexion  INT NOT NULL,                    -- relación con Tipo de Conexión
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
    id_tarifa         INT NOT NULL, -- la tarifa aplicada en el momento de la facturación
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

/* ---- Tablas históricas / auditoría: ON Historico ---- */
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
    id_empleado         INT  NOT NULL,  -- quien realizó
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