-- Verificar si la tabla ya existe para eliminarla antes de su creación
IF OBJECT_ID('dbo.UnidadRobotica', 'U') IS NOT NULL
    DROP TABLE UnidadRobotica;
GO

-- Creación de la tabla estructurada para las unidades robóticas
CREATE TABLE UnidadRobotica (
    RobotId         INT PRIMARY KEY,
    Alias           NVARCHAR(100),
    Ubicacion       NVARCHAR(100),
    Estado          NVARCHAR(50),
    GradosLibertad  INT,
    HorasTrabajo    FLOAT
);
GO

-- =============================================================
-- 1. PROCEDIMIENTO PARA RESTRICCIÓN E INSERCIÓN DE UN ROBOT
-- =============================================================
IF OBJECT_ID('dbo.usp_AddRobot', 'P') IS NOT NULL
    DROP PROCEDURE usp_AddRobot;
GO

CREATE PROCEDURE usp_AddRobot
    @RobotId        INT,
    @Alias          NVARCHAR(100),
    @Ubicacion      NVARCHAR(100),
    @Estado         NVARCHAR(50),
    @GradosLibertad INT,
    @HorasTrabajo   FLOAT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO UnidadRobotica (
        RobotId,
        Alias,
        Ubicacion,
        Estado,
        GradosLibertad,
        HorasTrabajo
    )
    VALUES (
        @RobotId,
        @Alias,
        @Ubicacion,
        @Estado,
        @GradosLibertad,
        @HorasTrabajo
    );
END;
GO

-- =============================================================
-- 2. PROCEDIMIENTO PARA CONSULTAR LA FLOTA COMPLETA
-- =============================================================
IF OBJECT_ID('dbo.usp_QueryAllRobots', 'P') IS NOT NULL
    DROP PROCEDURE usp_QueryAllRobots;
GO

CREATE PROCEDURE usp_QueryAllRobots
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        RobotId,
        Alias,
        Ubicacion,
        Estado,
        GradosLibertad,
        HorasTrabajo
    FROM UnidadRobotica;
END;
GO

-- =============================================================
-- 3. PROCEDIMIENTO PARA ACTUALIZAR PARÁMETROS OPERATIVOS
-- =============================================================
IF OBJECT_ID('dbo.usp_UpdateRobot', 'P') IS NOT NULL
    DROP PROCEDURE usp_UpdateRobot;
GO

CREATE PROCEDURE usp_UpdateRobot
    @RobotId        INT,
    @Alias          NVARCHAR(100),
    @Ubicacion      NVARCHAR(100),
    @Estado         NVARCHAR(50),
    @GradosLibertad INT,
    @HorasTrabajo   FLOAT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE UnidadRobotica
    SET
        Alias           = @Alias,
        Ubicacion       = @Ubicacion,
        Estado          = @Estado,
        GradosLibertad  = @GradosLibertad,
        HorasTrabajo    = @HorasTrabajo
    WHERE RobotId = @RobotId;
END;
GO

-- =============================================================
-- 4. PROCEDIMIENTO PARA ELIMINAR O DAR DE BAJA UN ROBOT
-- =============================================================
IF OBJECT_ID('dbo.usp_DeleteRobot', 'P') IS NOT NULL
    DROP PROCEDURE usp_DeleteRobot;
GO

CREATE PROCEDURE usp_DeleteRobot
    @RobotId INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM UnidadRobotica
    WHERE RobotId = @RobotId;
END;
GO

-- =============================================================
-- CARGA DE DATOS DE PRUEBA E INICIALIZACIÓN
-- =============================================================
EXEC usp_AddRobot 1, 'Brazo Antropomórfico A', 'Zona de Pintura', 'Operativo', 6, 1250.5;
EXEC usp_AddRobot 2, 'Manipulador SCARA B', 'Línea de Ensamble 2', 'Mantenimiento', 4, 850.0;
EXEC usp_AddRobot 3, 'Robot Cartesiano C', 'Estación de Empaque', 'Operativo', 3, 3100.2;
GO


-- Verificar y eliminar tablas existentes respetando el orden de dependencia (primero el detalle)
IF OBJECT_ID('dbo.MantenimientoDetalle', 'U') IS NOT NULL
    DROP TABLE MantenimientoDetalle;
GO

IF OBJECT_ID('dbo.Mantenimiento', 'U') IS NOT NULL
    DROP TABLE Mantenimiento;
GO

-- =============================================================
-- 1. CREACIÓN DE TABLAS (MAESTRO - DETALLE)
-- =============================================================

-- Tabla Maestro: Cabecera del Mantenimiento
CREATE TABLE Mantenimiento (
    MantenimientoId INT PRIMARY KEY IDENTITY(1,1),
    RobotId INT,
    FechaMantenimiento DATETIME DEFAULT GETDATE(),
    Tecnico NVARCHAR(100),
    TipoMantenimiento NVARCHAR(50), -- e.g., 'Preventivo', 'Correctivo', 'Calibración'
    FOREIGN KEY (RobotId) REFERENCES UnidadRobotica(RobotId)
);
GO

-- Tabla Detalle: Actividades específicas ejecutadas
CREATE TABLE MantenimientoDetalle (
    MantenimientoDetailId INT PRIMARY KEY IDENTITY(1,1),
    MantenimientoId INT,
    Actividad NVARCHAR(200), -- e.g., 'Lubricación de ejes', 'Calibración de home'
    DuracionMinutos INT,
    FOREIGN KEY (MantenimientoId) REFERENCES Mantenimiento(MantenimientoId)
);
GO

-- =============================================================
-- 2. PROCEDIMIENTOS ALMACENADOS (STORED PROCEDURES)
-- =============================================================

-- Procedimiento para registrar la Cabecera (Retorna el ID generado)
IF OBJECT_ID('dbo.usp_CreateMantenimiento', 'P') IS NOT NULL
    DROP PROCEDURE usp_CreateMantenimiento;
GO

CREATE PROCEDURE usp_CreateMantenimiento
    @RobotId INT,
    @Tecnico NVARCHAR(100),
    @TipoMantenimiento NVARCHAR(50),
    @MantenimientoId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Mantenimiento (RobotId, Tecnico, TipoMantenimiento)
    VALUES (@RobotId, @Tecnico, @TipoMantenimiento);

    -- Captura el último ID autogenerado por la identidad en esta sesión
    SET @MantenimientoId = SCOPE_IDENTITY();
END;
GO

-- Procedimiento para insertar cada Actividad en el Detalle
IF OBJECT_ID('dbo.usp_AddMantenimientoDetail', 'P') IS NOT NULL
    DROP PROCEDURE usp_AddMantenimientoDetail;
GO

CREATE PROCEDURE usp_AddMantenimientoDetail
    @MantenimientoId INT,
    @Actividad NVARCHAR(200),
    @DuracionMinutos INT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO MantenimientoDetalle (MantenimientoId, Actividad, DuracionMinutos)
    VALUES (@MantenimientoId, @Actividad, @DuracionMinutos);
END;
GO