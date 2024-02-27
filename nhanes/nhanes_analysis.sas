/* get data */
LIBNAME nh_path "/home/u63563888/schiltz24/nhanes/nhanesData/cleaned";

DATA nhanes;
	SET nh_path.nhanes_cleaned_11 nh_path.nhanes_cleaned_13
		nh_path.nhanes_cleaned_15 nh_path.nhanes_cleaned_17;
	
	IF ethnicity = "Non-Hispanic Black" THEN ethnicity_binary = "Black";
	ELSE ethnicity_binary = "Other";
RUN;


/*******************************************************/
/*****/
/*****	DATA PREP */
/*****/
/********************************************************/

/* other females */
DATA other_f;
	SET nhanes;
	WHERE sex = "Female" AND ethnicity_binary = "Other";
	
	ln_risk = -29.799 * log(age) - 
				13.578 * log(high_chol) + 
  				13.54 * log(total_chol) + 
 	 			4.884 * log(age)**2 - 3.114 * log(age) * log(total_chol) + 
  				3.149 * log(age) * log(high_chol) + 
  				2.019 * (has_hype_med) * log(sbp) +
  				1.957 * (1 - has_hype_med) * log(sbp) +
  				0.661 * is_diabetic + 7.5740 * does_smoke + 
  				-1.665 * does_smoke * log(age);
  				
  	risk_score = 1 - 0.9665**exp(ln_risk + 29.1817);
RUN;
	

/* black females */
DATA black_f;
	SET nhanes;
	WHERE sex = "Female" AND ethnicity_binary = "Black";
	
	ln_risk = 17.1141 * log(age) + 
				-18.9196 * log(high_chol) + 
				0.9396 * log(total_chol) + 
				4.4748 * log(age) * log(high_chol) + 
				29.2907 * (has_hype_med) * log(sbp) + 
				27.8197 * (1 - has_hype_med) * log(sbp) +
				-6.4321 * (has_hype_med) * log(sbp) * log(age) +
    			-6.0873 * (1 - has_hype_med) * log(sbp) * log(age) +
    			0.8738 * is_diabetic + 
    			0.6908 * does_smoke;
    			
    risk_score = 1 - 0.95334**exp(ln_risk - 86.6081);
RUN;


/* other males */
DATA other_m;
	SET nhanes;
	WHERE sex = "Male" AND ethnicity_binary = "Other";
	
	ln_risk = 12.344 * log(age) + 
				-7.990 * log(high_chol) + 
    			11.853 * log(total_chol) + 
 	   			1.797 * (has_hype_med) * log(sbp) + 
    			1.764 * (1 - has_hype_med) * log(sbp) +
    			0.658 * is_diabetic + 
	    		7.837 * does_smoke +
    			1.769 * log(age) * log(high_chol) + 
    			-2.664 * log(age) * log(total_chol) +
    			-1.795 * does_smoke * log(age);
    		
	risk_score = 1 - 0.9144**exp(ln_risk - 61.18);
RUN;


/* black males */
DATA black_m;
	SET nhanes;
	WHERE sex = "Male" AND ethnicity_binary = "Black";
	
	ln_risk = 2.469 * log(age) + 
				-0.307 * log(high_chol) + 
 	  	 		0.302 * log(total_chol) + 
    			1.916 * (has_hype_med) * log(sbp) + 
    			1.809 * (1 - has_hype_med) * log(sbp) +
    			0.645 * is_diabetic + 
    			0.549 * does_smoke;
    			
    risk_score = 1 - 0.8954**exp(ln_risk - 19.54);
RUN;


/* stack datasets */
DATA risk_scores;
	SET other_f black_f other_m black_m;
	
	has_hype_med_char = put(has_hype_med, 8.);
	is_diabetic_char = put(is_diabetic, 8.);
	does_smoke_char = put(does_smoke, 8.);
RUN;


/* threshold groups */
DATA group_one;
	SET risk_scores;
	
	IF risk_score >= 0.075 THEN is_rec = "1";
	ELSE is_rec = "0";
RUN;

DATA group_two;
	SET risk_scores;
	WHERE has_hbp = 1;
	
	IF risk_score >= 0.100 THEN is_rec = "1";
	ELSE is_rec = "0";
RUN;


/*******************************************************/
/*****/
/*****	DATA EXPORT */
/*****/
/********************************************************/

