/*
Credit Card Customer Churn Analysis
SQL dialect: MySQL 8+

Table expected: bank_churners
Load data/processed/BankChurners_Cleaned.csv into this table before running.
Churn_Flag: 1 = Attrited Customer, 0 = Existing Customer
*/

-- Q1. How many unique customers are in the dataset?
SELECT COUNT(DISTINCT CLIENTNUM) AS total_customers
FROM bank_churners;

-- Q2. How many customers are existing and how many have churned?
SELECT
    Attrition_Flag,
    COUNT(DISTINCT CLIENTNUM) AS total_customers
FROM bank_churners
GROUP BY Attrition_Flag
ORDER BY total_customers DESC;

-- Q3. What is the overall churn rate?
SELECT
    COUNT(DISTINCT CLIENTNUM) AS total_customers,
    SUM(Churn_Flag) AS churned_customers,
    COUNT(DISTINCT CLIENTNUM) - SUM(Churn_Flag) AS existing_customers,
    ROUND(100.0 * SUM(Churn_Flag) / COUNT(DISTINCT CLIENTNUM), 2) AS churn_rate_pct
FROM bank_churners;

-- Q4. Which card category has the highest churn rate?
SELECT
    Card_Category,
    COUNT(DISTINCT CLIENTNUM) AS total_customers,
    SUM(Churn_Flag) AS churned_customers,
    ROUND(100.0 * SUM(Churn_Flag) / COUNT(DISTINCT CLIENTNUM), 2) AS churn_rate_pct
FROM bank_churners
GROUP BY Card_Category
ORDER BY churn_rate_pct DESC;

-- Q5. How does churn vary by income category?
SELECT
    Income_Category,
    COUNT(DISTINCT CLIENTNUM) AS total_customers,
    SUM(Churn_Flag) AS churned_customers,
    ROUND(100.0 * SUM(Churn_Flag) / COUNT(DISTINCT CLIENTNUM), 2) AS churn_rate_pct
FROM bank_churners
GROUP BY Income_Category
ORDER BY churn_rate_pct DESC;

-- Q6. How does churn vary by age group?
SELECT
    Age_Group,
    COUNT(DISTINCT CLIENTNUM) AS total_customers,
    SUM(Churn_Flag) AS churned_customers,
    ROUND(100.0 * SUM(Churn_Flag) / COUNT(DISTINCT CLIENTNUM), 2) AS churn_rate_pct
FROM bank_churners
GROUP BY Age_Group
ORDER BY churn_rate_pct DESC;

-- Q7. Does churn differ by gender?
SELECT
    Gender,
    COUNT(DISTINCT CLIENTNUM) AS total_customers,
    SUM(Churn_Flag) AS churned_customers,
    ROUND(100.0 * SUM(Churn_Flag) / COUNT(DISTINCT CLIENTNUM), 2) AS churn_rate_pct
FROM bank_churners
GROUP BY Gender
ORDER BY churn_rate_pct DESC;

-- Q8. What is the churn rate by months inactive?
SELECT
    Months_Inactive_12_mon AS inactive_months,
    COUNT(DISTINCT CLIENTNUM) AS total_customers,
    SUM(Churn_Flag) AS churned_customers,
    ROUND(100.0 * SUM(Churn_Flag) / COUNT(DISTINCT CLIENTNUM), 2) AS churn_rate_pct
FROM bank_churners
GROUP BY Months_Inactive_12_mon
ORDER BY inactive_months;

-- Q9. What is the churn rate by number of customer contacts?
SELECT
    Contacts_Count_12_mon AS contact_count,
    COUNT(DISTINCT CLIENTNUM) AS total_customers,
    SUM(Churn_Flag) AS churned_customers,
    ROUND(100.0 * SUM(Churn_Flag) / COUNT(DISTINCT CLIENTNUM), 2) AS churn_rate_pct
FROM bank_churners
GROUP BY Contacts_Count_12_mon
ORDER BY contact_count;

