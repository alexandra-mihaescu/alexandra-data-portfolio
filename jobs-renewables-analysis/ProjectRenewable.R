rm(list=ls())

#PACKAGES----

install.packages("corrplot")
install.packages("psych")
install.packages("gridExtra")
install.packages("egg")

library(tidyverse)
library(readxl)
library(ggplot2)
library(dplyr)
library(modelsummary)
library(fixest)
library(sandwich)
library(corrplot)
library(lmtest)
library(gridExtra)
library(psych)
library(tidyr)
library(egg)

#### IMPORT DATA----

getwd()
data_EMP = read_excel("AMECO1.XLSX")
data_REN = read_excel("epcrw.xlsx")
data_EC = read_excel("EC.xlsx")
data_ED = read_excel("ED.xlsx")

str(data_EC)
str(data_ED)
str(data_EMP)
str(data_REN)

#### DATA CLEANING ----

data_EMP = data_EMP %>% 
  filter(TITLE == "Employment, persons: total economy (National accounts)")%>%
  select(8, "2005", "2006", "2007", "2008", "2009",
                               "2010", "2011", "2012", "2013", "2014", "2015", 
                               "2016", "2017", "2018", "2019", "2020", "2021", 
                               "2022", "2023")
data_EMP = data_EMP[6:49, ]

data_REN = data_REN  %>%  group_by(`GEO (Labels)`) %>% 
  filter(`SIEC (Labels)`%in% c("Hydro", "Wind", "Solar", "Solid biofuels"))%>%
  summarise(across(`2005`:`2023`, ~sum(as.numeric(.), na.rm=TRUE)))

data_REN = data_REN %>% rename(COUNTRY = `GEO (Labels)`)
data_EC = data_EC %>% rename(COUNTRY = `GEO (Labels)`)
data_ED = data_ED %>% rename(COUNTRY = `GEO (Labels)`)

data_EMP = data_EMP %>% filter(COUNTRY %in% data_EC$COUNTRY)
data_EC = data_EC %>% filter(COUNTRY %in% data_EMP$COUNTRY)
data_ED = data_ED %>% filter(COUNTRY %in% data_EMP$COUNTRY)
data_REN = data_REN %>% filter(COUNTRY %in% data_EMP$COUNTRY)



#We change the structure of the datasets, in order to be able to merge them

data_EC <- data_EC %>%
  pivot_longer(cols = 2:20,
               names_to = "Year",
               values_to = "EC") %>%
  mutate(Year = as.integer(Year))

data_ED <- data_ED %>%
  pivot_longer(cols = 2:20,
               names_to = "Year",
               values_to = "ED") %>%
  mutate(Year = as.integer(Year))

data_EMP <- data_EMP %>%
  pivot_longer(cols = 2:20,
               names_to = "Year",
               values_to = "EMP") %>%
  mutate(Year = as.integer(Year))

data_REN <- data_REN %>%
  pivot_longer(cols = 2:20,
               names_to = "Year",
               values_to = "REN") %>%
  mutate(Year = as.integer(Year))

merged_dataset = data_REN %>%
  left_join(data_EMP, by = c("COUNTRY", "Year")) %>%
  left_join(data_EC, by = c("COUNTRY", "Year")) %>%
  left_join(data_ED, by = c("COUNTRY", "Year"))

#Our variables:

# REN - Elecricity production capacities for reneawables and wastes (Megawatt)
# EMP - 
# EC -
# ED -


#Lastly, we need to balance the dataset rìby removing missing observations

merged_dataset <- merged_dataset %>%
  mutate(across(where(is.character), ~na_if(.x, "NO"))) %>%
  mutate(across(where(is.character), ~na_if(.x, ":"))) %>%
  mutate(across(where(is.character), ~na_if(.x,"NA")))

summary_COUNTRY = merged_dataset %>% group_by(COUNTRY) %>%
  summarise(tot_yaers = n_distinct(Year),
            complete_years = sum(complete.cases(REN, EMP, EC, ED))) #COUNTRYies with missing values


summary_year = merged_dataset %>% group_by(Year) %>%
  summarise(tot_COUNTRY = n_distinct(COUNTRY),
            complete_COUNTRY = sum(complete.cases(REN, EMP, EC, ED))) #Years with missing values


