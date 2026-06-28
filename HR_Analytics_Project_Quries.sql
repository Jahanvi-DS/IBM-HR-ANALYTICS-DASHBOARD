CREATE DATABASE hr_new_project;
USE hr_new_project;
SELECT * FROM hr_raw_data

-- Star Schema

CREATE TABLE Dim_Employee AS
SELECT 
    EmployeeNumber,
    Gender,
    MaritalStatus,
    Education,
    EducationField,
    NumCompaniesWorked,
    TotalWorkingYears
FROM hr_raw_data;

CREATE TABLE Dim_JobProfile AS
SELECT 
    EmployeeNumber,
    Department,
    JobRole,
    JobLevel,
    BusinessTravel,
    DistanceFromHome,
    OverTime
FROM hr_raw_data;

CREATE TABLE Fact_Attrition AS
SELECT 
    EmployeeNumber,
    Attrition,
    DailyRate,
    HourlyRate,
    MonthlyIncome,
    MonthlyRate,
    PercentSalaryHike,
    StockOptionLevel,
    YearsAtCompany,
    YearsInCurrentRole,
    YearsSinceLastPromotion,
    YearsWithCurrManager
FROM hr_raw_data;

-- Department Wise Attrition Rate
SELECT 
    p.Department,
    COUNT(f.EmployeeNumber) AS Total_Employees,
    SUM(CASE WHEN f.Attrition = 'Yes' THEN 1 ELSE 0 END) AS Total_Left,
    ROUND((SUM(CASE WHEN f.Attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(f.EmployeeNumber)) * 100, 2) AS Attrition_Rate_Percent
FROM Fact_Attrition f
JOIN Dim_JobProfile p ON f.EmployeeNumber = p.EmployeeNumber
GROUP BY p.Department
ORDER BY Attrition_Rate_Percent DESC;

-- Overtime vs Income Attrition Analysis
SELECT 
    p.OverTime,
    CASE 
        WHEN f.MonthlyIncome < 5000 THEN 'Low Income (<5k)'
        WHEN f.MonthlyIncome BETWEEN 5000 AND 10000 THEN 'Medium Income (5k-10k)'
        ELSE 'High Income (>10k)'
    END AS Income_Band,
    COUNT(*) AS Total_Staff,
    SUM(CASE WHEN f.Attrition = 'Yes' THEN 1 ELSE 0 END) AS Left_Staff,
    ROUND((SUM(CASE WHEN f.Attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS Attrition_Rate
FROM Fact_Attrition f
JOIN Dim_JobProfile p ON f.EmployeeNumber = p.EmployeeNumber
GROUP BY p.OverTime, Income_Band
ORDER BY p.OverTime, Attrition_Rate DESC;

-- High Attrition Roles Ranking
WITH RoleAttrition AS (
    SELECT 
        p.Department,
        p.JobRole,
        COUNT(*) AS Total_Employees,
        SUM(CASE WHEN f.Attrition = 'Yes' THEN 1 ELSE 0 END) AS Total_Left,
        ROUND((SUM(CASE WHEN f.Attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS Attrition_Rate
    FROM Fact_Attrition f
    JOIN Dim_JobProfile p ON f.EmployeeNumber = p.EmployeeNumber
    GROUP BY p.Department, p.JobRole
)
SELECT 
    Department,
    JobRole,
    Attrition_Rate,
    DENSE_RANK() OVER (PARTITION BY Department ORDER BY Attrition_Rate DESC) AS Attrition_Rank
FROM RoleAttrition;