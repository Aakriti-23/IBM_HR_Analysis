select * from ibm_hr_attrition;


-- Row count in main table
SELECT COUNT(*) FROM ibm_hr_attrition;

SELECT * FROM ibm_hr_attrition 
ORDER BY "Attrition_Probability" DESC 
LIMIT 10;


-- High-risk employees
SELECT COUNT(*) as high_risk_count 
FROM ibm_hr_attrition 
WHERE "Risk_Level" = 'High';


-- Department-wise risk summary
SELECT 
    "Department",
    COUNT(*) as total_employees,
    SUM(CASE WHEN "Risk_Level" = 'High' THEN 1 ELSE 0 END) as high_risk,
    ROUND(AVG("Attrition_Probability")::NUMERIC*100, 2) as avg_risk_score
FROM ibm_hr_attrition 
GROUP BY "Department" 
ORDER BY high_risk DESC;


-- High Risk Employees View
CREATE OR REPLACE VIEW high_risk_employees AS
SELECT 
    "Age",
    "Department",
    "JobRole",
    "MonthlyIncome",
    "OverTime",
    "YearsAtCompany",
    "MaritalStatus",
    "Attrition_Probability",
    "Risk_Level"
FROM ibm_hr_attrition
WHERE "Risk_Level" = 'High'
ORDER BY "Attrition_Probability" DESC;

SELECT * FROM high_risk_employees;


--Department Risk Summary View
CREATE OR REPLACE VIEW department_risk_summary AS
SELECT 
    "Department",
    COUNT(*) AS total_employees,
    SUM(CASE WHEN "Risk_Level" = 'High' THEN 1 ELSE 0 END) AS high_risk_count,
    ROUND(AVG("Attrition_Probability")::NUMERIC * 100, 2) AS avg_risk_score_percent,
    ROUND(
        100.0 * SUM(CASE WHEN "Risk_Level" = 'High' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS high_risk_percentage
FROM ibm_hr_attrition
GROUP BY "Department"
ORDER BY high_risk_percentage DESC;

select * from department_risk_summary;


-- Job Role Risk Summary View
CREATE OR REPLACE VIEW jobrole_risk_summary AS
SELECT 
    "JobRole",
    COUNT(*) AS total_employees,
    SUM(CASE WHEN "Risk_Level" = 'High' THEN 1 ELSE 0 END) AS high_risk_count,
    ROUND(AVG("Attrition_Probability")::NUMERIC * 100, 2) AS avg_risk_score_percent
FROM ibm_hr_attrition
GROUP BY "JobRole"
ORDER BY high_risk_count DESC;

select * from jobrole_risk_summary;


-- Attrition Risk by Age Group and Gender
SELECT
    "Age_Group",
    "Gender",
    COUNT(*) AS employees,
    ROUND(AVG("Attrition_Probability")::NUMERIC * 100,2) AS avg_risk_score,
    SUM(
        CASE
            WHEN "Risk_Level" = 'High' THEN 1
            ELSE 0
        END
    ) AS high_risk_count
FROM ibm_hr_attrition
GROUP BY "Age_Group", "Gender"
ORDER BY avg_risk_score DESC;


-- Work-life burnout analysis
SELECT
    "BusinessTravel",
    "OverTime",
    COUNT(*) AS employees,
    ROUND(AVG("Attrition_Probability")::NUMERIC * 100, 2) AS avg_attrition_risk
FROM ibm_hr_attrition
GROUP BY "BusinessTravel", "OverTime"
ORDER BY avg_attrition_risk DESC;


-- Income inequality inside departments
SELECT
    "Department",
    PERCENTILE_CONT(0.25)
        WITHIN GROUP (ORDER BY "MonthlyIncome") AS p25_salary,
    PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY "MonthlyIncome") AS median_salary,
    PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY "MonthlyIncome") AS p75_salary
FROM ibm_hr_attrition
GROUP BY "Department";

-- Top risky job roles within each department
WITH role_risk AS (
    SELECT
        "Department",
        "JobRole",
        ROUND(AVG("Attrition_Probability")::NUMERIC * 100, 2) AS avg_risk
    FROM ibm_hr_attrition
    GROUP BY "Department", "JobRole"
),
ranked AS (
    SELECT
        "Department",
        "JobRole",
        avg_risk,
        DENSE_RANK() OVER (PARTITION BY "Department" ORDER BY avg_risk DESC) AS risk_rank
    FROM role_risk
)

SELECT *
FROM ranked
WHERE risk_rank <= 3;


-- Department risk contribution %
WITH dept_risk AS (
    SELECT
        "Department",
        SUM("Attrition_Probability") AS total_risk
    FROM ibm_hr_attrition
    GROUP BY "Department"
),
company_total AS (
    SELECT
        SUM(total_risk) AS company_risk
    FROM dept_risk
)

SELECT
    d."Department",
    ROUND((d.total_risk / c.company_risk)::NUMERIC * 100, 2) AS company_risk_contribution_percent
FROM dept_risk d
CROSS JOIN company_total c
ORDER BY company_risk_contribution_percent DESC;
