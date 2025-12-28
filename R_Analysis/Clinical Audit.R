getwd()
setwd("C:/Users/User/Desktop/r class/")
getwd()

# PROJECT: Hospital Readmission Statistical Audit
# PURPOSE: Connect to SQL, analyze clinical trends, and validate with Statistics.
# AUTHOR: [Your Name]

# TOOLBOX SET
# Purpose: Load the libraries needed for database and data science tasks.
library(DBI)      # Standardizes the interface between R and database management systems.
library(RMySQL)   # The specific driver that allows R to speak to a MySQL server.
library(tidyverse) # A collection of tools (ggplot2, dplyr) for data cleaning and visualization.
library(ggthemes)  # Adds professional formatting to charts.

# --- 2. THE DATABASE HANDSHAKE ---
# Purpose: Establish a secure, live connection to your local SQL server.
con <- dbConnect(MySQL(), 
                 user = 'root',             # MySQL username.
                 password = 'password', # Replace with your actual password.
                 dbname = 'hospital_audit', # The specific database I created earlier ON MY SQL.
                 host = '127.0.0.1')        # Telling R the database is on this local computer.

# --- 3. DATA ACQUISITION ---
# Purpose: Import your "Single Source of Truth" View into R for advanced analysis.
# We use dbGetQuery because it sends a command and waits for the data to return.
df <- dbGetQuery(con, "SELECT * FROM cleaned_diabetic_data")

# --- 4. DATA CLEANING & TRANSFORMATION ---
# Purpose: This is the most important step! i removed the hidden '\r' 
# characters so R can actually see the "<30" readmission status.
age_summary <- df %>%   # stringr::str_trim removes invisible spaces and 'carriage returns' (\r)
  mutate(readmitted_clean = stringr::str_trim(readmitted)) %>%
  group_by(age) %>%
  summarize(# We turn the text into a 1 (Yes) or 0 (No) so we can calculate a percentage
    readmit_rate = mean(readmitted_clean == "<30", na.rm = TRUE) * 100)

#"<30" does not equal "<30\r". 
# By trimming the data, we ensure our "Yes/No" logic actually works.

#5. PROFESSIONAL VISUALIZATION ---
# Purpose: Creating a bar chart that is easy for a manager to read.
ggplot(age_summary, aes(x = age, y = readmit_rate, fill = readmit_rate)) +
  geom_col() + 
  # Use a gradient to highlight 'Danger' (High Risk) in red
  scale_fill_gradient(low = "steelblue", high = "firebrick") +
  labs(title = "Clinical Audit: 30-Day Readmission Risk by Age",
       subtitle = "High-risk spike identified in the [20-30) demographic",
       x = "Age Bracket",
       y = "Readmission Rate (%)") +
  theme_minimal()

#6.(T-TEST) 
# Purpose: Proving that the results aren't just a lucky guess.
# I compared hospital stay duration against patient complexity (9+ diagnoses).
t_test_results <- t.test(stay_duration ~ (num_diagnoses >= 9), data = df)

print(t_test_results)
