--1
SELECT
     TABLE_SCHEMA
    ,TABLE_NAME
    ,TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;


--2
SELECT
     TABLE_NAME
    ,COLUMN_NAME
    ,DATA_TYPE
    ,CHARACTER_MAXIMUM_LENGTH
    ,IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
ORDER BY TABLE_NAME, ORDINAL_POSITION;


--3
SELECT 'dim_date' AS Table_Name, COUNT(*) AS Total_Rows
FROM dbo.dim_date

UNION ALL

SELECT 'dim_demographics', COUNT(*)
FROM dbo.dim_demographics

UNION ALL

SELECT 'dim_location', COUNT(*)
FROM dbo.dim_location

UNION ALL

SELECT 'dim_lifestyle', COUNT(*)
FROM dbo.dim_lifestyle

UNION ALL

SELECT 'dim_healthcare_access', COUNT(*)
FROM dbo.dim_healthcare_access

UNION ALL

SELECT 'dim_social_determinants', COUNT(*)
FROM dbo.dim_social_determinants

UNION ALL

SELECT 'fact_survey_response', COUNT(*)
FROM dbo.fact_survey_response;




--4 Full Survey Details

SELECT
     f.survey_response_key
    ,f.SEQNO
    ,d.full_date AS survey_date

    -- Demographics
    ,demo.SEXVAR
    ,demo._AGE80
    ,demo._RACE
    ,demo.EDUCA
    ,demo.EMPLOY1
    ,demo.INCOME3

    -- Location
    ,loc._STATE
    ,loc._METSTAT
    ,loc._URBSTAT

    -- Lifestyle
    ,life._SMOKER3
    ,life.DRNKANY6
    ,life.EXERANY2

    -- Healthcare Access
    ,hc.PRIMINS2
    ,hc.PERSDOC3
    ,hc.CHECKUP1

    -- Social Determinants
    ,sd.LSATISFY
    ,sd.SDLONELY
    ,sd.SDHFOOD1

    -- Health Outcomes
    ,f.DIABETE4
    ,f.CVDINFR4
    ,f.CVDCRHD4
    ,f.CVDSTRK3
    ,f.CHCKDNY2
    ,f.ADDEPEV3
    ,f.GENHLTH
    ,f.PHYSHLTH
    ,f.MENTHLTH
    ,f._BMI5

FROM dbo.fact_survey_response f

JOIN dbo.dim_demographics demo
    ON f.demographics_key = demo.demographics_key

JOIN dbo.dim_location loc
    ON f.location_key = loc.location_key

JOIN dbo.dim_lifestyle life
    ON f.lifestyle_key = life.lifestyle_key

JOIN dbo.dim_healthcare_access hc
    ON f.healthcare_access_key = hc.healthcare_access_key

JOIN dbo.dim_social_determinants sd
    ON f.social_determinants_key = sd.social_determinants_key

LEFT JOIN dbo.dim_date d
    ON f.date_key = d.date_key;


    --5  Respondents Distribution by Gender

SELECT
     demo.SEXVAR
    ,COUNT(*) AS Total_Respondents

FROM dbo.fact_survey_response f

JOIN dbo.dim_demographics demo
    ON f.demographics_key = demo.demographics_key

GROUP BY demo.SEXVAR

ORDER BY Total_Respondents DESC;



--6  Respondents Distribution by Age Group

SELECT
    CASE
        WHEN demo._AGE80 < 25 THEN 'Under 25'
        WHEN demo._AGE80 BETWEEN 25 AND 34 THEN '25-34'
        WHEN demo._AGE80 BETWEEN 35 AND 44 THEN '35-44'
        WHEN demo._AGE80 BETWEEN 45 AND 54 THEN '45-54'
        WHEN demo._AGE80 BETWEEN 55 AND 64 THEN '55-64'
        WHEN demo._AGE80 >= 65 THEN '65 and Above'
        ELSE 'Unknown'
    END AS Age_Group,

    COUNT(*) AS Total_Respondents

FROM dbo.fact_survey_response f

JOIN dbo.dim_demographics demo
    ON f.demographics_key = demo.demographics_key

