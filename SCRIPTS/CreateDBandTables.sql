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

-----------------------------------------
	--SPs, TRGs, VWs
-----------------------------------------
	
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

-- sp Auditoria Abonado (Daniel)

USE ASADA_SC;
GO

CREATE OR ALTER PROCEDURE dbo.sp_RegistrarAuditoriaAbonado
    @NombreTabla VARCHAR(30),
    @Operacion VARCHAR(10),
    @IdAbonado INT = NULL,
    @Estado BIT = NULL,
    @RealizadoPor VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Audit_Abonado (
        NombreTabla,
        Operacion,
        IdAbonado,
        Estado,
        RealizadoPor,
        FechaDeEjecucion
    )
    VALUES (
        @NombreTabla,
        @Operacion,
        @IdAbonado,
        @Estado,
        @RealizadoPor,
        SYSUTCDATETIME()
    );
END
GO


-- sp para buscar abonado por correo (Daniel)

CREATE OR ALTER PROCEDURE dbo.sp_BuscarAbonadoPorCorreo
   @CorreoElectronico VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        id_abonado AS IdAbonado,
        nombre AS Nombre,
        ape1 AS Ape1,
        ape2 AS Ape2,
        direccion AS Direccion,
        telefono AS Telefono,
        cedula AS Cedula,
        correo_electronico AS CorreoElectronico,
        fecha_inicio AS FechaInicio,
        rol AS Rol
    FROM dbo.Abonado
    WHERE correo_electronico = @CorreoElectronico;
END
GO

-- sp para agregar tipo de conexión (Daniel)

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

-- sp tipo de conexi�n (Daniel)

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

-- sp insert conexion (Daniel)

USE ASADA_SC;
GO

IF OBJECT_ID('dbo.sp_InsertarConexion', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_InsertarConexion;
GO

CREATE PROCEDURE sp_InsertarConexion
    @nis VARCHAR(10),
    @direccion_servicio VARCHAR(255),
    @fecha_ini DATETIME,
    @fecha_fin DATETIME = NULL,
    @id_abonado INT,
    @id_tipoConexion INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validaciones previas
    IF EXISTS (SELECT 1 FROM Conexion WHERE nis = @nis)
    BEGIN
        RAISERROR('Ya existe una conexión con ese NIS', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Abonado WHERE id_abonado = @id_abonado)
    BEGIN
        RAISERROR('El abonado con ese ID no existe', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM TipoConexion WHERE id_tipoConexion = @id_tipoConexion)
    BEGIN
        RAISERROR('El tipo de conexión con ese ID no existe', 16, 1);
        RETURN;
    END

    BEGIN TRY
        INSERT INTO Conexion (
            nis, direccion_servicio, fecha_ini, fecha_fin, id_abonado, id_tipoConexion
        )
        VALUES (
            @nis, @direccion_servicio, @fecha_ini, @fecha_fin, @id_abonado, @id_tipoConexion
        );

        SELECT SCOPE_IDENTITY() AS idConexionCreada;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- sp update para conexion (Daniel)

IF OBJECT_ID('dbo.sp_ActualizarConexionParcial', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ActualizarConexionParcial;
GO

CREATE PROCEDURE dbo.sp_ActualizarConexionParcial
    @idConexion INT,
    @nis VARCHAR(10) = NULL,
    @direccion_servicio VARCHAR(255) = NULL,
    @fecha_ini DATETIME = NULL,
    @fecha_fin DATETIME = NULL,
    @id_abonado INT = NULL,
    @id_tipoConexion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validación de existencia
    IF NOT EXISTS (SELECT 1 FROM Conexion WHERE id_conexion = @idConexion)
    BEGIN
        RAISERROR('La conexión con ese ID no existe', 16, 1);
        RETURN;
    END

    -- Validaciones para los IDs y NIS si se proporcionan
    IF @nis IS NOT NULL AND EXISTS (SELECT 1 FROM Conexion WHERE nis = @nis AND id_conexion <> @idConexion)
    BEGIN
        RAISERROR('Ya existe otra conexión con ese NIS', 16, 1);
        RETURN;
    END

    IF @id_abonado IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Abonado WHERE id_abonado = @id_abonado)
    BEGIN
        RAISERROR('El abonado con ese ID no existe', 16, 1);
        RETURN;
    END

    IF @id_tipoConexion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM TipoConexion WHERE id_tipoConexion = @id_tipoConexion)
    BEGIN
        RAISERROR('El tipo de conexión con ese ID no existe', 16, 1);
        RETURN;
    END

    BEGIN TRY
        UPDATE Conexion
        SET
            nis = COALESCE(@nis, nis),
            direccion_servicio = COALESCE(@direccion_servicio, direccion_servicio),
            fecha_ini = COALESCE(@fecha_ini, fecha_ini),
            fecha_fin = COALESCE(@fecha_fin, fecha_fin),
            id_abonado = COALESCE(@id_abonado, id_abonado),
            id_tipoConexion = COALESCE(@id_tipoConexion, id_tipoConexion)
        WHERE id_conexion = @idConexion;

        SELECT 'Conexión actualizada correctamente' AS message;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
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

-- Buscar Abonado por correo, telefono, cedula y nombre (Daniel)

