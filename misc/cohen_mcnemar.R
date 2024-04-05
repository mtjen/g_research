library(irr)
library(psych)
library(readxl)
library(kableExtra)
library(dplyr)


# import data
data <- read_excel("/Users/mtjen/Desktop/Kappa_McNemar_Data\ 3.28.24.xlsx")


clean_data <- data |> 
                select(`PAIRS_sleep_status (0=good sleeper; 1=poor sleeper)`,
                       `Act_TST_recommended age (0=good sleeper; 1=poor sleeper)`,
                       `Act_SE_recommended 85% (0=good sleeper; 1=poor sleeper)`,
                       `Act_Both_TST_SE_recommended threshold (0=good sleeper; 1=poor sleeper)`) |>
                rename(PAIRS_sleep_status = 
                         `PAIRS_sleep_status (0=good sleeper; 1=poor sleeper)`,
                       Act_TST_recommended_age = 
                         `Act_TST_recommended age (0=good sleeper; 1=poor sleeper)`,
                       Act_SE_recommended_85 = 
                         `Act_SE_recommended 85% (0=good sleeper; 1=poor sleeper)`,
                       Act_Both_TST_SE_recommended_threshold = 
                         `Act_Both_TST_SE_recommended threshold (0=good sleeper; 1=poor sleeper)`)


# empty dataframe for results
results <- data.frame(matrix(ncol = 4, nrow = 0))
colnames(results) <- c("Pairing", "Statistic", "Value", "P-Value")


# pair one
kap_res_one <- kappa2(clean_data |> select(PAIRS_sleep_status, Act_TST_recommended_age))

kap_res_two <- cohen.kappa(cbind(clean_data$PAIRS_sleep_status,
                                 clean_data$Act_TST_recommended_age),
                           alpha = 0.05)

mcnemar_res <- mcnemar.test(table(sleep = clean_data$PAIRS_sleep_status,
                                  tst = clean_data$Act_TST_recommended_age))

results[nrow(results)+1,] = c("Sleep Status and TST Recommended", "Cohen's Kappa",
                              "0.11 (-0.12, 0.33)","0.35")
results[nrow(results)+1,] = c("Sleep Status and TST Recommended", "McNemar",
                              "3.23","0.07")


# pair two
kap_res_one <- kappa2(clean_data |> select(PAIRS_sleep_status, Act_SE_recommended_85))

kap_res_two <- cohen.kappa(cbind(clean_data$PAIRS_sleep_status,
                                 clean_data$Act_SE_recommended_85),
                           alpha = 0.05)

mcnemar_res <- mcnemar.test(table(sleep = clean_data$PAIRS_sleep_status,
                                  se = clean_data$Act_SE_recommended_85))

results[nrow(results)+1,] = c("Sleep Status and SE Recommended", "Cohen's Kappa",
                              "0.27 (0.07, 0.48)","0.01")
results[nrow(results)+1,] = c("Sleep Status and SE Recommended", "McNemar",
                              "6.50","0.01")


# pair three
kap_res_one <- kappa2(clean_data |> select(PAIRS_sleep_status, 
                                           Act_Both_TST_SE_recommended_threshold))

kap_res_two <- cohen.kappa(cbind(clean_data$PAIRS_sleep_status,
                                 clean_data$Act_Both_TST_SE_recommended_threshold),
                           alpha = 0.05)

mcnemar_res <- mcnemar.test(table(sleep = clean_data$PAIRS_sleep_status,
                                  both = clean_data$Act_Both_TST_SE_recommended_threshold))

results[nrow(results)+1,] = c("Sleep Status and Both TST and SE Recommended", 
                              "Cohen's Kappa",
                              "0.16 (-0.01, 0.33)","0.08")
results[nrow(results)+1,] = c("Sleep Status and Both TST and SE Recommended", "McNemar",
                              "17.46","0.00")


# pair four
kap_res_one <- kappa2(clean_data |> select(Act_TST_recommended_age, Act_SE_recommended_85))

kap_res_two <- cohen.kappa(cbind(clean_data$Act_TST_recommended_age,
                                 clean_data$Act_SE_recommended_85),
                           alpha = 0.05)

mcnemar_res <- mcnemar.test(table(tst = clean_data$Act_TST_recommended_age,
                                  se = clean_data$Act_SE_recommended_85))

results[nrow(results)+1,] = c("TST Recommended and SE Recommended", 
                              "Cohen's Kappa",
                              "0.29 (0.06, 0.51)","0.02")
results[nrow(results)+1,] = c("TST Recommended and SE Recommended", "McNemar",
                              "0.16","0.69")


kable(results)

