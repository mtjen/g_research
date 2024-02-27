# package import
library(dplyr)
library(haven)
library(SHAPforxgboost)
library(shapviz)
library(xgboost)


# import data
all_data <- read_sas("/Users/mtjen/Desktop/schiltz24/nhanes_project/normal_rec.sas7bdat")
hbp_data <- read_sas("/Users/mtjen/Desktop/schiltz24/nhanes_project/hbp_rec.sas7bdat")



############################################################
######
###### ALL DATA
######
############################################################

# create dataframe
all_data_numeric <- all_data |>
  select(age, sex, ethnicity, sbp, dbp, high_chol, 
         total_chol, has_hype_med, is_diabetic, 
         does_smoke, is_rec) |>
  mutate(is_male = case_when(sex == "Male" ~ 1,
                             TRUE ~ 0),
         is_black = case_when(ethnicity == "Non-Hispanic Black" ~ 1,
                              TRUE ~ 0)) |>
  mutate(is_rec = as.numeric(is_rec)) |>
  select(-sex, -ethnicity)

# make data (minus outcome) into matrix object
all_data_matrix <- as.matrix(all_data_numeric |> select(-is_rec))

# create xgboost model
all_mod <- xgboost(data = all_data_matrix, label = all_data_numeric$is_rec, 
                   nrounds = 1, objective = "binary:logistic")

# get shapley values
all_shap_long <- shap.prep(xgb_model = all_mod, X_train = all_data_matrix)

# visualize
shap.plot.summary(all_shap_long)     # shapley values plot
# xgb.plot.tree(model = all_mod)     # decision tree - useless w/ all the variables

# force plot for all observations
force_shap_all <- shap.values(xgb_model = all_mod, X_train = all_data_matrix)
prepped_force_all <- shap.prep.stack.data(shap_contrib = force_shap_all$shap_score)
shap.plot.force_plot(prepped_force_all)

# force and waterfall plots by average values for sex+race
# other male
all_avg_o_m <- as.data.frame.list(colMeans(all_data_numeric |> 
                                             filter(is_male == 1, is_black == 0) |>
                                             select(-is_rec)))

all_avg_o_m_shp <- shapviz(all_mod, X_pred = as.matrix(all_avg_o_m), X = all_avg_o_m)
sv_waterfall(all_avg_o_m_shp, row_id = 1)
sv_force(all_avg_o_m_shp, row_id = 1)

# other female
all_avg_o_f <- as.data.frame.list(colMeans(all_data_numeric |> 
                                             filter(is_male == 0, is_black == 0) |>
                                             select(-is_rec)))

all_avg_o_f_shp <- shapviz(all_mod, X_pred = as.matrix(all_avg_o_f), X = all_avg_o_f)
sv_waterfall(all_avg_o_f_shp, row_id = 1)
sv_force(all_avg_o_f_shp, row_id = 1)

# black male
all_avg_b_m <- as.data.frame.list(colMeans(all_data_numeric |> 
                                             filter(is_male == 1, is_black == 1) |>
                                             select(-is_rec)))

all_avg_b_m_shp <- shapviz(all_mod, X_pred = as.matrix(all_avg_b_m), X = all_avg_b_m)
sv_waterfall(all_avg_b_m_shp, row_id = 1)
sv_force(all_avg_b_m_shp, row_id = 1)

# black female
all_avg_b_f <- as.data.frame.list(colMeans(all_data_numeric |> 
                                             filter(is_male == 0, is_black == 1) |>
                                             select(-is_rec)))

all_avg_b_f_shp <- shapviz(all_mod, X_pred = as.matrix(all_avg_b_f), X = all_avg_b_f)
sv_waterfall(all_avg_b_f_shp, row_id = 1)
sv_force(all_avg_b_f_shp, row_id = 1)



############################################################
######
###### HBP DATA
######
############################################################

# create dataframe
hbp_data_numeric <- hbp_data |>
  select(age, sex, ethnicity, sbp, dbp, high_chol, 
         total_chol, has_hype_med, is_diabetic, 
         does_smoke, is_rec) |>
  mutate(is_male = case_when(sex == "Male" ~ 1,
                             TRUE ~ 0),
         is_black = case_when(ethnicity == "Non-Hispanic Black" ~ 1,
                              TRUE ~ 0)) |>
  mutate(is_rec = as.numeric(is_rec)) |>
  select(-sex, -ethnicity)

# make data (minus outcome) into matrix object
hbp_data_matrix <- as.matrix(hbp_data_numeric |> select(-is_rec))

# create xgboost model
hbp_mod <- xgboost(data = hbp_data_matrix, label = hbp_data_numeric$is_rec, 
                   nrounds = 1, objective = "binary:logistic")