CREATE OR ALTER PROCEDURE sp_BuscarAbonadoMasParecido
  @criterio NVARCHAR(100)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @criterioNormalizado NVARCHAR(100);
  SET @criterioNormalizado = LTRIM(RTRIM(LOWER(@criterio)));

  ;WITH Candidatos AS (
    SELECT 
      a.id_abonado AS idAbonado,
	  a.cedula,
	  a.telefono,
	  a.correo_electronico,
      -- 🧱 Nombre completo
      CONCAT(a.nombre, ' ', a.ape1, 
             CASE WHEN a.ape2 IS NOT NULL AND a.ape2 <> '' THEN ' ' + a.ape2 ELSE '' END) AS nombreCompleto,

      -- 🔢 Puntuación de similitud
      (
        CASE WHEN a.nombre COLLATE SQL_Latin1_General_CP1_CI_AI LIKE '%' + @criterioNormalizado + '%' THEN 5 ELSE 0 END +
        CASE WHEN a.ape1 COLLATE SQL_Latin1_General_CP1_CI_AI LIKE '%' + @criterioNormalizado + '%' THEN 4 ELSE 0 END +
        CASE WHEN a.ape2 COLLATE SQL_Latin1_General_CP1_CI_AI LIKE '%' + @criterioNormalizado + '%' THEN 3 ELSE 0 END +
        CASE WHEN a.correo_electronico COLLATE SQL_Latin1_General_CP1_CI_AI LIKE '%' + @criterioNormalizado + '%' THEN 4 ELSE 0 END +
        CASE WHEN a.telefono COLLATE SQL_Latin1_General_CP1_CI_AI LIKE '%' + @criterioNormalizado + '%' THEN 2 ELSE 0 END +
        CASE WHEN a.cedula COLLATE SQL_Latin1_General_CP1_CI_AI LIKE '%' + @criterioNormalizado + '%' THEN 3 ELSE 0 END
      ) AS Puntuacion
    FROM dbo.Abonado a
  )
  SELECT TOP 1
    idAbonado,
	cedula,
    nombreCompleto,
	telefono,
	correo_electronico
  FROM Candidatos
  WHERE Puntuacion > 0
  ORDER BY Puntuacion DESC;
END;
GO

-- Sp insertar periodo (Daniel)

CREATE OR ALTER PROCEDURE sp_InsertarPeriodo
    @anio INT,
    @mes INT,
    @fechaCorte DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validaciones
    IF @anio IS NULL OR @mes IS NULL
    BEGIN
        RAISERROR('Debe proporcionar año y mes del periodo.', 16, 1);
        RETURN;
    END

    IF @mes < 1 OR @mes > 12
    BEGIN
        RAISERROR('El mes debe estar entre 1 y 12.', 16, 1);
        RETURN;
    END

    -- Validar duplicado
    IF EXISTS (
        SELECT 1
        FROM dbo.Periodo
        WHERE anio = @anio AND mes = @mes
    )
    BEGIN
        RAISERROR('Ya existe un periodo con el mismo año y mes.', 16, 1);
        RETURN;
    END

    -- Insertar el periodo
    INSERT INTO dbo.Periodo (anio, mes, fecha_corte)
    VALUES (@anio, @mes, @fechaCorte);

    -- Devolver el id generado
    SELECT SCOPE_IDENTITY() AS idPeriodo;
END;
GO

-- Buscar periodo (Daniel)

CREATE OR ALTER PROCEDURE sp_BuscarPeriodo
    @anio INT = NULL,
    @mes INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar que al menos un parámetro venga
    IF @anio IS NULL AND @mes IS NULL
    BEGIN
        RAISERROR('Debe proporcionar al menos el año o el mes para la búsqueda.', 16, 1);
        RETURN;
    END

    -- Buscar el periodo
    SELECT TOP 1
        id_periodo AS idPeriodo,
        anio,
        mes,
        CONVERT(VARCHAR(10), fecha_corte, 103) AS fechaCorte -- Formato dd/mm/yyyy
    FROM dbo.Periodo
    WHERE 
        (@anio IS NULL OR anio = @anio) AND
        (@mes IS NULL OR mes = @mes)
    ORDER BY anio DESC, mes DESC;  -- Devuelve el más reciente si hay varios
END;
GO

-- Sp insertar medidor (Daniel)

CREATE OR ALTER PROCEDURE sp_InsertarMedidor
    @serial VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    -- Validación del serial
    IF @serial IS NULL OR LEN(@serial) = 0
    BEGIN
        RAISERROR('Debe proporcionar un serial válido.', 16, 1);
        RETURN;
    END

    -- Validar duplicado
    IF EXISTS (
        SELECT 1
        FROM dbo.Medidor
        WHERE serial = @serial
    )
    BEGIN
        RAISERROR('Ya existe un medidor con el mismo serial.', 16, 1);
        RETURN;
    END

    -- Insertar el medidor con estado = 1 (activo)
    INSERT INTO dbo.Medidor (serial, estado)
    VALUES (@serial, 0);

    -- Devolver el id generado
    SELECT SCOPE_IDENTITY() AS idMedidor;
END;
GO

-- Listar medidores sp (Daniel)

CREATE OR ALTER PROCEDURE sp_ListarMedidores
    @numeroInicial INT = 0, -- desde qué registro empezar
    @limite INT = 10        -- cuántos registros traer
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar parámetros
    IF @numeroInicial < 0 SET @numeroInicial = 0;
    IF @limite <= 0 SET @limite = 10;

    -- Obtener total de medidores
    DECLARE @total INT;
    SELECT @total = COUNT(*) FROM dbo.Medidor;

    -- Devolver los registros paginados
    SELECT 
        id_medidor AS idMedidor,
        serial,
        estado,
        @total AS total
    FROM dbo.Medidor
    ORDER BY id_medidor
    OFFSET @numeroInicial ROWS
    FETCH NEXT @limite ROWS ONLY;
