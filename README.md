# 🛢️ Asset Equipment Maintenance & Downtime Risk Engine

A comprehensive relational database architecture, dynamic risk scoring framework, and automated stored procedure pipeline engineered in SQL Server for heavy equipment maintenance and operational risk management across oil & gas pipeline networks.

---

## 📌 Project Overview

Unplanned equipment failures and pipeline degradation pose substantial operational, environmental, and financial risks in industrial energy transportation. This project establishes an end-to-end data processing and analytical engine in T-SQL to normalize raw sensor telemetry, aggregate fleet-level maintenance metrics, calculate dynamic multi-variable failure risk scores, and encapsulate decision-support queries within automated stored procedures.

---

## 🛠️ Tech Stack & Key Methods

* **Database Engine:** Microsoft SQL Server (SSMS / T-SQL)
* **Data Architecture:** 1NF/2NF/3NF Relational Normalization & Staging Transformations
* **Analytics & Modeling:** Window Functions, Dynamic Multi-Tier Risk Scoring Logic, Conditional Aggregations (`CASE WHEN`)
* **Automation:** Parameterized Staging Stored Procedures for Programmatic Execution

---

## 📁 Repository Structure & Script Pipeline

The repository is organized into distinct, modular SQL scripts following a production-grade data pipeline workflow:

```text
Asset_Equipment_Maintenance_Pipeline_Project/
├── 📄 Oil_Gas_Pipeline_Normalization.sql
├── 📄 Fleet_Level_Aggregations.sql
├── 📄 Pipeline_Risk_Scoring_Query.sql
├── 📄 Stored_Procedure_Creation.sql
├── 📄 Stored_Procedure_Test_Execution.sql
└── 📄 README.md