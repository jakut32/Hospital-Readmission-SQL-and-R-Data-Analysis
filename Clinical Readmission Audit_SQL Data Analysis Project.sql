-- 1. Create a workspace for my project
CREATE DATABASE hospital_audit;
USE hospital_audit;
-- turned table into text to reduce upload errors
CREATE TABLE diabetic_data (
    encounter_id TEXT, patient_nbr TEXT, race TEXT, gender TEXT, age TEXT, weight TEXT,
    admission_type_id TEXT, discharge_disposition_id TEXT, admission_source_id TEXT,
    time_in_hospital TEXT, payer_code TEXT, medical_specialty TEXT, num_lab_procedures TEXT,
    num_procedures TEXT, num_medications TEXT, number_outpatient TEXT, number_emergency TEXT,
    number_inpatient TEXT, diag_1 TEXT, diag_2 TEXT, diag_3 TEXT, number_diagnoses TEXT,
    max_glu_serum TEXT, A1Cresult TEXT, metformin TEXT, repaglinide TEXT, nateglinide TEXT,
    chlorpropamide TEXT, glimepiride TEXT, acetohexamide TEXT, glipizide TEXT, glyburide TEXT,
    tolbutamide TEXT, pioglitazone TEXT, rosiglitazone TEXT, acarbose TEXT, miglitol TEXT,
    troglitazone TEXT, tolazamide TEXT, examide TEXT, citoglipton TEXT, insulin TEXT,
    `glyburide-metformin` TEXT, `glipizide-metformin` TEXT, `glimepiride-pioglitazone` TEXT,
    `metformin-rosiglitazone` TEXT, `metformin-pioglitazone` TEXT, `change` TEXT,
    diabetesMed TEXT, readmitted TEXT
);
SET GLOBAL LOCAL_INFILE =1;
SHOW VARIABLES LIKE "secure_file_priv"; -- could not import local file data so i asked sql to bring a securE file loaction since it says i can execute because its runnin on secure file piv
-- -- 2. Import the actual CSV file from your local computer
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\diabetic_data.csv' 
INTO TABLE diabetic_data -- Specifies which table to dump the data into
FIELDS TERMINATED BY ',' -- -- Tells SQL that each column is separated by a comma (CSV format)
OPTIONALLY ENCLOSED BY '"' -- Handles data values that might have quotes around them
LINES TERMINATED BY '\n' -- Tells SQL that a new line in the file represents a new row
IGNORE 1 ROWS; -- Skips the first row (the header) so column names aren't imported as data

-- 2. Check the count 
SELECT COUNT(*) FROM diabetic_data;


/* DATA CLEANING PHASE
Purpose: Transform the raw 'Text' import into a structured, analysis-ready table.
creating a VIEW so I don't change the raw data, but I see a 'clean' version of it.
*/


CREATE OR REPLACE VIEW cleaned_diabetic_data AS
SELECT 
 -- 1. Convert IDs to Integers for faster indexing
    CAST(encounter_id AS UNSIGNED) AS encounter_id,
    CAST(patient_nbr AS UNSIGNED) AS patient_id,
    
     -- 2. Handling Missing Categories
    -- If race is '?', we label it 'Unknown' for professional reporting
    CASE WHEN race = '?' THEN 'Unknown' ELSE race END AS race,
    
    gender,
    
    age,
    
    
      -- 3. Weight is 98% missing, so we convert '?' to NULL
    -- NULL is better than '?' because SQL math functions (like AVG) ignore NULLs
    CASE WHEN weight = '?' THEN NULL ELSE weight END AS weight,
    
      -- 4. Convert Stay Time to a Number so we can calculate averages
    CAST(time_in_hospital AS UNSIGNED) AS stay_duration,
    
    
    -- 5. Clean Medical Specialty
    CASE WHEN medical_specialty = '?' THEN 'Unspecified' ELSE medical_specialty END AS specialty,
    
    
     -- 6. Convert Lab Procedures to a Number for correlation analysis
    CAST(num_lab_procedures AS UNSIGNED) AS num_lab_procedures,
    
    CAST(number_diagnoses AS UNSIGNED) AS num_diagnoses, 
    
    insulin, 
    -- 7. Standardize Diagnosis Codes (fixing the '?' placeholders)
    CASE WHEN diag_1 = '?' THEN 'Unknown' ELSE diag_1 END AS primary_diagnosis,
    CASE WHEN diag_2 = '?' THEN 'Unknown' ELSE diag_2 END AS secondary_diagnosis,
    
    readmitted
    
FROM diabetic_data;

-- check if all columns are present
SELECT 
    race, 
    age, 
    specialty, 
    insulin, 
    num_diagnoses, 
    readmitted 
FROM cleaned_diabetic_data 
LIMIT 5;


/* Q1: Departmental Risk Audit (Specialty)
Purpose: To identify which hospital departments have the highest readmission rates to help management improve discharge protocols.
*/