END;
GO

-- sp buscar medidor (Daniel)

CREATE OR ALTER PROCEDURE sp_BuscarMedidor
    @serialBuscado VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    -- Validación
    IF @serialBuscado IS NULL OR LEN(@serialBuscado) = 0
    BEGIN
        RAISERROR('Debe proporcionar un serial para la búsqueda.', 16, 1);
        RETURN;
    END

    -- Buscar medidor más parecido
    SELECT TOP 1
        id_medidor AS idMedidor,
        serial,
        estado
    FROM dbo.Medidor
    WHERE serial LIKE '%' + @serialBuscado + '%'
    ORDER BY 
        -- Ordena por cercanía: empieza con el valor buscado primero
        CASE 
            WHEN serial = @serialBuscado THEN 0
            WHEN serial LIKE @serialBuscado + '%' THEN 1
            ELSE 2
        END,
        id_medidor; -- desempate por id
END;
GO

-- Insertar tarifa (Daniel)

IF OBJECT_ID('dbo.sp_InsertarTarifa', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_InsertarTarifa;
GO

CREATE PROCEDURE sp_InsertarTarifa
    @tipoTarifa VARCHAR(30),
    @cargoFijo DECIMAL(12,2),
    @fechaIni DATETIME,
    @fechaFin DATETIME = NULL,
    @idTipoConexion INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validación tipo de conexión
    IF NOT EXISTS (SELECT 1 FROM TipoConexion WHERE id_tipoConexion = @idTipoConexion)
    BEGIN
        RAISERROR('El tipo de conexión con ese ID no existe', 16, 1);
        RETURN;
    END

    -- Validar solapamiento de tarifas
    IF EXISTS (
        SELECT 1 
        FROM Tarifa 
        WHERE tipo_tarifa = @tipoTarifa 
          AND id_tipoConexion = @idTipoConexion 
          AND fecha_ini <= ISNULL(@fechaFin, GETDATE())
          AND (fecha_fin IS NULL OR fecha_fin >= @fechaIni)
    )
    BEGIN
        RAISERROR('Ya existe una tarifa para este tipo de conexión y fechas que se solapan', 16, 1);
        RETURN;
    END

    BEGIN TRY
        -- Insertar tarifa
        INSERT INTO Tarifa (tipo_tarifa, cargo_fijo, fecha_ini, fecha_fin, id_tipoConexion)
        VALUES (@tipoTarifa, @cargoFijo, @fechaIni, @fechaFin, @idTipoConexion);

        -- Devolver el id generado
        SELECT SCOPE_IDENTITY() AS idTarifaCreada;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO


-- sp Buscar tarifa (Daniel)

CREATE OR ALTER PROCEDURE  sp_BuscarTarifa
    @idTipoConexion INT = NULL,
    @nombreTipoTarifa NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        t.id_tarifa,
        t.tipo_tarifa
      
    FROM Tarifa t
    WHERE 
        (@idTipoConexion IS NULL OR t.id_tipoConexion = @idTipoConexion)
        AND
        (@nombreTipoTarifa IS NULL OR t.tipo_tarifa LIKE '%' + @nombreTipoTarifa + '%')
    ORDER BY 
        -- opcional: poner primero los más parecidos si quieres
        CASE 
            WHEN @nombreTipoTarifa IS NOT NULL THEN 
                LEN(t.tipo_tarifa) - LEN(REPLACE(t.tipo_tarifa, @nombreTipoTarifa, ''))
            ELSE 0
        END DESC
END

-- Insert tramo tarifa (Daniel)

CREATE OR ALTER PROCEDURE sp_InsertarTarifaTramo
    @idTarifa INT,
    @desdeM3 INT = NULL,
    @hastaM3 INT = NULL,
    @precioM3 DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    -- Validaciones
    IF @precioM3 <= 0
    BEGIN
        RAISERROR('El precio por m3 debe ser mayor a 0.', 16, 1);
        RETURN;
    END

    IF @idTarifa IS NULL
    BEGIN
        RAISERROR('Debe proporcionar un idTarifa válido.', 16, 1);
        RETURN;
    END

    IF @desdeM3 IS NOT NULL AND @hastaM3 IS NOT NULL AND @desdeM3 > @hastaM3
    BEGIN
        RAISERROR('desdeM3 no puede ser mayor que hastaM3.', 16, 1);
        RETURN;
    END

    -- Validar que exista la tarifa
    IF NOT EXISTS (SELECT 1 FROM dbo.Tarifa WHERE id_tarifa = @idTarifa)
    BEGIN
        RAISERROR('No existe una tarifa con el id proporcionado.', 16, 1);
        RETURN;
    END

    -- Insertar el tramo
    INSERT INTO dbo.TarifaTramo (id_tarifa, desde_m3, hasta_m3, precio_m3)
    VALUES (@idTarifa, @desdeM3, @hastaM3, @precioM3);

    -- Devolver el id generado
    SELECT SCOPE_IDENTITY() AS idTramo;
END;
GO


-- sp insertar medidor historico (Daniel)

CREATE OR ALTER PROCEDURE sp_InsertarMedidorHistorico
    @idMedidor INT,
    @idConexion INT,
    @fechaInstalacion DATETIME,
    @fechaRetiro DATETIME = NULL,
    @lecturaInicial DECIMAL(12,2),
    @lecturaFinal DECIMAL(12,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar existencia del medidor
    IF NOT EXISTS (SELECT 1 FROM dbo.Medidor WHERE id_medidor = @idMedidor)
    BEGIN
        RAISERROR('El medidor especificado no existe.', 16, 1);
        RETURN;
    END;

    -- Validar existencia de la conexión
    IF NOT EXISTS (SELECT 1 FROM dbo.Conexion WHERE id_conexion = @idConexion)
    BEGIN
        RAISERROR('La conexión especificada no existe.', 16, 1);
        RETURN;
    END;

    -- Validar fechas
    IF @fechaInstalacion IS NULL
    BEGIN
        RAISERROR('Debe especificar una fecha de instalación.', 16, 1);
        RETURN;
    END;

    IF @fechaRetiro IS NOT NULL AND @fechaRetiro < @fechaInstalacion
    BEGIN
        RAISERROR('La fecha de retiro no puede ser anterior a la instalación.', 16, 1);
        RETURN;
    END;

    -- Validar lecturas
    IF @lecturaInicial < 0
    BEGIN
        RAISERROR('La lectura inicial no puede ser negativa.', 16, 1);
        RETURN;
    END;

    IF @lecturaFinal IS NOT NULL AND @lecturaFinal < @lecturaInicial
    BEGIN
        RAISERROR('La lectura final no puede ser menor que la inicial.', 16, 1);
        RETURN;
    END;

    -- Validar que el medidor no esté ya asignado sin retiro
    IF EXISTS (
        SELECT 1 FROM dbo.MedidorHistorico 
        WHERE id_medidor = @idMedidor AND fecha_retiro IS NULL
    )
    BEGIN
        RAISERROR('El medidor ya está asignado y no ha sido retirado.', 16, 1);
        RETURN;
    END;

    -- Insertar registro en MedidorHistorico
    INSERT INTO dbo.MedidorHistorico (
        id_medidor, id_conexion, fecha_instalacion, fecha_retiro, lectura_inicial, lectura_final
    )
    VALUES (
        @idMedidor, @idConexion, @fechaInstalacion, @fechaRetiro, @lecturaInicial, @lecturaFinal
    );

    -- Cambiar el estado del medidor a "instalado" (1)
    UPDATE dbo.Medidor
    SET estado = 1
    WHERE id_medidor = @idMedidor;

    -- Retornar ID generado
    SELECT SCOPE_IDENTITY() AS idMedidorHistorico;
END;
GO

-- sp insertar lectura (Daniel)

CREATE OR ALTER PROCEDURE sp_InsertarLecturaConFactura
    @idMedidor INT,
    @idPeriodo INT,
    @lecturaAnterior DECIMAL(12,2),
    @lecturaActual DECIMAL(12,2),
    @fechaLectura DATETIME,
    @idEmpleado INT
AS
BEGIN
    SET NOCOUNT ON;

    -------------------------------
    -- 1️⃣ Validaciones básicas
    -------------------------------

    -- Medidor existente
    IF NOT EXISTS (SELECT 1 FROM dbo.Medidor WHERE id_medidor = @idMedidor)
    BEGIN
        RAISERROR('El medidor especificado no existe.', 16, 1);
        RETURN;
    END

    -- Periodo existente
    IF NOT EXISTS (SELECT 1 FROM dbo.Periodo WHERE id_periodo = @idPeriodo)
    BEGIN
        RAISERROR('El periodo especificado no existe.', 16, 1);
        RETURN;
    END

    -- Empleado existente
    IF NOT EXISTS (SELECT 1 FROM dbo.Empleado WHERE id_empleado = @idEmpleado)
    BEGIN
        RAISERROR('El empleado especificado no existe.', 16, 1);
        RETURN;
    END

    -- Lecturas válidas
    IF @lecturaAnterior < 0 OR @lecturaActual < 0
    BEGIN
        RAISERROR('Las lecturas no pueden ser negativas.', 16, 1);
        RETURN;
    END

    IF @lecturaActual < @lecturaAnterior
    BEGIN
        RAISERROR('La lectura actual no puede ser menor que la anterior.', 16, 1);
        RETURN;
    END


    -------------------------------
    -- 2️⃣ Insertar lectura
    -------------------------------
    INSERT INTO dbo.Lectura (id_medidor, id_periodo, lectura_anterior, lectura_actual, fecha_lectura, id_empleado)
    VALUES (@idMedidor, @idPeriodo, @lecturaAnterior, @lecturaActual, @fechaLectura, @idEmpleado);

    DECLARE @idLectura INT = SCOPE_IDENTITY();
    DECLARE @idConexion INT;
    DECLARE @idAbonado INT;
    DECLARE @idTipoConexion INT;
    DECLARE @idTarifa INT;
    DECLARE @fechaVencimiento DATETIME;

    -------------------------------
    -- Obtener datos de conexión y abonado
    -------------------------------
    SELECT TOP 1
        @idConexion = mh.id_conexion,
        @idTipoConexion = c.id_tipoConexion,
        @idAbonado = c.id_abonado
    FROM dbo.MedidorHistorico mh
    INNER JOIN dbo.Conexion c ON c.id_conexion = mh.id_conexion
    WHERE mh.id_medidor = @idMedidor
      AND mh.fecha_retiro IS NULL;

    IF @idConexion IS NULL
    BEGIN
        RAISERROR('No se encontró una conexión activa para este medidor.', 16, 1);
        RETURN;
    END

    -------------------------------
    -- Obtener tarifa activa
    -------------------------------
    SELECT TOP 1 @idTarifa = t.id_tarifa
    FROM dbo.Tarifa t
    WHERE t.id_tipoConexion = @idTipoConexion
      AND t.fecha_ini <= @fechaLectura
      AND (t.fecha_fin IS NULL OR t.fecha_fin >= @fechaLectura)
    ORDER BY t.fecha_ini DESC;

    IF @idTarifa IS NULL
    BEGIN
        RAISERROR('No se encontró una tarifa activa para este tipo de conexión.', 16, 1);
        RETURN;
    END

    -------------------------------
    -- Obtener fecha de vencimiento del periodo
    -------------------------------
    SELECT @fechaVencimiento = fecha_corte
    FROM dbo.Periodo
    WHERE id_periodo = @idPeriodo;

    -------------------------------
    -- Insertar factura y relacionar
    -------------------------------
    INSERT INTO dbo.Factura (fecha_emision, fecha_vencimiento, id_conexion, id_abonado, id_tarifa)
    VALUES (@fechaLectura, @fechaVencimiento, @idConexion, @idAbonado, @idTarifa);

    DECLARE @idFactura INT = SCOPE_IDENTITY();

    INSERT INTO dbo.Factura_Lectura (id_factura, id_lectura)
    VALUES (@idFactura, @idLectura);
END;
GO

-- generar factura (Daniel) 

CREATE OR ALTER PROCEDURE sp_GenerarFacturaPeriodoPorTramo
    @idMedidor INT,
    @idPeriodo INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idConexion INT;
    DECLARE @idAbonado INT;
    DECLARE @idTipoConexion INT;
    DECLARE @idTarifa INT;
    DECLARE @fechaVencimiento DATETIME;
    DECLARE @fechaEmision DATETIME = GETDATE();
    DECLARE @cargoFijo DECIMAL(12,2) = 0;
    DECLARE @totalFactura DECIMAL(12,2) = 0;
    DECLARE @lecturasExistentes INT;

    -- Validaciones básicas
    IF NOT EXISTS (SELECT 1 FROM dbo.Medidor WHERE id_medidor = @idMedidor)
    BEGIN
        RAISERROR('El medidor especificado no existe.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.Periodo WHERE id_periodo = @idPeriodo)
    BEGIN
        RAISERROR('El periodo especificado no existe.', 16, 1);
        RETURN;
    END

    -- Verificar si hay lecturas en el periodo
   SELECT @lecturasExistentes = COUNT(*)
	FROM dbo.Lectura
	WHERE id_medidor = @idMedidor
	  AND id_periodo = @idPeriodo;

	IF @lecturasExistentes = 0
	BEGIN
		RAISERROR('No hay lecturas registradas para este medidor en el periodo especificado.', 16, 1);
		RETURN;
	END

	

    -- Obtener conexión, abonado y tipo de conexión
    SELECT TOP 1
        @idConexion = mh.id_conexion,
        @idTipoConexion = c.id_tipoConexion,
        @idAbonado = c.id_abonado
    FROM dbo.MedidorHistorico mh
    INNER JOIN dbo.Conexion c ON c.id_conexion = mh.id_conexion
    WHERE mh.id_medidor = @idMedidor
      AND mh.fecha_retiro IS NULL;

    IF @idConexion IS NULL
    BEGIN
        RAISERROR('No se encontró una conexión activa para este medidor.', 16, 1);
        RETURN;
    END

    -- Obtener tarifa activa
    SELECT TOP 1
        @idTarifa = t.id_tarifa,
        @cargoFijo = t.cargo_fijo
    FROM dbo.Tarifa t
    WHERE t.id_tipoConexion = @idTipoConexion
      AND t.fecha_ini <= @fechaEmision
      AND (t.fecha_fin IS NULL OR t.fecha_fin >= @fechaEmision)
    ORDER BY t.fecha_ini DESC;

    IF @idTarifa IS NULL
    BEGIN
        RAISERROR('No se encontró una tarifa activa para este tipo de conexión.', 16, 1);
        RETURN;
    END

    -- Fecha de corte del periodo
    SELECT @fechaVencimiento = fecha_corte
    FROM dbo.Periodo
    WHERE id_periodo = @idPeriodo;

    -- Calcular costo por lectura y tramo
    ;WITH LecturaTramos AS (
        SELECT
            l.id_lectura,
            l.lectura_anterior,
            l.lectura_actual,
            t.id_tramo,
            t.desde_m3,
            t.hasta_m3,
            t.precio_m3,
            CASE
                WHEN t.hasta_m3 IS NULL THEN
                    CASE 
                        WHEN l.lectura_actual - l.lectura_anterior >= ISNULL(t.desde_m3,0)
                        THEN (l.lectura_actual - l.lectura_anterior - ISNULL(t.desde_m3,0) + 1) * t.precio_m3
                        ELSE 0
                    END
                ELSE
                    CASE 
                        WHEN l.lectura_actual - l.lectura_anterior >= t.desde_m3
                        THEN ((CASE 
                                WHEN l.lectura_actual - l.lectura_anterior > t.hasta_m3 
                                THEN t.hasta_m3 
                                ELSE l.lectura_actual - l.lectura_anterior
                              END) - t.desde_m3 + 1) * t.precio_m3
                        ELSE 0
                    END
            END AS costoTramo
        FROM dbo.Lectura l
        INNER JOIN dbo.TarifaTramo t ON t.id_tarifa = @idTarifa
        WHERE l.id_medidor = @idMedidor
          AND l.id_periodo = @idPeriodo
    )
    SELECT @totalFactura = SUM(costoTramo)
    FROM LecturaTramos;

    -- Sumar cargo fijo
    SET @totalFactura = ISNULL(@totalFactura,0) + @cargoFijo;

    -- Insertar factura
    INSERT INTO dbo.Factura (fecha_emision, fecha_vencimiento, id_conexion, id_abonado, id_tarifa)
    VALUES (@fechaEmision, @fechaVencimiento, @idConexion, @idAbonado, @idTarifa);

    DECLARE @idFactura INT = SCOPE_IDENTITY();

    -- Relacionar todas las lecturas del periodo con la factura
    INSERT INTO dbo.Factura_Lectura (id_factura, id_lectura)
    SELECT @idFactura, id_lectura
    FROM dbo.Lectura
    WHERE id_medidor = @idMedidor
      AND id_periodo = @idPeriodo;

    -- Retornar resultado
    SELECT @idFactura AS idFactura, @totalFactura AS totalAPagar;
END;
GO

-- sp listar lecturas con filtros (Daniel)

CREATE OR ALTER PROCEDURE sp_BuscarLecturasPaginado
    @idPeriodo INT = NULL,
    @idEmpleado INT = NULL,
    @idMedidor INT = NULL,
    @busqueda NVARCHAR(100) = NULL,
    @numeroInicial INT = 0,
    @limite INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    -- Total de registros en la tabla
    DECLARE @total INT;
    SELECT @total = COUNT(*) FROM dbo.Lectura;

    -- Total que coincide con filtros
    DECLARE @encontrados INT;
    SELECT @encontrados = COUNT(*)
    FROM dbo.Lectura L
    WHERE
        (@idPeriodo IS NULL OR L.id_periodo = @idPeriodo)
        AND (@idEmpleado IS NULL OR L.id_empleado = @idEmpleado)
        AND (@idMedidor IS NULL OR L.id_medidor = @idMedidor)
        AND (
            @busqueda IS NULL
            OR EXISTS (
                SELECT 1 FROM dbo.Periodo P
                WHERE P.id_periodo = L.id_periodo
                  AND REPLACE(LOWER(CONCAT(P.mes,'/',P.anio)),' ','') LIKE '%' + REPLACE(LOWER(@busqueda),' ','') + '%'
            )
            OR EXISTS (
                SELECT 1 FROM dbo.Empleado E
                WHERE E.id_empleado = L.id_empleado
                  AND REPLACE(LOWER(CONCAT(E.nombre,' ',E.ape1,' ',ISNULL(E.ape2,''))),' ','') LIKE '%' + REPLACE(LOWER(@busqueda),' ','') + '%'
            )
            OR EXISTS (
                SELECT 1 FROM dbo.Medidor M
                WHERE M.id_medidor = L.id_medidor
                  AND REPLACE(LOWER(M.serial),' ','') LIKE '%' + REPLACE(LOWER(@busqueda),' ','') + '%'
            )
        );

    -- Registros paginados
    SELECT 
        L.id_lectura AS idLectura,
        L.lectura_anterior AS lecturaAnterior,
        L.lectura_actual AS lecturaActual,
        L.fecha_lectura AS fechaLectura,
        L.id_periodo AS idPeriodo,
        CONCAT(P.mes,'/',P.anio) AS nombrePeriodo,
        L.id_empleado AS idEmpleado,
        CONCAT(E.nombre,' ',E.ape1,' ',ISNULL(E.ape2,'')) AS nombreEmpleado,
        L.id_medidor AS idMedidor,
        M.serial AS serialMedidor,
        @total AS total,
        @encontrados AS encontrados
    FROM dbo.Lectura L
    INNER JOIN dbo.Periodo P ON L.id_periodo = P.id_periodo
    INNER JOIN dbo.Empleado E ON L.id_empleado = E.id_empleado
    INNER JOIN dbo.Medidor M ON L.id_medidor = M.id_medidor
    WHERE
        (@idPeriodo IS NULL OR L.id_periodo = @idPeriodo)
        AND (@idEmpleado IS NULL OR L.id_empleado = @idEmpleado)
        AND (@idMedidor IS NULL OR L.id_medidor = @idMedidor)
        AND (
            @busqueda IS NULL
            OR REPLACE(LOWER(CONCAT(P.mes,'/',P.anio)),' ','') LIKE '%' + REPLACE(LOWER(@busqueda),' ','') + '%'
            OR REPLACE(LOWER(CONCAT(E.nombre,' ',E.ape1,' ',ISNULL(E.ape2,''))),' ','') LIKE '%' + REPLACE(LOWER(@busqueda),' ','') + '%'
            OR REPLACE(LOWER(M.serial),' ','') LIKE '%' + REPLACE(LOWER(@busqueda),' ','') + '%'
        )
    ORDER BY L.fecha_lectura DESC
    OFFSET @numeroInicial ROWS
    FETCH NEXT @limite ROWS ONLY;
END;
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
	
------------------------------------------------------------------------
	--------------------------------------------------------------
--SP Mantenimientos --David
	--------------------------------------------------------------
------------------------------------------------------------------------
	
-- sp_InsertarMantenimiento
CREATE OR ALTER PROCEDURE sp_InsertarMantenimiento --Quitar el ALTER si no sirve 
    @fechaMantenimiento DATETIME,
    @ubicacion VARCHAR(255) = NULL,
    @idConexion INT,
    @idEmpleado INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validaciones
    IF @fechaMantenimiento IS NULL
    BEGIN
        RAISERROR('Debe proporcionar una fecha de mantenimiento.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Conexion WHERE id_conexion = @idConexion)
    BEGIN
        RAISERROR('La conexión especificada no existe.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Empleado WHERE id_empleado = @idEmpleado)
    BEGIN
        RAISERROR('El empleado especificado no existe.', 16, 1);
        RETURN;
    END

    -- Insertar mantenimiento
    INSERT INTO Mantenimientos (fecha_mantenimiento, ubicacion, estado, id_conexion, id_empleado)
    VALUES (@fechaMantenimiento, @ubicacion, 1, @idConexion, @idEmpleado);

    -- Retornar ID generado
    SELECT SCOPE_IDENTITY() AS idMantenimiento;
END;
GO

-- sp_ListarMantenimientos
CREATE OR ALTER PROCEDURE sp_ListarMantenimientos
    @numeroInicial INT = 0,
    @limite INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar parámetros
    IF @numeroInicial < 0 SET @numeroInicial = 0;
    IF @limite <= 0 SET @limite = 10;

    -- Obtener total de mantenimientos
    DECLARE @total INT;
    SELECT @total = COUNT(*) FROM Mantenimientos;

    -- Devolver los registros paginados
    SELECT 
        m.id_mantenimiento AS idMantenimiento,
        m.fecha_mantenimiento AS fechaMantenimiento,
        m.ubicacion,
        m.estado,
        c.id_conexion AS idConexion,
        c.nis,
        e.id_empleado AS idEmpleado,
        e.nombre AS nombreEmpleado,
        e.ape1 AS ape1Empleado,
        @total AS total
    FROM Mantenimientos m
    LEFT JOIN Conexion c ON c.id_conexion = m.id_conexion
    LEFT JOIN Empleado e ON e.id_empleado = m.id_empleado
    ORDER BY m.fecha_mantenimiento DESC
    OFFSET @numeroInicial ROWS
    FETCH NEXT @limite ROWS ONLY;
END;
GO

-- sp_BuscarMantenimientos
CREATE OR ALTER PROCEDURE sp_BuscarMantenimientos
    @idConexion INT = NULL,
    @idEmpleado INT = NULL,
    @fechaDesde DATETIME = NULL,
    @fechaHasta DATETIME = NULL,
    @busqueda VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        m.id_mantenimiento AS idMantenimiento,
        m.fecha_mantenimiento AS fechaMantenimiento,
        m.ubicacion,
        m.estado,
        c.nis,
        e.nombre AS nombreEmpleado,
        e.ape1 AS ape1Empleado
    FROM Mantenimientos m
    LEFT JOIN Conexion c ON c.id_conexion = m.id_conexion
    LEFT JOIN Empleado e ON e.id_empleado = m.id_empleado
    WHERE 
        (@idConexion IS NULL OR m.id_conexion = @idConexion)
        AND (@idEmpleado IS NULL OR m.id_empleado = @idEmpleado)
        AND (@fechaDesde IS NULL OR m.fecha_mantenimiento >= @fechaDesde)
        AND (@fechaHasta IS NULL OR m.fecha_mantenimiento <= @fechaHasta)
        AND (@busqueda IS NULL OR 
             LOWER(ISNULL(m.ubicacion,'')) LIKE '%' + LOWER(@busqueda) + '%' OR
             LOWER(ISNULL(c.nis,'')) LIKE '%' + LOWER(@busqueda) + '%')
    ORDER BY m.fecha_mantenimiento DESC;
END;
GO

-- sp_ActualizarMantenimiento
CREATE OR ALTER PROCEDURE sp_ActualizarMantenimiento
    @idMantenimiento INT,
    @fechaMantenimiento DATETIME = NULL,
    @ubicacion VARCHAR(255) = NULL,
    @estado BIT = NULL,
    @idConexion INT = NULL,
    @idEmpleado INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar existencia
    IF NOT EXISTS (SELECT 1 FROM Mantenimientos WHERE id_mantenimiento = @idMantenimiento)
    BEGIN
        RAISERROR('El mantenimiento especificado no existe.', 16, 1);
        RETURN;
    END

    -- Validar conexión si se proporciona
    IF @idConexion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Conexion WHERE id_conexion = @idConexion)
    BEGIN
        RAISERROR('La conexión especificada no existe.', 16, 1);
        RETURN;
    END

    -- Validar empleado si se proporciona
    IF @idEmpleado IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Empleado WHERE id_empleado = @idEmpleado)
    BEGIN
        RAISERROR('El empleado especificado no existe.', 16, 1);
        RETURN;
    END

    -- Actualizar mantenimiento
    UPDATE Mantenimientos
    SET 
        fecha_mantenimiento = COALESCE(@fechaMantenimiento, fecha_mantenimiento),
        ubicacion = COALESCE(@ubicacion, ubicacion),
        estado = COALESCE(@estado, estado),
        id_conexion = COALESCE(@idConexion, id_conexion),
        id_empleado = COALESCE(@idEmpleado, id_empleado)
    WHERE id_mantenimiento = @idMantenimiento;

    SELECT 'Mantenimiento actualizado correctamente' AS message;
END;
GO

-- sp_EliminarMantenimiento
CREATE OR ALTER PROCEDURE sp_EliminarMantenimiento
    @idMantenimiento INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar existencia
    IF NOT EXISTS (SELECT 1 FROM Mantenimientos WHERE id_mantenimiento = @idMantenimiento)
    BEGIN
        RAISERROR('El mantenimiento especificado no existe.', 16, 1);
        RETURN;
    END

    -- Eliminar detalles primero (cascada)
    DELETE FROM DetalleMantenimiento WHERE id_mantenimiento = @idMantenimiento;

    -- Eliminar mantenimiento
    DELETE FROM Mantenimientos WHERE id_mantenimiento = @idMantenimiento;

    SELECT 'Mantenimiento eliminado correctamente' AS message;
END;
GO

-- sp_InsertarDetalleMantenimiento
CREATE OR ALTER PROCEDURE sp_InsertarDetalleMantenimiento
    @idMantenimiento INT,
    @descripcionTrabajo VARCHAR(255),
    @idEmpleado INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validaciones
    IF @descripcionTrabajo IS NULL OR LEN(@descripcionTrabajo) = 0
    BEGIN
        RAISERROR('Debe proporcionar una descripción del trabajo.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Mantenimientos WHERE id_mantenimiento = @idMantenimiento)
    BEGIN
        RAISERROR('El mantenimiento especificado no existe.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Empleado WHERE id_empleado = @idEmpleado)
    BEGIN
        RAISERROR('El empleado especificado no existe.', 16, 1);
        RETURN;
    END

    -- Insertar detalle
    INSERT INTO DetalleMantenimiento (id_mantenimiento, descripcion_trabajo, id_empleado)
    VALUES (@idMantenimiento, @descripcionTrabajo, @idEmpleado);

    -- Retornar ID generado
    SELECT SCOPE_IDENTITY() AS idDetalle;
END;
GO

-- sp_ObtenerDetallesMantenimiento
CREATE OR ALTER PROCEDURE sp_ObtenerDetallesMantenimiento
    @idMantenimiento INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar existencia del mantenimiento
    IF NOT EXISTS (SELECT 1 FROM Mantenimientos WHERE id_mantenimiento = @idMantenimiento)
    BEGIN
        RAISERROR('El mantenimiento especificado no existe.', 16, 1);
        RETURN;
    END

    -- Obtener detalles
    SELECT 
        d.id_detalle AS idDetalle,
        d.descripcion_trabajo AS descripcionTrabajo,
        e.id_empleado AS idEmpleado,
        e.nombre AS nombreEmpleado,
        e.ape1 AS ape1Empleado
    FROM DetalleMantenimiento d
    INNER JOIN Empleado e ON e.id_empleado = d.id_empleado
    WHERE d.id_mantenimiento = @idMantenimiento
    ORDER BY d.id_detalle DESC;
END;
GO

--SP_Get [Empleados y Conexion] --David

-- sp_ListarEmpleados
CREATE OR ALTER PROCEDURE sp_ListarEmpleados
    @numeroInicial INT = 0,
    @limite INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar parámetros
    IF @numeroInicial < 0 SET @numeroInicial = 0;
    IF @limite <= 0 SET @limite = 10;

    -- Obtener total de empleados
    DECLARE @total INT;
    SELECT @total = COUNT(*) FROM Empleado;

    -- Devolver los registros paginados
    SELECT 
        e.id_empleado AS idEmpleado,
        e.cedula,
        e.nombre,
        e.ape1,
        e.ape2,
        e.telefono,
        e.correo_electronico AS correoElectronico,
        e.rol,
        @total AS total
    FROM Empleado e
    ORDER BY e.id_empleado
    OFFSET @numeroInicial ROWS
    FETCH NEXT @limite ROWS ONLY;
END;
GO

-- sp_ListarConexiones
CREATE OR ALTER PROCEDURE sp_ListarConexiones
    @numeroInicial INT = 0,
    @limite INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar parámetros
    IF @numeroInicial < 0 SET @numeroInicial = 0;
    IF @limite <= 0 SET @limite = 10;

    -- Obtener total de conexiones
    DECLARE @total INT;
    SELECT @total = COUNT(*) FROM Conexion;

    -- Devolver los registros paginados
    SELECT 
        c.id_conexion AS idConexion,
        c.nis,
        c.direccion_servicio AS direccionServicio,
        c.fecha_ini AS fechaIni,
        c.fecha_fin AS fechaFin,
        a.id_abonado AS idAbonado,
        a.nombre AS nombreAbonado,
        a.ape1 AS ape1Abonado,
        tc.id_tipoConexion AS idTipoConexion,
        tc.nombre AS nombreTipoConexion,
        @total AS total
    FROM Conexion c
    LEFT JOIN Abonado a ON a.id_abonado = c.id_abonado
    LEFT JOIN TipoConexion tc ON tc.id_tipoConexion = c.id_tipoConexion
    ORDER BY c.id_conexion
    OFFSET @numeroInicial ROWS
    FETCH NEXT @limite ROWS ONLY;
END;
GO