GROUP BY
    CASE
        WHEN demo._AGE80 < 25 THEN 'Under 25'
        WHEN demo._AGE80 BETWEEN 25 AND 34 THEN '25-34'
        WHEN demo._AGE80 BETWEEN 35 AND 44 THEN '35-44'
        WHEN demo._AGE80 BETWEEN 45 AND 54 THEN '45-54'
        WHEN demo._AGE80 BETWEEN 55 AND 64 THEN '55-64'
        WHEN demo._AGE80 >= 65 THEN '65 and Above'
        ELSE 'Unknown'
    END

ORDER BY MIN(demo._AGE80);


--7  Chronic Diseases Distribution

SELECT
     'Diabetes' AS Disease
    ,DIABETE4 AS Response
    ,COUNT(*) AS Total_Respondents

FROM dbo.fact_survey_response

GROUP BY DIABETE4

UNION ALL

SELECT
     'Heart Attack'
    ,CVDINFR4
    ,COUNT(*)

FROM dbo.fact_survey_response

GROUP BY CVDINFR4

UNION ALL

SELECT
     'Coronary Heart Disease'
    ,CVDCRHD4
    ,COUNT(*)

FROM dbo.fact_survey_response

GROUP BY CVDCRHD4

UNION ALL

SELECT
     'Stroke'
    ,CVDSTRK3
    ,COUNT(*)

FROM dbo.fact_survey_response

GROUP BY CVDSTRK3

UNION ALL

SELECT
     'Kidney Disease'
    ,CHCKDNY2
    ,COUNT(*)

FROM dbo.fact_survey_response

GROUP BY CHCKDNY2

UNION ALL

SELECT
     'Depression'
    ,ADDEPEV3
    ,COUNT(*)

FROM dbo.fact_survey_response

GROUP BY ADDEPEV3

ORDER BY Disease, Response;


--8 . Smoking Status Distribution

SELECT
     life._SMOKER3
    ,COUNT(*) AS Total_Respondents
    ,AVG(f._BMI5) AS Average_BMI

FROM dbo.fact_survey_response f

JOIN dbo.dim_lifestyle life
    ON f.lifestyle_key = life.lifestyle_key

WHERE f._BMI5 IS NOT NULL

GROUP BY life._SMOKER3

ORDER BY Total_Respondents DESC;


--9  Healthcare Access and Diabetes

SELECT
     hc.PRIMINS2
    ,f.DIABETE4
    ,COUNT(*) AS Total_Respondents

FROM dbo.fact_survey_response f

JOIN dbo.dim_healthcare_access hc
    ON f.healthcare_access_key = hc.healthcare_access_key

GROUP BY
     hc.PRIMINS2
    ,f.DIABETE4

ORDER BY Total_Respondents DESC;


--10  Top 10 States by Respondents

SELECT TOP 10
     loc._STATE
    ,COUNT(*) AS Total_Respondents

FROM dbo.fact_survey_response f

JOIN dbo.dim_location loc
    ON f.location_key = loc.location_key

GROUP BY loc._STATE

ORDER BY Total_Respondents DESC;


--11 Average BMI by Age Group

SELECT
    CASE
        WHEN demo._AGE80 < 25 THEN 'Under 25'
        WHEN demo._AGE80 BETWEEN 25 AND 44 THEN '25-44'
        WHEN demo._AGE80 BETWEEN 45 AND 64 THEN '45-64'
        WHEN demo._AGE80 >= 65 THEN '65 and Above'
        ELSE 'Unknown'
    END AS Age_Group,

    COUNT(*) AS Total_Respondents,
    AVG(f._BMI5) AS Average_BMI

FROM dbo.fact_survey_response f

JOIN dbo.dim_demographics demo
    ON f.demographics_key = demo.demographics_key

WHERE f._BMI5 IS NOT NULL

GROUP BY
    CASE
        WHEN demo._AGE80 < 25 THEN 'Under 25'
        WHEN demo._AGE80 BETWEEN 25 AND 44 THEN '25-44'
        WHEN demo._AGE80 BETWEEN 45 AND 64 THEN '45-64'
        WHEN demo._AGE80 >= 65 THEN '65 and Above'
        ELSE 'Unknown'
    END

