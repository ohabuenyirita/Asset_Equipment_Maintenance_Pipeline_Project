USE [Predictive Maintenance Oil and Gas Pipeline Data];
GO

-- PROJECT 1: Asset Equipment Maintenance & Downtime Risk Engine
-- Analytical Query 1: Dynamic Pipe Risk & Corrosion Severity Assessment

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
    
    -- Engineered Risk Score combining corrosion impact and material loss
    CAST((i.Corrosion_Impact_Percent * 0.6) + (i.Material_Loss_Percent * 0.4) AS DECIMAL(5,2)) AS CalculatedRiskScore,
    
    -- Automated Maintenance Priority Flag
    CASE 
        WHEN i.Material_Loss_Percent >= 30 OR i.Corrosion_Impact_Percent >= 15 THEN 'HIGH PRIORITY - Immediate Inspection'
        WHEN i.Material_Loss_Percent BETWEEN 15 AND 29 THEN 'MEDIUM PRIORITY - Schedule Monitoring'
        ELSE 'LOW PRIORITY - Stable Operation'
    END AS MaintenanceRecommendation

FROM dbo.PipelineInspections_Clean i
INNER JOIN dbo.PipelineAssetRegistry r
    ON i.AssetID = r.AssetID
ORDER BY CalculatedRiskScore DESC;
GO