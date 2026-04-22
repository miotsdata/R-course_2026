set.seed(42)
n <- 240

# ── Patient IDs ───────────────────────────────────────────────────────────────
patient_ids <- paste0("PT-", sprintf("%03d", 1:n))

# ── Sex ───────────────────────────────────────────────────────────────────────
sex <- sample(c("Male", "Female"), n, replace = TRUE, prob = c(0.48, 0.52))

# ── Age ───────────────────────────────────────────────────────────────────────
# Generated first because it drives stage, smoking history, and BP
age <- round(rnorm(n, mean = 58, sd = 12))
age <- pmax(pmin(age, 85), 25)

# ── Smoking ───────────────────────────────────────────────────────────────────
# Real distribution: older patients have more "former" smokers
# Intentional mess for string-cleaning exercise
smoking_clean <- ifelse(
    age < 45,
    sample(c("never", "former", "current"), n, replace = TRUE, prob = c(0.55, 0.20, 0.25)),
    ifelse(
        age < 65,
        sample(c("never", "former", "current"), n, replace = TRUE, prob = c(0.35, 0.35, 0.30)),
        sample(c("never", "former", "current"), n, replace = TRUE, prob = c(0.30, 0.50, 0.20))
    )
)

messy_map <- list(
    never   = c("never", "Never", "never smoker"),
    former  = c("former", "FORMER"),
    current = c("current", "Curent")
)
smoking_raw <- sapply(smoking_clean, function(s) sample(messy_map[[s]], 1))

# ── Disease stage ─────────────────────────────────────────────────────────────
# Smokers and older patients more likely to present at advanced stage
stage_prob <- function(smk, ag) {
    base <- c(I = 0.35, II = 0.35, III = 0.20, IV = 0.10)
    if (smk == "current") base <- base + c(-0.10, -0.05,  0.10,  0.05)
    if (smk == "former")  base <- base + c(-0.05,  0.00,  0.03,  0.02)
    if (ag  > 65)         base <- base + c(-0.05,  0.00,  0.03,  0.02)
    base / sum(base)
}
stage <- mapply(function(smk, ag) {
    sample(c("I", "II", "III", "IV"), 1, prob = stage_prob(smk, ag))
}, smoking_clean, age)

# ── Treatment group ───────────────────────────────────────────────────────────
# Advanced stages less often in control arm
treatment_prob <- function(stg) {
    if (stg %in% c("III", "IV")) c(Control = 0.20, Drug_A = 0.40, Drug_B = 0.40)
    else                          c(Control = 0.35, Drug_A = 0.32, Drug_B = 0.33)
}
treatment <- mapply(function(stg) {
    sample(c("Control", "Drug_A", "Drug_B"), 1, prob = treatment_prob(stg))
}, stage)

# ── Anthropometrics ───────────────────────────────────────────────────────────
# BMI is the root variable; weight is derived so BMI is exactly consistent
BMI_true <- ifelse(sex == "Male",
                   pmax(round(rnorm(n, mean = 27.5, sd = 5.0), 1), 16),
                   pmax(round(rnorm(n, mean = 26.0, sd = 5.2), 1), 16))

height <- ifelse(sex == "Male",
                 round(rnorm(n, mean = 175, sd = 7), 1),
                 round(rnorm(n, mean = 163, sd = 6), 1))
height <- pmax(height, 145)

weight <- round(BMI_true * (height / 100)^2, 1)

# ── Blood pressure ────────────────────────────────────────────────────────────
# SBP driven by age, BMI, smoking, sex
sbp_base <- 110 +
    0.35 * age +
    0.45 * BMI_true +
    ifelse(smoking_clean == "current", 6, ifelse(smoking_clean == "former", 3, 0)) +
    ifelse(sex == "Male", 4, 0) +
    rnorm(n, 0, 10)
sbp <- round(pmax(pmin(sbp_base, 200), 85))

# DBP correlated with SBP
dbp_base <- 0.55 * sbp + 15 + rnorm(n, 0, 7)
dbp <- round(pmax(pmin(dbp_base, 120), 50))

# ── Glucose ───────────────────────────────────────────────────────────────────
# Insulin resistance: increases with BMI and age
glucose_base <- 70 +
    0.80 * BMI_true +
    0.25 * age +
    ifelse(sex == "Male", 5, 0) +
    rnorm(n, 0, 14)
glucose <- round(pmax(glucose_base, 60))

# ── Cholesterol ───────────────────────────────────────────────────────────────
# Increases with BMI and age; slightly lower in current smokers (known effect)
cholesterol_base <- 120 +
    1.80 * BMI_true +
    0.70 * age +
    ifelse(sex == "Female", 10, 0) +
    ifelse(smoking_clean == "current", -8, 0) +
    rnorm(n, 0, 25)
cholesterol <- round(pmax(cholesterol_base, 100))

# ── CRP (inflammation marker, log-normal) ─────────────────────────────────────
# Elevated with BMI, smoking, and advanced stage
crp_log_mean <- 0.5 +
    0.045 * BMI_true +
    ifelse(smoking_clean == "current", 0.55, ifelse(smoking_clean == "former", 0.20, 0)) +
    ifelse(stage == "III", 0.40, ifelse(stage == "IV", 0.80, 0)) +
    rnorm(n, 0, 0.5)