-- Q10. How does the number of bank products relate to churn?
SELECT
    Total_Relationship_Count AS number_of_bank_products,
    COUNT(DISTINCT CLIENTNUM) AS total_customers,
    SUM(Churn_Flag) AS churned_customers,
    ROUND(100.0 * SUM(Churn_Flag) / COUNT(DISTINCT CLIENTNUM), 2) AS churn_rate_pct
FROM bank_churners
GROUP BY Total_Relationship_Count
ORDER BY number_of_bank_products;

-- Q11. How does utilization band relate to churn?
SELECT
    Utilization_Band,
    COUNT(DISTINCT CLIENTNUM) AS total_customers,
    SUM(Churn_Flag) AS churned_customers,
    ROUND(100.0 * SUM(Churn_Flag) / COUNT(DISTINCT CLIENTNUM), 2) AS churn_rate_pct
FROM bank_churners
GROUP BY Utilization_Band
ORDER BY churn_rate_pct DESC;

-- Q12. Compare the transaction activity of existing and churned customers.
SELECT
    Attrition_Flag,
    COUNT(DISTINCT CLIENTNUM) AS total_customers,
    ROUND(AVG(Total_Trans_Ct), 2) AS avg_transaction_count,
    ROUND(AVG(Total_Trans_Amt), 2) AS avg_transaction_amount,
    ROUND(AVG(Avg_Utilization_Ratio), 3) AS avg_utilization_ratio
FROM bank_churners
GROUP BY Attrition_Flag;

-- Q13. Which segments have meaningful churn risk?
-- HAVING removes very small groups that can produce unstable percentages.
SELECT
    Card_Category,
    Income_Category,
    COUNT(DISTINCT CLIENTNUM) AS total_customers,
    SUM(Churn_Flag) AS churned_customers,
    ROUND(100.0 * SUM(Churn_Flag) / COUNT(DISTINCT CLIENTNUM), 2) AS churn_rate_pct
FROM bank_churners
GROUP BY Card_Category, Income_Category
HAVING COUNT(DISTINCT CLIENTNUM) >= 30
ORDER BY churn_rate_pct DESC, total_customers DESC;

-- Q14. Which existing customers match the rule-based warning criteria?
-- This is a prioritization rule, not an ML prediction.
WITH customer_ranking AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY Total_Trans_Ct) AS transaction_quartile,
        NTILE(4) OVER (ORDER BY Total_Ct_Chng_Q4_Q1) AS transaction_change_quartile
    FROM bank_churners
    WHERE Attrition_Flag = 'Existing Customer'
)
SELECT
    CLIENTNUM,
    Customer_Age,
    Card_Category,
    Months_Inactive_12_mon,
    Contacts_Count_12_mon,
    Total_Trans_Ct,
    Total_Ct_Chng_Q4_Q1
FROM customer_ranking
WHERE transaction_quartile = 1
  AND transaction_change_quartile = 1
  AND Months_Inactive_12_mon >= 3
  AND Contacts_Count_12_mon >= 3
ORDER BY Months_Inactive_12_mon DESC, Contacts_Count_12_mon DESC;

-- Q15. Rank customer groups by churn rate within each card category.
WITH segment_churn AS (
    SELECT
        Card_Category,
        Income_Category,
        COUNT(DISTINCT CLIENTNUM) AS total_customers,
        SUM(Churn_Flag) AS churned_customers,
        100.0 * SUM(Churn_Flag) / COUNT(DISTINCT CLIENTNUM) AS churn_rate_pct
    FROM bank_churners
    GROUP BY Card_Category, Income_Category
)
SELECT
    Card_Category,
    Income_Category,
    total_customers,
    churned_customers,
    ROUND(churn_rate_pct, 2) AS churn_rate_pct,
    DENSE_RANK() OVER (
        PARTITION BY Card_Category ORDER BY churn_rate_pct DESC
    ) AS risk_rank
FROM segment_churn
ORDER BY Card_Category, risk_rank;
