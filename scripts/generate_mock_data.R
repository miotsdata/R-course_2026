set.seed(42)
n <- 240

# Patient IDs
patient_ids <- paste0("PT-", sprintf("%03d", 1:n))

# Sex
sex <- sample(c("Male", "Female"), n, replace = TRUE, prob = c(0.48, 0.52))

# Treatment group
treatment <- sample(c("Control", "Drug_A", "Drug_B"), n, replace = TRUE)

# Disease stage
stage <- sample(c("I", "II", "III", "IV"), n, replace = TRUE, prob = c(0.3, 0.35, 0.25, 0.1))

# Age
age <- round(rnorm(n, mean = 58, sd = 12))

# Weight (kg) - slightly different by sex
weight <- ifelse(sex == "Male",
                 round(rnorm(n, mean = 82, sd = 12), 1),
                 round(rnorm(n, mean = 68, sd = 10), 1))

# Height (cm)
height <- ifelse(sex == "Male",
                 round(rnorm(n, mean = 175, sd = 7), 1),
                 round(rnorm(n, mean = 163, sd = 6), 1))

# Systolic blood pressure
sbp <- round(rnorm(n, mean = 130, sd = 18))

# Diastolic blood pressure
dbp <- round(rnorm(n, mean = 82, sd = 11))

# Glucose (mg/dL) - slightly elevated for some
glucose <- round(rnorm(n, mean = 105, sd = 22))

# Cholesterol (mg/dL)
cholesterol <- round(rnorm(n, mean = 195, sd = 38))

# Biomarker (e.g. CRP, ng/mL) - log-normal
crp <- round(exp(rnorm(n, mean = 1.2, sd = 0.8)), 2)

# Visit date (within 2023)
start_date2023 <- as.Date("2023-01-10")
start_date2020 <- as.Date("2020-01-10")
start_date2018 <- as.Date("2018-01-10")
start_date2025 <- as.Date("2025-01-10")
visit_date <- sample(c(start_date2023, start_date2020, start_date2018, start_date2025), n, replace = TRUE) + sample(0:300, n, replace = FALSE)

# Hospital site
site <- sample(c("Milan", "Rome", "Turin", "Turin "), n, replace = TRUE, prob = c(0.4, 0.3, 0.15, 0.15))

# Smoking status (some messy on purpose for string exercises)
smoking_raw <- sample(c("never", "Never", "former", "FORMER", "current", "Curent", "never smoker"),
                      n, replace = TRUE, prob = c(0.15, 0.15, 0.15, 0.1, 0.12, 0.13, 0.2))

# Build dataframe
clinical_df <- data.frame(
  patient_id   = patient_ids,
  site         = site,
  visit_date   = as.character(visit_date),
  age          = age,
  sex          = sex,
  smoking      = smoking_raw,
  treatment    = treatment,
  stage        = stage,
  weight_kg    = weight,
  height_cm    = height,
  sbp_mmhg     = sbp,
  dbp_mmhg     = dbp,
  glucose_mgdl = glucose,
  cholesterol_mgdl = cholesterol,
  crp_ngml     = crp,
  stringsAsFactors = FALSE
)

write.csv(clinical_df, file = "data/clinical_data.csv", row.names = FALSE)
cat("clinical_data.csv created with", nrow(clinical_df), "rows and", ncol(clinical_df), "columns\n")

# ------ Second dataset: lab results (for join exercise) ------
# Subset of patients got lab follow-up
n_lab <- round(n * 2 / 3)
lab_ids <- sort(sample(patient_ids, n_lab))

# Lab values
lab_df <- data.frame(
  patient_id    = lab_ids,
  hemoglobin_gdl = round(rnorm(n_lab, mean = 13.5, sd = 1.8), 1),
  wbc_10e9l     = round(rnorm(n_lab, mean = 7.2, sd = 2.1), 2),
  platelets_10e9l = round(rnorm(n_lab, mean = 230, sd = 60)),
  alt_ul        = round(exp(rnorm(n_lab, mean = 3.4, sd = 0.5))),
  creatinine_mgdl = round(rnorm(n_lab, mean = 0.95, sd = 0.22), 2),
  stringsAsFactors = FALSE
)

write.csv(lab_df, file = "data/lab_results.csv", row.names = FALSE)
cat("lab_results.csv created with", nrow(lab_df), "rows and", ncol(lab_df), "columns\n")
