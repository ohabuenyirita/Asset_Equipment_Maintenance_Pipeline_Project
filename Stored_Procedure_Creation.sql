USE [Predictive Maintenance Oil and Gas Pipeline Data];
GO

-- Drop the procedure if it already exists so we can safely re-create it
IF OBJECT_ID('dbo.sp_GetHighRiskPipelines', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetHighRiskPipelines;
GO

-- Create the Stored Procedure with an input parameter for Material Loss Threshold
CREATE PROCEDURE dbo.sp_GetHighRiskPipelines
    @MaterialLossThreshold DECIMAL(5,2) = 30.00 -- Default threshold set to 30%
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        r.AssetTag,
        r.Material,
        r.Grade,
        r.Pipe_Size_mm,
        r.Max_Pressure_psi,
        i.Time_Years,
        i.Thickness_Loss_mm,
        i.Material_Loss_Percent,
        i.Corrosion_Impact_Percent,
        i.Condition,
        
        -- Calculated Risk Score
        CAST((i.Corrosion_Impact_Percent * 0.6) + (i.Material_Loss_Percent * 0.4) AS DECIMAL(5,2)) AS CalculatedRiskScore,
        
        -- Actionable Status
        CASE 
            WHEN i.Material_Loss_Percent >= 40 THEN 'CRITICAL - Urgent Shutdown Required'
            ELSE 'HIGH - Schedule Maintenance'
        END AS RiskAction

    FROM dbo.PipelineInspections_Clean i
    INNER JOIN dbo.PipelineAssetRegistry r
        ON i.AssetID = r.AssetID
    WHERE i.Material_Loss_Percent >= @MaterialLossThreshold
    ORDER BY i.Material_Loss_Percent DESC;

END;
GO