crp <- round(exp(crp_log_mean), 2)

# ── Visit dates ───────────────────────────────────────────────────────────────
# Multi-year recruitment; later years have more advanced-stage diagnoses
visit_year_prob <- function(stg) {
    if (stg == "IV") c(0.10, 0.20, 0.30, 0.40)
    else             c(0.20, 0.25, 0.30, 0.25)
}
base_dates <- as.Date(c("2018-01-10", "2020-01-10", "2023-01-10", "2025-01-10"))
visit_date <- mapply(function(stg) {
    base <- sample(base_dates, 1, prob = visit_year_prob(stg))
    as.character(base + sample(0:300, 1))
}, stage)

# ── Hospital site ─────────────────────────────────────────────────────────────
# "Turin " with trailing space: intentional for string-cleaning exercise
site <- sample(c("Milan", "Rome", "Turin", "Turin "), n, replace = TRUE,
               prob = c(0.40, 0.30, 0.15, 0.15))

# ── Assemble clinical dataframe ───────────────────────────────────────────────
clinical_df <- data.frame(
    patient_id       = patient_ids,
    site             = site,
    visit_date       = visit_date,
    age              = age,
    sex              = sex,
    smoking          = smoking_raw,
    treatment        = treatment,
    stage            = stage,
    weight_kg        = weight,
    height_cm        = height,
    sbp_mmhg         = sbp,
    dbp_mmhg         = dbp,
    glucose_mgdl     = glucose,
    cholesterol_mgdl = cholesterol,
    crp_ngml         = crp,
    stringsAsFactors = FALSE
)

write.csv(clinical_df, file = "data/clinical_data.csv", row.names = FALSE)
cat("clinical_data.csv created with", nrow(clinical_df), "rows and",
    ncol(clinical_df), "columns\n")

# ── Sanity checks ─────────────────────────────────────────────────────────────
cat("\n--- Sanity checks ---\n")
bmi_tert <- cut(BMI_true, breaks = quantile(BMI_true, c(0, 1/3, 2/3, 1)),
                include.lowest = TRUE, labels = c("Low BMI", "Mid BMI", "High BMI"))
cat("Mean SBP by BMI tertile:\n");     print(round(tapply(sbp,       bmi_tert,       mean), 1))
cat("Mean glucose by BMI tertile:\n"); print(round(tapply(glucose,   bmi_tert,       mean), 1))
cat("Mean CRP by stage:\n");           print(round(tapply(crp,       stage,          mean), 2))
cat("Stage distribution by smoking:\n"); print(table(smoking_clean, stage))

# ── Lab results (2/3 of patients, for join exercise) ──────────────────────────
n_lab   <- round(n * 2 / 3)
lab_ids <- sort(sample(patient_ids, n_lab))
idx     <- match(lab_ids, patient_ids)

# Hemoglobin: lower in females and advanced stage (anaemia of chronic disease)
hgb_base <- ifelse(sex[idx] == "Male", 14.8, 13.0) +
    ifelse(stage[idx] == "III", -0.5, ifelse(stage[idx] == "IV", -1.2, 0)) +
    rnorm(n_lab, 0, 1.2)
hemoglobin <- round(pmax(hgb_base, 7.5), 1)

# WBC: elevated in current smokers and advanced stage
wbc_base <- 6.5 +
    ifelse(smoking_clean[idx] == "current", 1.2, 0) +
    ifelse(stage[idx] %in% c("III", "IV"), 0.8, 0) +
    rnorm(n_lab, 0, 1.8)
wbc <- round(pmax(wbc_base, 2.0), 2)

# Platelets: mild drop in stage IV
plt_base <- 240 + ifelse(stage[idx] == "IV", -30, 0) + rnorm(n_lab, 0, 55)
platelets <- round(pmax(plt_base, 50))

# ALT: log-normal, increases with BMI (hepatic steatosis)
alt_log <- 3.0 + 0.03 * BMI_true[idx] + rnorm(n_lab, 0, 0.45)
alt     <- round(exp(alt_log))

# Creatinine: increases with age, BMI, and male sex
creat_base <- 0.55 +
    0.005 * age[idx] +
    0.008 * BMI_true[idx] +
    ifelse(sex[idx] == "Male", 0.15, 0) +
    rnorm(n_lab, 0, 0.15)
creatinine <- round(pmax(creat_base, 0.4), 2)

lab_df <- data.frame(
    patient_id      = lab_ids,
    hemoglobin_gdl  = hemoglobin,
    wbc_10e9l       = wbc,
    platelets_10e9l = platelets,
    alt_ul          = alt,
    creatinine_mgdl = creatinine,
    stringsAsFactors = FALSE
)

write.csv(lab_df, file = "data/lab_results.csv", row.names = FALSE)
cat("\nlab_results.csv created with", nrow(lab_df), "rows and",
    ncol(lab_df), "columns\n")