LIBNAME exp_path "/home/u63563888/schiltz24/nhanes/risk_score_datasets";

DATA exp_path.normal_rec;
	SET group_one;
RUN;

DATA exp_path.hbp_rec;
	SET group_two;
RUN;


/*******************************************************/
/*****/
/*****	DATA ANALYSIS */
/*****/
/********************************************************/

LIBNAME nh_path "/home/u63563888/schiltz24/nhanes/risk_score_datasets";

DATA group_one;
	SET nh_path.normal_rec;
RUN;

DATA group_two;
	SET nh_path.hbp_rec;
RUN;


/* macro to get age distribution by statin recommendation */
%MACRO get_statin_rec_plot(dataset, sex, ethnicity_binary);
	PROC FREQ DATA = &dataset NOPRINT;
		WHERE sex = &sex AND ethnicity_binary = &ethnicity_binary;
		TABLE age * is_rec / OUT = freq_data OUTPCT;
	RUN;
	
	PROC SGPANEL DATA = freq_data; 
		PANELBY is_rec / LAYOUT = ROWLATTICE;
		VBAR age / RESPONSE = pct_row;
		COLAXIS VALUESROTATE = vertical;
		REFLINE 50 100 / AXIS = y 
						LINEATTRS = (COLOR = darkred PATTERN = dash);
	RUN;
%MEND;

/* all observations */
%get_statin_rec_plot(group_one, "Male", "Other");   /* ~56 */
%get_statin_rec_plot(group_one, "Female", "Other"); /* ~66 */
%get_statin_rec_plot(group_one, "Male", "Black");   /* ~49 */
%get_statin_rec_plot(group_one, "Female", "Black"); /* ~58 */

/* hbp observations */
%get_statin_rec_plot(group_two, "Male", "Other");   /* ~59 */
%get_statin_rec_plot(group_two, "Female", "Other"); /* ~68 */
%get_statin_rec_plot(group_two, "Male", "Black");   /* ~53 */
%get_statin_rec_plot(group_two, "Female", "Black"); /* ~60 */


/* macro to get age distribution by subgroup */
%MACRO get_statin_plot_by_subgroup(dataset, title);
	/* create subgroups for race and sex */
	DATA groupData;
		SET &dataset;
		
		LENGTH subgroup $ 20;
		IF sex = "Male" AND ethnicity_binary = "Other" THEN subgroup = "Other Males";
		ELSE IF sex = "Female" AND ethnicity_binary = "Other" THEN subgroup = "Other Females";
		ELSE IF sex = "Male" AND ethnicity_binary = "Black" THEN Subgroup = "Black Males";
		ELSE subgroup = "Black Females";
	RUN;
	
	PROC FREQ DATA = groupData NOPRINT;
		TABLE subgroup * age * is_rec / OUT = freq_data OUTPCT;
	RUN;
	
	/* only keep data for those that are recommended */
	DATA recommendedData;
		SET freq_data;
		WHERE is_rec = "1";
	RUN;
		
	PROC SGPANEL DATA = recommendedData; 
		PANELBY subgroup / NOVARNAME;
		VBAR age / RESPONSE = pct_row;
		COLAXIS FITPOLICY = staggerthin LABEL = "Age";
		ROWAXIS LABEL = "% Recommended to Take Statin Medication";
		TITLE &title;
		REFLINE 50 100 / AXIS = y 
						LINEATTRS = (COLOR = red PATTERN = dot);
	RUN;
%MEND;

%get_statin_plot_by_subgroup(group_one, "Statin Recommendation by Age for All Observations")
%get_statin_plot_by_subgroup(group_two, "Statin Recommendation by Age for Observations with HBP")


/*******************************************************/
/*****/
/*****	TABLE 1 */
/*****/
/********************************************************/

PROC SORT DATA = group_one;
	BY seqn;
RUN;

PROC SORT DATA = group_two;
	BY seqn;
RUN;

DATA merged_groups;
	MERGE group_one (IN=inOne RENAME=(is_rec=all_rec)) 
			group_two(RENAME=(is_rec=hbp_rec));
	BY seqn;
	IF inOne;
RUN;


/* recommendation distribution check */
PROC FREQ DATA = merged_groups;
	TABLE hbp_rec;
RUN;

