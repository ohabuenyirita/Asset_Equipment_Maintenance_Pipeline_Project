USE [Predictive Maintenance Oil and Gas Pipeline Data];
GO

-- PROJECT 1: Asset Equipment Maintenance & Downtime Risk Engine
-- Analytical Query 2: Fleet-Level Material Risk & Aggregated Corrosion Metrics

SELECT 
    r.Material,
    r.Grade,
    COUNT(DISTINCT r.AssetID) AS TotalUniqueAssets,
    COUNT(i.InspectionID) AS TotalInspectionsCount,
    CAST(AVG(i.Corrosion_Impact_Percent) AS DECIMAL(5,2)) AS AvgCorrosionImpactPct,
    CAST(AVG(i.Material_Loss_Percent) AS DECIMAL(5,2)) AS AvgMaterialLossPct,
    MAX(i.Time_Years) AS MaxOperatingYears,
    
    -- Fleet Health Grouping
    SUM(CASE WHEN i.Condition = 'Critical' THEN 1 ELSE 0 END) AS CriticalConditionCount,
    SUM(CASE WHEN i.Condition = 'Moderate' THEN 1 ELSE 0 END) AS ModerateConditionCount

FROM dbo.PipelineAssetRegistry r
INNER JOIN dbo.PipelineInspections_Clean i
    ON r.AssetID = i.AssetID
GROUP BY r.Material, r.Grade
ORDER BY AvgMaterialLossPct DESC;
GO