colSums(is.na(merged_dataset)) #Complete observations

range((merged_dataset$Year)) #From year 2005 to 2023

unique(merged_dataset$COUNTRY) #Names of selected COUNTRYies
n_distinct(merged_dataset$COUNTRY) #Selected COUNTRYies: 27

str(merged_dataset)

merged_dataset <- merged_dataset %>%
  mutate(across(c(EMP, EC, ED), ~as.numeric(.x)))

merged_dataset = merged_dataset %>%
  mutate(EMPth = EMP/1000)

# STATISTICAL ANALYSIS ----

### Descriptive Statistics Table (Mean, SD, Min, Max)
#By country, even if it not seems to be convenient, better in an aggregate way


# Descriptive statistics (overall, not by country)
desc_table <- merged_dataset %>%
  select(REN, EMPth, EC, ED) %>%
  summarise(across(everything(),
                   list(mean = mean,
                        sd = sd,
                        min = min,
                        max = max),
                   .names = "{.col}_{.fn}"))

# Put it in columns in order to compact everything 
desc_table_long <- desc_table %>%
  pivot_longer(cols = everything(),
               names_to = c("Variable", "Statistic"),
               names_sep = "_",
               values_to = "Value") %>%
  pivot_wider(names_from = Statistic, values_from = Value)

print(desc_table_long)

###Plot aggregated means over time instead of single country

# Aggregated means over time

means_trend <- merged_dataset %>%
  group_by(Year) %>%
  summarise(
    EMP = mean(EMPth),
    REN = mean(REN),
    EC  = mean(EC),
    ED  = mean(ED),
    .groups = "drop") %>%
  pivot_longer(
    cols = c(EMP, REN, EC, ED),
    names_to = "Variable",
    values_to = "Value")

# Plot aggregated trends


ggplot(means_trend, aes(x = Year, y = Value)) +
  geom_line(size = 1.2, color = "#191970", alpha = 0.85) +
  facet_wrap( ~ Variable, scales = "free_y",
              labeller = as_labeller(c( EMP = "Employment (Thousand)",
                                        REN = "Renewable Capacity (Mw)",
                                        EC = "Energy Consumption Pro Capita (toe)",
                                        ED = "Energy Dependency (%)"))) +
  theme_minimal() +
  labs(y = "Average Value",
       x = "Year") #REMEMBER: title "Average Trends Over Time (2005 - 2023)" in the ppt


# 
data_barplot = merged_dataset %>% filter (Year %in% c(2005, 2023))

REN_bar = data_barplot %>%
  ggplot(aes(x = COUNTRY, y = REN/10000,
                            fill = factor (Year))) +
  geom_col(position = "dodge") +
  scale_fill_manual(values = c("2005" = "#96CDCD", "2023" = "#191970" )) +
  labs( y = "RenewableS (Gw)",
        x = "",
        fill = "Year") +
  theme_minimal(base_size = 14) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) 

EMPth_bar = data_barplot %>%
  ggplot(aes(x = COUNTRY, y = EMPth,
             fill = factor (Year))) +
  geom_col(position = "dodge") +
  scale_fill_manual(values = c("2005" = "#96CDCD", "2023" = "#191970" )) +
  labs( y = "Employment (Thousands)",
        x = "",
        fill = "Year") +
  theme_minimal(base_size = 14) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggarrange(REN_bar, EMPth_bar,
          ncol = 1, nrow = 2)

### Density plots 

vars_to_check <- merged_dataset %>% select(REN, EMPth, ED, EC)

# Density plots with normal curve overlay
density_plots <- lapply(names(vars_to_check), function(var) {
  ggplot(merged_dataset, aes(x = .data[[var]])) +
    geom_density(fill = "blue", alpha = 0.6) +
    geom_rug(alpha = 0.3) +
    stat_function(
      fun = dnorm,
      args = list(mean = mean(merged_dataset[[var]], na.rm = TRUE),
                  sd = sd(merged_dataset[[var]], na.rm = TRUE)),
      color = "red", size = 1, linetype = "dashed" 
    ) +
    labs(title = paste("Density of", var), x = var, y = "Density") +
    theme_minimal()
})

