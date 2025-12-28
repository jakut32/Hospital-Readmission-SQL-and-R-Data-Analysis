# Hospital-Readmission-SQL-Audit
SQL analysis of 100k+ diabetic clinical records to identify 30-day readmission risks.
# 🏥 Hospital Readmission Clinical Audit (SQL)

## 📌 Project Overview
This project performs a deep-dive audit into 101,766 diabetic patient encounters across 130 US hospitals (1999-2008). The goal is to identify why patients return within 30 days and provide data-driven recommendations for hospital discharge protocols.

---

## 📊 Key Clinical Findings

### 1. The "Down" Insulin Effect (Medication Stability)
**Finding:** Patients whose insulin dosage was **decreased (Down)** right before discharge had the highest readmission rates.
**Insight:** A dosage reduction usually follows a "sugar crash" (Hypoglycemia). These patients are metabolically unstable and require more supervision than those on a "Steady" dose.



### 2. Systemic Frailty (Complexity)
**Finding:** Patients with **9+ diagnoses** are significantly more likely to return.
**Insight:** High comorbidity indicates systemic frailty. These patients aren't just diabetic; they are managing multiple failing organs, making post-discharge recovery difficult.



### 3. Demographic Risk (Age 20-30)
**Finding:** Younger adults (20-30) show a spike in readmission risk.
**Insight:** This is often due to the "Transition Gap"—moving from parental/pediatric care to independent management, combined with higher metabolic activity and potential economic barriers to medication.



---

## 💻 Technical Implementation
- **ETL Pipeline:** Configured `secure_file_priv` for bulk CSV loading into MySQL.
- **Data Cleaning:** Built a `VIEW` to handle missing `?` values and cast `TEXT` data into `UNSIGNED` integers for calculation.
- **Aggregations:** Utilized `CASE` statements and `AVG()` to calculate precise readmission percentages across 100k+ rows.

---

## 💡 Strategic Recommendations
1. **Hypoglycemia Protocol:** Mandatory 48-hour follow-up for any patient discharged after a "Down" insulin adjustment.
2. **Specialty Focus:** Internal Medicine and Oncology departments should implement "Transition Coaches" for high-complexity patients.
3. **Resource Allocation:** Prioritize discharge planning for patients with 9+ diagnoses regardless of their primary reason for admission.
4. ## 🛠️ Data Analysis Pipeline (R)
After establishing the SQL database, I used R for advanced cleaning and statistical testing:
- **handshake:** Connected R to MySQL using the `DBI` package.
- **Cleaning:** Used `str_trim` to remove hidden `\r` characters that were affecting data accuracy.
- **Visualization:** Generated professional charts to communicate clinical risks.

## 📊 Visual Insights
### Clinical Audit: Age vs. Readmission
![Bar Chart](https://github.com/jakut32/Hospital-Readmission-SQL-Audit/blob/main/R_Analysis/age_readmission_bar_chart.png)
*This chart identifies a high-risk readmission spike in the [20-30) age demographic.*

### Statistical Validation: Stay Duration vs. Complexity
![Box Plot](https://github.com/jakut32/Hospital-Readmission-SQL-Audit/blob/main/R_Analysis/age_readmission_box_plot.png)
*The vertical **height** of these boxes proves our T-test result: complex patients (9+ diagnoses) stay 1.2 days longer than simple cases.*
