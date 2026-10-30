--------------------------------------------------------------------------------
-- PROJECT: Asset Equipment Maintenance & Downtime Risk Engine
-- DATABASE: Predictive Maintenance Oil and Gas Pipeline Data
-- DESCRIPTION: End-to-end relational database architecture setup, table cleaning,
--              surrogate primary key generation, normalization, and foreign key binding.
--------------------------------------------------------------------------------

USE [Predictive Maintenance Oil and Gas Pipeline Data];
GO

-- 1. CLEANUP: Drop existing tables if re-running script
IF OBJECT_ID('dbo.PipelineInspections_Clean', 'U') IS NOT NULL
    DROP TABLE dbo.PipelineInspections_Clean;
GO

IF OBJECT_ID('dbo.PipelineAssetRegistry', 'U') IS NOT NULL
    DROP TABLE dbo.PipelineAssetRegistry;
GO

--------------------------------------------------------------------------------
-- 2. STAGING & CLEAN INSPECTION TABLE CREATION
-- Takes raw imported CSV data and generates an auto-incrementing primary key.
--------------------------------------------------------------------------------
SELECT 
    CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS INT) AS InspectionID,
    Pipe_Size_mm,
    Thickness_mm,
    Material,
    Grade,
    Max_Pressure_psi,
    Temperature_C,
    Corrosion_Impact_Percent,
    Thickness_Loss_mm,
    Material_Loss_Percent,
    Time_Years,
    Condition
INTO dbo.PipelineInspections_Clean
FROM dbo.market_pipe_thickness_loss_dataset;
GO

-- Lock down InspectionID as NOT NULL and set as Primary Key
ALTER TABLE dbo.PipelineInspections_Clean
ALTER COLUMN InspectionID INT NOT NULL;
GO

ALTER TABLE dbo.PipelineInspections_Clean
ADD CONSTRAINT PK_InspectionID PRIMARY KEY (InspectionID);
GO

--------------------------------------------------------------------------------
-- 3. NORMALIZATION: EQUIPMENT ASSET REGISTRY
-- Extracts unique pipe specifications into a master parent registry table.
--------------------------------------------------------------------------------
SELECT DISTINCT 
    CAST(ROW_NUMBER() OVER (ORDER BY Material, Grade, Pipe_Size_mm) AS INT) AS AssetID,
    CONCAT('PIPE-', CAST(ROW_NUMBER() OVER (ORDER BY Material, Grade, Pipe_Size_mm) AS VARCHAR(10))) AS AssetTag,
    Pipe_Size_mm,
    Thickness_mm AS InitialThickness_mm,
    Material,
    Grade,
    Max_Pressure_psi
INTO dbo.PipelineAssetRegistry
FROM dbo.PipelineInspections_Clean;
GO

-- Lock down AssetID as NOT NULL and set as Primary Key
ALTER TABLE dbo.PipelineAssetRegistry
ALTER COLUMN AssetID INT NOT NULL;
GO

ALTER TABLE dbo.PipelineAssetRegistry
ADD CONSTRAINT PK_AssetID PRIMARY KEY (AssetID);
GO

--------------------------------------------------------------------------------
-- 4. RELATIONAL ARCHITECTURE: FOREIGN KEY BINDING
-- Links inspection records back to the master asset registry table.
--------------------------------------------------------------------------------
-- Add AssetID foreign key column to inspection logs
ALTER TABLE dbo.PipelineInspections_Clean
ADD AssetID INT NULL;
GO

-- Populate the foreign key using matching asset specifications
UPDATE i
SET i.AssetID = r.AssetID
FROM dbo.PipelineInspections_Clean i
INNER JOIN dbo.PipelineAssetRegistry r
  ON i.Pipe_Size_mm = r.Pipe_Size_mm
  AND i.Material = r.Material
  AND i.Grade = r.Grade
  AND i.Thickness_mm = r.InitialThickness_mm;
GO

-- Enforce Referential Integrity via Foreign Key Constraint
ALTER TABLE dbo.PipelineInspections_Clean
ADD CONSTRAINT FK_Inspection_AssetRegistry 
FOREIGN KEY (AssetID) REFERENCES dbo.PipelineAssetRegistry(AssetID);
GO

PRINT 'Relational Database Architecture successfully built and verified for portfolio deployment!';
GO