do.call(grid.arrange, c(density_plots, ncol = 2)) #The dashed red line represents the theoretical normal distribution


#Distributions before and after log transformation


density_lnREN = 
  merged_dataset %>% ggplot(aes(x  = log(REN+1))) +
  geom_density(fill = "#96CDCD", color = "#96CDCD", alpha = 0.4) + 
  labs( x = "Renewable Capacity (Mw)", y = " ")+
  theme_minimal() +
  theme( axis.title = element_text( hjust = 1,
                                    vjust = 0))


density_REN = 
  merged_dataset %>% ggplot(aes(x = REN)) +
  geom_density(fill = "#1b1f34", color = "#1b1f34" , alpha = 0.4) + 
  labs(y = "Density", x = " ") +
  theme_minimal()

ggarrange(density_REN, density_lnREN,
          ncol=2, nrow=1)

density_lnEMPth = 
  merged_dataset %>% ggplot(aes(x = log(EMPth+0.01))) +
  geom_density(fill = "#96CDCD", color = "#96CDCD", alpha = 0.4) + 
  labs( x = "Employment (Thousands))", y = " ")+
  theme_minimal() +
  theme( axis.title = element_text( hjust = 1,
                                    vjust = 0))

density_EMPth = 
  merged_dataset %>% ggplot(aes(x = EMPth)) +
  geom_density(fill = "#1b1f34", color = "#1b1f34" , alpha = 0.4) +
  labs(y = "Density", x = " ") + theme_minimal()

ggarrange(density_EMPth, density_lnEMPth,
          ncol=2, nrow=1)

density_lnEC = 
  merged_dataset %>% ggplot(aes(x  = log(EC+0.01))) +
  geom_density(fill = "#96CDCD", color = "#96CDCD", alpha = 0.4) +
  labs( x = "Energy Consumption (TOE)", y = " ")+
  theme_minimal() +
  theme( axis.title = element_text( hjust = 1,
                                    vjust = 0))

density_EC = 
  merged_dataset %>% ggplot(aes(x = EC)) +
  geom_density(fill = "#1b1f34", color = "#1b1f34" , alpha = 0.4) + 
  labs(y = "Density", x = " ") + theme_minimal()

ggarrange(density_EC, density_lnEC,
          ncol=2, nrow=1)

density_ED = merged_dataset %>% ggplot(aes(x = ED)) +
  geom_density(fill = "#1b1f34", color = "#1b1f34" , alpha = 0.4) + 
  labs(y = "Density", x = "Energy Dependency (%)")+
  theme_minimal()+
  theme( axis.title = element_text( hjust = 1,
                                    vjust = 0))

density_ED



# Scatterplots: EMP vs main regressor and controls
scatter_vars <- c("REN", "EC", "ED")

scatter_plots <- lapply(scatter_vars, function(var) {
  ggplot(merged_dataset, aes(x = .data[[var]], y = EMPth)) +
    geom_point(alpha = 0.5, color = "darkblue") +
    geom_smooth(method = "lm", se = FALSE, color = "red") +
    labs(title = paste("EMP vs", var),
         x = var, y = "Employment (thousands)") +
    theme_minimal()
})

do.call(grid.arrange, c(scatter_plots, ncol = 2))

#Scatterplot EMP ~ REN

merged_dataset %>%
  ggplot(aes(x = log(REN+1), y = log(EMPth))) +
  geom_point(alpha = 0.5, color = "darkblue") +
  geom_smooth( method = "lm", color = "red3") +
  labs( x = "Log of Renewable Capacity (Mw)",
        y = "Log of Employment (Thousand)") +
  theme_minimal() +
  theme( axis.title = element_text( hjust = 1,
                                    vjust = 0))

#Comparison between the first and the last year of panel 

plot_data <- merged_dataset %>%
  filter(Year %in% c(2005, 2023)) %>%
  select(COUNTRY, Year, EMPth, REN) %>%
  drop_na()