SELECT 
    specialty, -- The medical department 
    COUNT(*) AS total_visits, -- Total patient volume for that department
    -- Calculate % of patients returning within 30 days
    ROUND(AVG(CASE WHEN readmitted LIKE '%<30%' THEN 1.0 ELSE 0.0 END) * 100, 2) AS readmit_rate
FROM cleaned_diabetic_data -- Pull from our cleaned VIEW
WHERE specialty != 'Unspecified' -- Remove rows where specialty is missing
GROUP BY specialty -- Group results by department
HAVING total_visits > 100 -- Ensure we only look at high-volume departments
ORDER BY readmit_rate DESC; -- Sort by highest risk first

/* Q2: Patient Complexity Analysis (Diagnoses)
Purpose: To determine if patients with multiple underlying health conditions (Comorbidities) are more likely to return.
*/

SELECT 
    CASE WHEN num_diagnoses <= 4 THEN 'Simple (1-4)' -- Grouping by health complexity
         WHEN num_diagnoses BETWEEN 5 AND 8 THEN 'Moderate (5-8)' 
         ELSE 'Complex (9+)' END AS complexity,
    -- Calculate readmission percentage for each complexity level
    ROUND(AVG(CASE WHEN readmitted LIKE '%<30%' THEN 1.0 ELSE 0.0 END) * 100, 2) AS readmit_rate
FROM cleaned_diabetic_data
GROUP BY complexity -- Group by our new complexity buckets
ORDER BY readmit_rate DESC; -- Show the most "fragile" groups at the top

/* Q3: Medication Stability Analysis (Insulin)
Purpose: To see if changing a patient's insulin dose right before discharge increases their risk of returning.
*/
SELECT 
    insulin, -- The insulin dosage trend (Up, Down, Steady, No)
    -- Probability of returning within 30 days based on dosage change
    ROUND(AVG(CASE WHEN readmitted LIKE '%<30%' THEN 1.0 ELSE 0.0 END) * 100, 2) AS readmit_rate
FROM cleaned_diabetic_data
GROUP BY insulin -- Group by the medication trend
ORDER BY readmit_rate DESC; -- Identify if "Up/Down" changes cause more risk


/* Q4: Acuity & Lab Intensity Analysis
Purpose: To find out if a high number of lab tests (indicating a serious hospital stay) correlates with a longer recovery time.
*/
SELECT 
    CASE WHEN num_lab_procedures < 30 THEN 'Low (0-29)' -- Segmenting by lab volume
         WHEN num_lab_procedures BETWEEN 30 AND 60 THEN 'Med (30-60)' 
         ELSE 'High (60+)' END AS lab_intensity,
    ROUND(AVG(stay_duration), 2) AS avg_stay -- Calculate average days in hospital
FROM cleaned_diabetic_data
GROUP BY lab_intensity -- Group by the intensity of the care received
ORDER BY avg_stay DESC; -- Show which intensity level stays the longest

/* Q5: Age-Based Vulnerability Audit
Purpose: To identify which life stages are most at risk, specifically looking for trends in younger vs. older diabetic patients.
*/
SELECT 
    age, 
    -- Calculate the readmission percentage for each age group
    ROUND(AVG(CASE WHEN readmitted LIKE '%<30%' THEN 1.0 ELSE 0.0 END) * 100, 2) AS readmit_rate
FROM cleaned_diabetic_data
GROUP BY age -- Group by age bracket
ORDER BY readmit_rate DESC; -- Find the most vulnerable age group

/*
Q6: Demographic Disparity Audit (Race)
Purpose: To uncover potential gaps in healthcare outcomes that may be caused by social or economic barriers.
*/
SELECT 
    race,-- The ethnic demographic
    -- Calculate the readmission percentage per demographic
    ROUND(AVG(CASE WHEN readmitted LIKE '%<30%' THEN 1.0 ELSE 0.0 END) * 100, 2) AS readmit_rate
FROM cleaned_diabetic_data
WHERE race != 'Unknown' -- Filter out rows with missing race data
GROUP BY race -- Group by racial background
ORDER BY readmit_rate DESC; -- Sort to identify disparities in care outcomes





/* ANALYSIS: RACE VS COMPLEXITY 
   Purpose: To see if Caucasians have higher readmission because 
   they have more diagnoses (Complexity) or are older.
*/
--  Seein what race has more elderly people so readmits is up usin num of diagnosis and age
SELECT 
    race,
    AVG(num_diagnoses) AS avg_illnesses, -- Are they sicker?
    ROUND(AVG(CASE WHEN age IN ('[70-80)', '[80-90)', '[90-100)') THEN 1 ELSE 0 END) * 100, 2) AS percent_elderly,
    ROUND(AVG(CASE WHEN readmitted LIKE '%<30%' THEN 1.0 ELSE 0.0 END) * 100, 2) AS readmit_rate
FROM cleaned_diabetic_data
GROUP BY race;