ORDER BY MIN(demo._AGE80);



--12 CTE: Top 5 States for Diabetes Responses

WITH StateDiabetes AS
(
    SELECT
         loc._STATE
        ,COUNT(*) AS Total_Respondents

    FROM dbo.fact_survey_response f

    JOIN dbo.dim_location loc
        ON f.location_key = loc.location_key

    WHERE f.DIABETE4 IS NOT NULL

    GROUP BY loc._STATE
),

RankedStates AS
(
    SELECT
         _STATE
        ,Total_Respondents

        ,ROW_NUMBER() OVER
        (
            ORDER BY Total_Respondents DESC
        ) AS State_Rank

    FROM StateDiabetes
)

SELECT
     _STATE
    ,Total_Respondents
    ,State_Rank

FROM RankedStates

WHERE State_Rank <= 5

ORDER BY State_Rank;




-- Report 1: Chronic Disease Distribution

SELECT
     'Diabetes' AS Disease
    ,COUNT(*) AS Total_Records
    ,SUM(CASE WHEN DIABETE4 = 'Yes' THEN 1 ELSE 0 END)
        AS Yes_Count

FROM dbo.fact_survey_response

UNION ALL

SELECT
     'Heart Attack'
    ,COUNT(*)
    ,SUM(CASE WHEN CVDINFR4 = 'Yes' THEN 1 ELSE 0 END)

FROM dbo.fact_survey_response

UNION ALL

SELECT
     'Stroke'
    ,COUNT(*)
    ,SUM(CASE WHEN CVDSTRK3 = 'Yes' THEN 1 ELSE 0 END)

FROM dbo.fact_survey_response

UNION ALL

SELECT
     'Kidney Disease'
    ,COUNT(*)
    ,SUM(CASE WHEN CHCKDNY2 = 'Yes' THEN 1 ELSE 0 END)

FROM dbo.fact_survey_response

UNION ALL

SELECT
     'Depression'
    ,COUNT(*)
    ,SUM(CASE WHEN ADDEPEV3 = 'Yes' THEN 1 ELSE 0 END)

FROM dbo.fact_survey_response;



-- Report 2: Risk Factors Analysis

SELECT
     life._SMOKER3 AS Smoking_Status
    ,life.EXERANY2 AS Physical_Activity
    ,COUNT(*) AS Total_Respondents
    ,AVG(f._BMI5) AS Average_BMI

FROM dbo.fact_survey_response f

JOIN dbo.dim_lifestyle life
    ON f.lifestyle_key = life.lifestyle_key

WHERE f._BMI5 IS NOT NULL

GROUP BY
     life._SMOKER3
    ,life.EXERANY2

ORDER BY Total_Respondents DESC;




-- Report 3: Diabetes by Age and Gender

SELECT
     demo.SEXVAR
    ,CASE
        WHEN demo._AGE80 < 35 THEN 'Under 35'
        WHEN demo._AGE80 BETWEEN 35 AND 54 THEN '35-54'
        WHEN demo._AGE80 BETWEEN 55 AND 64 THEN '55-64'
        WHEN demo._AGE80 >= 65 THEN '65 and Above'
        ELSE 'Unknown'
     END AS Age_Group

    ,COUNT(*) AS Total_Respondents

FROM dbo.fact_survey_response f

JOIN dbo.dim_demographics demo
    ON f.demographics_key = demo.demographics_key

WHERE f.DIABETE4 IS NOT NULL

GROUP BY
     demo.SEXVAR,
     CASE
        WHEN demo._AGE80 < 35 THEN 'Under 35'
        WHEN demo._AGE80 BETWEEN 35 AND 54 THEN '35-54'
        WHEN demo._AGE80 BETWEEN 55 AND 64 THEN '55-64'
        WHEN demo._AGE80 >= 65 THEN '65 and Above'
        ELSE 'Unknown'
     END

ORDER BY Age_Group, demo.SEXVAR;