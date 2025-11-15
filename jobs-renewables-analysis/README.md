# Jobs and Renewables Analysis
**An emprical study on the effect of renewable energy deployment on employment in the EU27 (2005-2023)**

*Project developed during my Bachelor AY 2024-2025*

## Table of Contents

- [Project Overview](#project-overview)
- [Data](#data)
- [Methodology](#methodology)
- [Descriptive statistics](#descriptive-statistics)
- [Results and Interpretation](#results-and-interpretation)
- [Limitations](#limitations)
- [References](#references)

---

## Project Overview 

This project work investigates whether the expansion of **renewable energy production** contributes to **employment growth** in the European Union.
Using panel data for **27 EU countries from 2005 to 2023**, the study replicates and updates previous research, incorporating recent dynamics such as:
- The European Green Deal;
- Post-Covid labour market adjustments;
- The 2021-2022 energy crisis;
- Technological progress in wind, solar and other renewables.

The goal is to provide updated and policy relevant evidence on the job effects of the green transition.

🎯 Research question: **What is the effect of renewables on employment in the EU?**
*We test whether increases in renewable energy capacity are associated with higher employment levels, controlling for structural differences across countries and time*

The debate about this topic is still opened. Existing literature findings:
- Positive effects (elasticity around 0.48% → 1% increase in renewables raises employment by 0.48%)
- Smaller effects (around 0.08%) depending on the method, period or region
- Large heterogeneity between countries
- Need to distinguish between gross and net job creation

---

## Data 

**Sources**
- **Eurostat** (Renewable energy capacity,Energy dependency, Energy consumption)
- **AMECO** (Employment)

Unit: country-year <br>
Sample: 27 countries * 19 years = 513 observations<br>
Format: panel data

**Data cleaning process**
1. Standardised and renamed variables
2. Reshaped datasets from wide to long
3. Merged using country-year keys
4. removed missing values or inconsistent observations
5. Applied log-transformations to skewed variables

---

## Methodology

1️⃣ **Baseline Model** <br>
$\log(EMP_it) = \alpha + \beta \log(REN_it) + u_it$

2️⃣ **Multiple Regression Model** <br>
*To reduce omitted variable bias*

$\log(EMP_it) = \alpha + \beta_1 \log(REN_it) +\beta_2 \log(EC_it) + \beta_3 ED_it + u_it$

Where:
- **EMP** = employment (thousands of people)
- **REN** = renewable energy capacity
- **EC** = energy consumption per capita
- **ED** = energy dependency (%)

We also estimate fixed-effects model and cluster standard errors by country.

---

## Descriptive statistics

The analyses included: <br>
- **Summary Statistic Table** (mean, standard deviation, minimum, maximum)
- Average trends over time
- Skewness and distribution
- **Correlation matrix**
- Scatterplot of Employment vs Renewables

This and others tables and plots can be found in the accompanying [PowerPoint presentation] or in the [R script]


---

## Results and Interpretation

1️⃣ **Renewables**  have a positivve and statistically significant effect <br>
Across all models (simple OLS,, multiple regression, FE, cluster SE) renewables remain significant.

- Elasticity = **0.59-0.62**
- A 1% increase in renewables is associated with a 0.6% higher employment

2️⃣ **Energy dependency** <br>
Negative effect (small but significant in some models)

3️⃣ **Energy Consumption per capita** <br>
Strong negative effect, possibly due to automation, energy efficiency, industrial mix

4️⃣ **Fixed Effects** <br>
The effect of renewables persists but becomes smaller once controlling for country structure.

**Interpretation**  <br>

We can say that results align with literature: renewables tend to create jobs.
However, the magnitude is lower when controlling for country differences and employment benefits may depend on policiy support, technology and insutrial structure.

---

## Limitations

### Internal validity
1. Possible omitted variables (GDP, investment policies, labour force structure)
2. Reverse causality (employment → renewables)
3. Potential model misspesification

### External validity 
1. Results apply to EU high-income countries
2. Not generalisable to developing countries or fossil-dependent countries

---

## References

- Proença, S., & Fortes, P. (2020). The social face of renewables: Econometric analysis of the relationship between renewables and employment. Energy Reports, 6, 581-586.
- Lambert, R. J., & Silva, P. P. (2012). The challenges of determining the employment effects of renewable energy. Renewable and Sustainable Energy Reviews, 16(7), 4667-4674.
- Azretbergenova, G. Ž., Syzdykov, B., Niyazov, T., Gulzhan, T., & Yskak, N. (2021). The relationship between renewable energy production and employment in European union countries: Panel data analysis. International Journal of Energy Economics and Policy, 11(3), 20-26.

---

## Repository Structure

