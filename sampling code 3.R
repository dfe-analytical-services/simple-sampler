# Sampling 2.0 #
library(lubridate)
library(dplyr)
library(data.table)
library(ggplot2)
#library(plyr)
library(pwr)
library(dummies)
library(survey)

# ---- Get edubase data ----
date <- Sys.Date()
month <- ifelse(nchar(month(date)) == 1, paste0("0", month(date)), month(date))
day <- ifelse(nchar(day(date)) == 1, paste0("0", day(date)), day(date))

edubase <- fread(paste0('http://ea-edubase-api-prod.azurewebsites.net/edubase/edubasealldata',
              year(date),
              month,
              day,
              '.csv'))

edubase.2 <- edubase %>%
  filter(`EstablishmentStatus (name)` == "Open") %>%
  select(URN,
         EstablishmentName,
         TelephoneNum,
         HeadFirstName,
         HeadLastName,
         type = `TypeOfEstablishment (name)`,
         group = `EstablishmentTypeGroup (name)`,
         OpenDate,
         phase = `PhaseOfEducation (name)`,
         gender=`Gender (name)`,
         NumberOfPupils,
         PercentageFSM,
         trusts = `Trusts (name)`,
         Ofsted = `OfstedRating (name)`,
         Town,
         Postcode,
         region = `GOR (name)`) %>%
  mutate(region = as.factor(region),
         Ofsted = as.factor(Ofsted),
         phase2 = case_when(phase %in% c("Secondary", "Middle deemed secondary") ~ "Secondary",
                           phase %in% c("Primary", "Middle deemed primary") ~ "Primary"),
         region2 = case_when(region %in% c("London") ~ "London",
                             TRUE ~ "Non-London")) %>%
  group_by(phase2) %>%
  mutate(numpupils_quintile = ntile(NumberOfPupils, 5),
         fsm_quintile = ntile(PercentageFSM, 5)) %>%
  ungroup %>%
  filter(!region %in% c("Not Applicable", "Wales (pseudo)")) %>%
  mutate(All = "All")

summary(edubase.2)

# Get confidence intervals and sample sizes
c = 0.05
x = 350

if(!is.na(c)) {
  x = round((1.96 * 0.5 * 0.5)/c^2)
} else {
  x = x
}

# Get groups you want to analyse
groups <- c("phase2")

if(groups == "" | is.na(groups) | is.null(groups)) groups <- "All"
   
# ---- Sampling -----

# We want to randomly sample within our groups
# such that the samples are nationally representative by input factors

# Set variables you want to be representative by
repr <- c( "numpupils_quintile", "group",  "Ofsted", "region", "fsm_quintile")

# ---- Draw samples ----

# Secondary
sec.samp <- edubase.2 %>%
  filter(phase2 == "Secondary") %>%
  group_by_(repr) %>%
  sample_frac(x/nrow(.)) %>%
  ungroup %>%
  mutate_at(vars(repr), as.factor)

# Primary
pri.samp <- edubase.2 %>%
  filter(phase2 == "Primary") %>%
  group_by_(repr) %>%
  sample_frac(x/nrow(.)) %>%
  ungroup %>%
  mutate_at(vars(repr), as.factor)

# View descriptions
summary(sec.samp)
summary(pri.samp)

# ---- Save samples and descriptions ----

fwrite(pri.samp, './Outputs/Primary sample.csv')
fwrite(sec.samp, './Outputs/Secondary sample.csv')


# ---- Set up for shiny app ----

# Get list of possible representation variables
vars <- names(edubase.2)[c(6,7,10,14,17, 19:21)]

# Save
saveRDS(vars, './Utils/representatin varaibles.rds')