# get shapley values
hbp_shap_long <- shap.prep(xgb_model = hbp_mod, X_train = hbp_data_matrix)

# visualize
shap.plot.summary(hbp_shap_long)     # shapley values plot
# xgb.plot.tree(model = hbp_mod)     # decision tree - useless w/ all the variables

# force plot for all observations
force_shap_hbp <- shap.values(xgb_model = hbp_mod, X_train = hbp_data_matrix)
prepped_force_hbp <- shap.prep.stack.data(shap_contrib = force_shap_hbp$shap_score)
shap.plot.force_plot(prepped_force_hbp)

# force and waterfall plots by average values for sex+race
# other male
hbp_avg_o_m <- as.data.frame.list(colMeans(hbp_data_numeric |> 
                                             filter(is_male == 1, is_black == 0) |>
                                             select(-is_rec)))

hbp_avg_o_m_shp <- shapviz(hbp_mod, X_pred = as.matrix(hbp_avg_o_m), X = hbp_avg_o_m)
sv_waterfall(hbp_avg_o_m_shp, row_id = 1)
sv_force(hbp_avg_o_m_shp, row_id = 1)

# other female
hbp_avg_o_f <- as.data.frame.list(colMeans(hbp_data_numeric |> 
                                             filter(is_male == 0, is_black == 0) |>
                                             select(-is_rec)))

hbp_avg_o_f_shp <- shapviz(hbp_mod, X_pred = as.matrix(hbp_avg_o_f), X = hbp_avg_o_f)
sv_waterfall(hbp_avg_o_f_shp, row_id = 1)
sv_force(hbp_avg_o_f_shp, row_id = 1)

# black male
hbp_avg_b_m <- as.data.frame.list(colMeans(hbp_data_numeric |> 
                                             filter(is_male == 1, is_black == 1) |>
                                             select(-is_rec)))

hbp_avg_b_m_shp <- shapviz(hbp_mod, X_pred = as.matrix(hbp_avg_b_m), X = hbp_avg_b_m)
sv_waterfall(hbp_avg_b_m_shp, row_id = 1)
sv_force(hbp_avg_b_m_shp, row_id = 1)

# black female
hbp_avg_b_f <- as.data.frame.list(colMeans(hbp_data_numeric |> 
                                             filter(is_male == 0, is_black == 1) |>
                                             select(-is_rec)))

hbp_avg_b_f_shp <- shapviz(hbp_mod, X_pred = as.matrix(hbp_avg_b_f), X = hbp_avg_b_f)
sv_waterfall(hbp_avg_b_f_shp, row_id = 1)
sv_force(hbp_avg_b_f_shp, row_id = 1)



############################################################
######
###### SHAPLEY PLOTS
######
############################################################

# function to create shapley plots (sex: Male or Female, ethnicity: Black or Other)
create_shapley_plot <- function(dataset, sex, ethnicity) {
  is_male_indic <- ifelse(sex == "Male", 1, 0)
  is_black_indic <- ifelse(ethnicity == "Black", 1, 0)
  
  filtered_data <- dataset |> filter(is_male == is_male_indic, 
                                     is_black == is_black_indic) |>
    select(-is_male, -is_black)
  
  # make data (minus outcome) into matrix object
  dataset_matrix <- as.matrix(filtered_data |> select(-is_rec))
  
  # create xgboost model
  xgMod <- xgboost(data = dataset_matrix, label = filtered_data$is_rec, 
                   nrounds = 1, objective = "binary:logistic")
  
  # get shapley values
  shap_long <- shap.prep(xgb_model = xgMod, X_train = dataset_matrix)
  
  # plot shapley values
  return(shap.plot.summary(shap_long))
}


create_shapley_plot(all_data_numeric, "Male", "Other")
create_shapley_plot(all_data_numeric, "Male", "Black")
create_shapley_plot(all_data_numeric, "Female", "Other")
create_shapley_plot(all_data_numeric, "Female", "Black")

create_shapley_plot(hbp_data_numeric, "Male", "Other")
create_shapley_plot(hbp_data_numeric, "Male", "Black")
create_shapley_plot(hbp_data_numeric, "Female", "Other")
create_shapley_plot(hbp_data_numeric, "Female", "Black")


############################################################
######
###### HELPFUL LINKS
######
############################################################
# https://xgboost.readthedocs.io/en/stable/parameter.html 
# https://liuyanguu.github.io/post/2019/07/18/visualization-of-shap-for-xgboost/
# https://www.kaggle.com/code/rtatman/machine-learning-with-xgboost-in-r
# https://www.r-bloggers.com/2021/04/how-to-plot-xgboost-trees-in-r/
# https://www.r-bloggers.com/2022/06/visualize-shap-values-without-tears/
