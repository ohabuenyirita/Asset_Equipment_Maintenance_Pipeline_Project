USE [Predictive Maintenance Oil and Gas Pipeline Data];
GO

-- Test 1: Find all pipelines with 45% or higher material loss
EXEC dbo.sp_GetHighRiskPipelines @MaterialLossThreshold = 45.00;
GO

-- Test 2: Find extremely critical pipelines with 60% or higher material loss
EXEC dbo.sp_GetHighRiskPipelines @MaterialLossThreshold = 60.00;
GO