PROC FREQ DATA = group_two;
	TABLE is_rec;
RUN;


/* data for table 1 */
DATA table_one_data;
	SET merged_groups;
	
	IF age < 50 THEN age_cat = "40-49";
	ELSE IF age >= 50 AND age < 60 THEN age_cat = "50-59";
	ELSE IF age >= 60 AND age < 70 THEN age_cat = "60-69";
	ELSE age_cat = "70-79";
RUN;


/* create table 1 */
PROC TABULATE DATA = table_one_data;
	CLASS age_cat ethnicity has_hype_med_char 
			is_diabetic_char does_smoke_char 
			all_rec hbp_rec;
	VAR sbp high_chol total_chol;
	TABLE age_cat="Age Category" ethnicity="Ethnicity" 
			has_hype_med_char="Does Take Hypertension Medication" 
			is_diabetic_char="Is Diabetic" 
			does_smoke_char="Does Smoke" 
			sbp="Systolic Blood Pressure"*mean 
			high_chol*mean total_chol*mean, 
			all_rec hbp_rec ;
RUN;


/*******************************************************/
/*****/
/*****	DATA MODELING */
/*****/
/********************************************************/

/* preliminary models */
/* C = 97.2 */
PROC LOGISTIC DATA = group_one;
        CLASS ethnicity_binary (REF = "Other")
        		has_hype_med_char (REF = "0") 
                is_diabetic_char (REF = "0")
                does_smoke_char (REF = "0") / PARAM = REFERENCE;
        MODEL is_rec (EVENT = "1") = 
        		age ethnicity_binary sbp high_chol total_chol 
        		has_hype_med_char is_diabetic_char 
        		does_smoke_char / EXPB;
RUN;

/* C = 96.8 */
PROC LOGISTIC DATA = group_two;
        CLASS ethnicity_binary (REF = "Other")
        		has_hype_med_char (REF = "0") 
                is_diabetic_char (REF = "0")
                does_smoke_char (REF = "0") / PARAM = REFERENCE;
        MODEL is_rec (EVENT = "1") = 
        		age ethnicity_binary sbp high_chol total_chol 
        		has_hype_med_char is_diabetic_char 
        		does_smoke_char / EXPB;
RUN;


/* predictors with high odds ratios */
PROC FREQ DATA = group_one;
	TABLE has_hype_med_char * is_rec
			is_diabetic_char * is_rec
			does_smoke_char * is_rec;
RUN;

PROC FREQ DATA = group_two;
	TABLE has_hype_med_char * is_rec
			is_diabetic_char * is_rec
			does_smoke_char * is_rec;
RUN;


/* macro to train/test statin recommendation model */
%MACRO get_statin_rec_model_results(dataset);
	PROC SORT DATA = &dataset OUT = sorted_data;
		BY ethnicity_binary;
	RUN;
	
	PROC SURVEYSELECT DATA = sorted_data 
						RATE = 0.7 OUT = split_data 
						SEED = 123 OUTALL NOPRINT;
		STRATA ethnicity_binary;
	RUN;
	
	DATA train_data test_data; 
		SET split_data; 
		IF selected = 1 THEN OUTPUT train_data; 
		ELSE OUTPUT test_data; 
		DROP selected;
	RUN;
	
	PROC LOGISTIC DATA = train_data NOPRINT;
	        CLASS ethnicity_binary (REF = "Other")
	        		has_hype_med_char (REF = "0") 
	                is_diabetic_char (REF = "0")
	                does_smoke_char (REF = "0") / PARAM = REFERENCE;
	        MODEL is_rec (EVENT = "1") = 
	        		age ethnicity_binary sbp high_chol total_chol 
	        		has_hype_med_char is_diabetic_char 
	        		does_smoke_char / EXPB;
	        SCORE DATA = test_data OUT = model_results;
	RUN;
	
	DATA result_data;
		SET model_results;
		RENAME i_is_rec = predicted_val
				P_0 = prob_0
				P_1 = prob_1;
		DROP SelectionProb SamplingWeight f_is_rec;
	RUN;
	
	PROC FREQ DATA = result_data;
		TABLE is_rec * predicted_val / nocol norow;
	RUN;
%MEND;


%get_statin_rec_model_results(group_one); /* 89.28% */
%get_statin_rec_model_results(group_two); /* 88.09% */

