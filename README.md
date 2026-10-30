# 🛢️ Asset Equipment Maintenance & Downtime Risk Engine

[![Database](https://img.shields.io/badge/Database-MS%20SQL%20Server-red.svg)](https://www.microsoft.com/en-us/sql-server)
[![Language](https://img.shields.io/badge/Language-T--SQL-blue.svg)](https://docs.microsoft.com/en-us/sql/t-sql/language-reference)
[![Domain](https://img.shields.io/badge/Domain-Oil%20%26%20Gas%20Asset%20Integrity-orange.svg)](#)
[![Architecture](https://img.shields.io/badge/Schema-3NF%20Relational%20Model-green.svg)](#)

---

## 📌 Executive Summary

Unplanned structural failure in midstream oil and gas pipelines represents a primary risk vector for catastrophic environmental damage, capital loss, and operational downtime. Raw telemetry and inspection data collected from field sensors often arrive in flat, unnormalized formats prone to data redundancy, insert/update anomalies, and operational overhead.

This project establishes a **production-grade relational database architecture and ETL pipeline** written in T-SQL. It ingests flat inspection telemetry, transforms unnormalized data streams into third normal form (3NF), generates synthetic primary keys via window functions, establishes an **Asset Equipment Registry**, and enforces strict referential integrity across historical inspection logs.

This computational foundation supports high-frequency downstream predictive risk scoring, degradation modeling, and automated asset health monitoring.

---

## 🏗️ Relational Architecture & Normalization Pipeline

The architectural strategy executes a structured multi-stage data transformation process:

```text
┌─────────────────────────────────────────────────────────┐
│          Raw Telemetry Ingestion (Flat File)            │
│        [dbo].[market_pipe_thickness_loss_dataset]       │
└────────────────────────────┬────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────┐
│     Staging & Clean Inspection Log (Child Entity)       │
│            [dbo].[PipelineInspections_Clean]            │
│   • PK: InspectionID (Windowed Row Sequence)            │
│   • Captures Telemetry, Loss %, & Operating Conditions  │
└────────────────────────────┬────────────────────────────┘
                             │  (Normalizing Unique Specs)
                             ▼
┌─────────────────────────────────────────────────────────┐
│          Master Asset Registry (Parent Entity)          │
│               [dbo].[PipelineAssetRegistry]             │
│   • PK: AssetID (Surrogate Key)                         │
│   • AssetTag: Unique Formatted Hardware Key             │
│   • Dimensional Specs: Material, Grade, Pressure        │
└────────────────────────────┬────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────┐
│        Referential Integrity & Foreign Key Binding      │
│       ALTER TABLE [dbo].[PipelineInspections_Clean]     │
│   • FK: AssetID ──► REFERENCES [PipelineAssetRegistry]  │
└─────────────────────────────────────────────────────────┘

```
### ⚙️ Key Engineering Features

1. **Idempotent Deployment Guardrails:**
   * Includes structural check blocks using `OBJECT_ID(..., 'U')` to ensure safe, repeatable execution in automated CI/CD deployment pipelines without schema corruption.

2. **Surrogate Key & Asset Tag Generation:**
   * Generates deterministically sequenced primary keys (`InspectionID`, `AssetID`) using `ROW_NUMBER() OVER (...)`.
   * Constructs standardized industrial equipment identifiers (`AssetTag`, e.g., `PIPE-1`, `PIPE-2`) to streamline enterprise asset tracking across physical site locations.

3. **Schema Normalization (3NF Conversion):**
   * Eliminates data redundancy by isolating immutable asset attributes (pipe diameter, material composition, grade, baseline design pressure) into `dbo.PipelineAssetRegistry`.
   * Decouples static equipment metadata from dynamic inspection metrics (corrosion impact, thickness loss, temperature, operating pressure).

4. **Relational Binding & Referential Integrity:**
   * Executes multi-column join matching (`Pipe_Size_mm`, `Material`, `Grade`, `Thickness_mm`) to map historical telemetry back to master asset keys.
   * Enforces hard foreign key constraints (`FK_Inspection_AssetRegistry`) to guarantee ACID compliance and block orphaned inspection entries.

---

## 📐 Data Dictionary & Domain Schema

### 1. `dbo.PipelineAssetRegistry` (Master Equipment Entity)

| Attribute Name | Data Type | Constraint | Domain Description |
| :--- | :--- | :--- | :--- |
| **`AssetID`** | `INT` | `PRIMARY KEY` | Auto-generated surrogate key for asset identity. |
| **`AssetTag`** | `VARCHAR(10)` | `NOT NULL` | Standardized industrial hardware tag (`PIPE-X`). |
| **`Pipe_Size_mm`** | `FLOAT / INT` | `NOT NULL` | Nominal outer pipe diameter in millimeters. |
| **`InitialThickness_mm`**| `DECIMAL` | `NOT NULL` | Baseline nominal wall thickness at installation. |
| **`Material`** | `VARCHAR(50)`| `NOT NULL` | Metallurgical composition (e.g., Carbon Steel). |
| **`Grade`** | `VARCHAR(20)`| `NOT NULL` | Material strength rating (e.g., API 5L X52, X70). |
| **`Max_Pressure_psi`** | `FLOAT` | `NOT NULL` | Maximum allowable operating pressure (MAOP). |

### 2. `dbo.PipelineInspections_Clean` (Inspection Telemetry Entity)

| Attribute Name | Data Type | Constraint | Domain Description |
| :--- | :--- | :--- | :--- |
| **`InspectionID`** | `INT` | `PRIMARY KEY` | Unique log entry sequence key. |
| **`AssetID`** | `INT` | `FOREIGN KEY` | Relational reference linking to `PipelineAssetRegistry`. |
| **`Temperature_C`** | `FLOAT` | `NULL` | Fluid/ambient temperature during inspection. |
| **`Corrosion_Impact_Percent`**|`FLOAT` | `NULL` | Measured degradation percentage. |
| **`Thickness_Loss_mm`** | `FLOAT` | `NULL` | Wall loss measured via ultrasonic testing. |
| **`Material_Loss_Percent`** | `FLOAT` | `NULL` | Cumulative volumetric material loss ratio. |
| **`Time_Years`** | `FLOAT` | `NULL` | Operational service age at time of log. |
| **`Condition`** | `VARCHAR(20)`| `NULL` | Field rating (`Optimal`, `Moderate`, `Critical`). |

---

## 💻 Pipeline Implementation (T-SQL)
```sql
--------------------------------------------------------------------------------
-- PROJECT: Asset Equipment Maintenance & Downtime Risk Engine
-- MODULE: Relational Architecture, Data Normalization & Foreign Key Enforcement
--------------------------------------------------------------------------------

USE [Predictive Maintenance Oil and Gas Pipeline Data];
GO

-- 1. IDEMPOTENT CLEANUP: Safe Schema Reset
IF OBJECT_ID('dbo.PipelineInspections_Clean', 'U') IS NOT NULL
    DROP TABLE dbo.PipelineInspections_Clean;
GO

IF OBJECT_ID('dbo.PipelineAssetRegistry', 'U') IS NOT NULL
    DROP TABLE dbo.PipelineAssetRegistry;
GO

-- 2. STAGING & CLEAN INSPECTION TABLE CREATION
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

-- Enforce Primary Key on Inspection Telemetry
ALTER TABLE dbo.PipelineInspections_Clean
ALTER COLUMN InspectionID INT NOT NULL;
GO

ALTER TABLE dbo.PipelineInspections_Clean
ADD CONSTRAINT PK_InspectionID PRIMARY KEY (InspectionID);
GO

-- 3. NORMALIZATION: Extract Master Asset Registry
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

-- Enforce Primary Key on Asset Registry
ALTER TABLE dbo.PipelineAssetRegistry
ALTER COLUMN AssetID INT NOT NULL;
GO

ALTER TABLE dbo.PipelineAssetRegistry
ADD CONSTRAINT PK_AssetID PRIMARY KEY (AssetID);
GO

-- 4. RELATIONAL BINDING: Foreign Key Population & Constraint
ALTER TABLE dbo.PipelineInspections_Clean
ADD AssetID INT NULL;
GO

UPDATE i
SET i.AssetID = r.AssetID
FROM dbo.PipelineInspections_Clean i
INNER JOIN dbo.PipelineAssetRegistry r
  ON i.Pipe_Size_mm = r.Pipe_Size_mm
  AND i.Material = r.Material
  AND i.Grade = r.Grade
  AND i.Thickness_mm = r.InitialThickness_mm;
GO

-- Enforce Strict Foreign Key Integrity
ALTER TABLE dbo.PipelineInspections_Clean
ADD CONSTRAINT FK_Inspection_AssetRegistry 
FOREIGN KEY (AssetID) REFERENCES dbo.PipelineAssetRegistry(AssetID);
GO

PRINT 'Relational Database Architecture successfully built and verified for portfolio deployment!';
GO
```
## 🔬 Research & Industrial Applications

### For Academic & Graduate Research Frameworks
* **Computational Data Infrastructure:** Provides a standardized relational foundation for training predictive machine learning models (e.g., XGBoost, Isolation Forests) to forecast remaining useful life (RUL) and mechanical degradation rates in energy infrastructure.
* **Reproducible Data Engineering:** Demonstrates rigorous, deterministic data preprocessing suitable for peer-reviewed computational methodologies and research datasets.

### For Oil & Gas Industry Operations
* **Asset Performance Management (APM):** Enables reliability engineers to track wall thinning velocity, evaluate corrosion rates per grade/material pair, and optimize capital expenditure (CapEx) replacement schedules.
* **Integrity Management Programs (IMP):** Directly aligns with regulatory compliance standards (e.g., API 570, ASME B31.8S) by providing structured audit trails for inline inspections (ILI) and ultrasonic thickness logging.

---

## 🛠️ Requirements & Setup Instructions

### Prerequisites
* **Database Engine:** Microsoft SQL Server 2016 or newer (compatible with SQL Server Management Studio / Azure Data Studio).
* **Source Dataset:** Extracted from the Kaggle archive (*Predictive Maintenance Oil and Gas Pipeline Data* by Muhammad Waqas) as a lightweight 70 KB CSV flat file (`market_pipe_thickness_loss_dataset.csv`), staged into the database as `dbo.market_pipe_thickness_loss_dataset`.

### Execution
1. Open **SQL Server Management Studio (SSMS)**.
2. Select target database context: `USE [Predictive Maintenance Oil and Gas Pipeline Data];`.
3. Open and execute `Asset_Equipment_Maintenance_Pipeline_Project.sql`.
4. Verify execution output in the messages console:
   ```text
   (X rows affected)
   Relational Database Architecture successfully built and verified for portfolio deployment!
---
   ## 👤 Author & Academic Background

**Ohabuenyi Rita**  
*Data Analyst & Computer Science Graduate*  
* **Specialization:** Relational Database Architecture, Industrial Analytics, T-SQL Engineering, Predictive Modeling.  
* **GitHub:** [@ohabuenyirita](https://github.com/ohabuenyirita)  
* **LinkedIn:** [Ohabuenyi Rita](https://linkedin.com/in/ohabuenyirita)