ggplot(plot_data, aes(x = log(REN), y = log(EMPth))) +
  geom_point(color = "blue", size = 2, alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, color = "red") +
  facet_wrap(~ Year, ncol = 2) +
  labs(
    title = "Relationship between Employment and Access to Renewable Energy",
    x = "Renewable energy consumption (% of total final energy use)",
    y = "Employment (thousands)",
    caption = "Cross-country comparison for 2015 and 2022"
  ) +
  theme_minimal(base_size = 14)


### Correlation matrix

# Visualizing relationships between variables through a correlation plot can be useful
# to understand the strenght of our hypotesis, and the role of the possible controls

merged_dataset = merged_dataset %>%
  mutate(lnEMPth = log(EMPth+0.001),
         lnREN = log(REN+0.001),
         lnEC = log(EC+0.001))
  
correlation_matrix = 
  merged_dataset %>%
  select(lnEMPth, lnREN, lnEC, ED) %>% 
  cor(use = "complete.obs")

corrplot(correlation_matrix, method="color", type = 'full', diag=FALSE, col=c("#1b1f34", "#96CDCD"),  
         addgrid.col = 'white', addCoef.col = 'white',tl.col = "black",tl.srt = 45, tl.pos = "d")


# ECONOMETRIC ANALYSIS: FIRST RESEARCH QUESTION ----

# The effect of access to safely managed drinking water services on the primary completion rate 
#of children 

# Plot the relationship between primary completion rate of children and safely 
# managed drinking water services at the beginning and at the end of the study period in two separate graphs 
# (i.e., two distinct scatter plots representing all COUNTRYies primary completion rate in 2022 and all COUNTRYies survival rates in 2015, add the regression line too).

### REGRESSION ANALYSIS

# Run the OLS model: primary completion rate explained by access to safely managed drinking water
#with and withoust robust SE

mod_REN = feols(lnEMPth ~ lnREN, data = merged_dataset )
mod_REN_hc1 <- feols(lnEMPth ~ lnREN, data = merged_dataset, vcov = "HC1" )

modelsummary(list("OLS simple" = mod_REN,
                  "Robust SE" = mod_REN_hc1),
             stars = c("*" = .1, "**" = .05, "***" = .01), fmt = 3)


# We add controles once at time

mod_ED = feols(lnEMPth ~ lnREN + ED , data = merged_dataset, vcov = "HC1" )
mod_EC = feols(lnEMPth ~ lnREN + lnEC, data = merged_dataset, vcov = "HC1" )
mod_complete = feols(lnEMPth ~ lnREN + ED + lnEC, data = merged_dataset, vcov = "HC1" )

modelsummary(list("OLS simple" = mod_REN_hc1,
                  "With GDP" = mod_ED,
                  "With pop" = mod_EC,
                  "With both" = mod_complete),
             stars = c("*" = .1, "**" = .05, "***" = .01), fmt = 3)



# In the previous models we have not controlled for structural changes across COUNTRYies
# and over time.
# To do so we introduce fix effects




mod_c_fe = feols(lnEMPth ~ lnREN + ED + lnEC | COUNTRY,
                 data = merged_dataset,
                 vcov = "HC1")
mod_y_fe = feols(lnEMPth ~ lnREN + ED + lnEC| Year,
                 data = merged_dataset,
                 vcov = "HC1")
mod_fe = feols(lnEMPth ~ lnREN + ED + lnEC| COUNTRY + Year,
               data = merged_dataset,
               vcov = "HC1")

modelsummary(list("Previous model" = mod_ED,
                  "COUNTRY FE" = mod_c_fe,
                  "Year FE" = mod_y_fe,
                  "Both FE" = mod_fe),
             stars = c("*" = .1, "**" = .05, "***" = .01), fmt = 3)

# Adding FE the model looses significance: it might be because of too little
# variation in the data across COUNTRYies and years

# Lastly, we use clustered standard errors

mod_cluster_se = feols(lnEMPth ~ lnREN + ED + lnEC | COUNTRY + Year,
                       data = merged_dataset,
                       cluster = ~COUNTRY)

modelsummary(list("Rough model" = mod_complete,
                  "FE model" = mod_fe,
                  "Clusterized model" = mod_cluster_se),
             stars = c("*" = .1, "**" = .05, "***" = .01), fmt = 3)

