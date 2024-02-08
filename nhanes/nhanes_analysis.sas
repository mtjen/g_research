/* get data */
LIBNAME nh_path "/home/u63563888/schiltz24/nhanes/nhanesData/cleaned";

DATA nhanes;
	SET nh_path.nhanes_cleaned_11 nh_path.nhanes_cleaned_13
		nh_path.nhanes_cleaned_15 nh_path.nhanes_cleaned_17;
	
	IF ethnicity ^= "Non-Hispanic Black" THEN ethnicity = "Other";
RUN;


/*******************************************************/
/*****/
/*****	DATA PREP */
/*****/
/********************************************************/

/* other females */
DATA other_f;
	SET nhanes;
	WHERE sex = "Female" AND ethnicity = "Other";
	
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
	WHERE sex = "Female" AND ethnicity = "Non-Hispanic Black";
	
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


/* white males */
DATA other_m;
	SET nhanes;
	WHERE sex = "Male" AND ethnicity = "Other";
	
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
	WHERE sex = "Male" AND ethnicity = "Non-Hispanic Black";
	
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


/* statin recommendation breakdown by age, sex, race */
PROC FREQ DATA = group_one;
	WHERE sex = "Male" AND ethnicity = "Other";
	TABLE age * is_rec / out = g1_m_o OUTPCT;
RUN;

PROC SGPANEL DATA = g1_m_o; 
	PANELBY is_rec / LAYOUT = ROWLATTICE;
	VBAR age / RESPONSE = pct_row;
	COLAXIS VALUESROTATE = vertical;
	REFLINE 50 / AXIS = y 
					LINEATTRS = (COLOR = darkred PATTERN = dash);
RUN;


PROC FREQ DATA = group_one;
	WHERE sex = "Female" AND ethnicity = "Other";
	TABLE age * is_rec / out = g1_f_o OUTPCT;
RUN;

PROC SGPANEL DATA = g1_f_o; 
	PANELBY is_rec / LAYOUT = ROWLATTICE;
	VBAR age / RESPONSE = pct_row;
	COLAXIS VALUESROTATE = vertical;
	REFLINE 50 / AXIS = y 
					LINEATTRS = (COLOR = darkred PATTERN = dash);
RUN;


/* very low */
PROC FREQ DATA = group_one;
	WHERE sex = "Male" AND ethnicity = "Non-Hispanic Black";
	TABLE age * is_rec / out = g1_m_b OUTPCT;
RUN;

PROC SGPANEL DATA = g1_m_b; 
	PANELBY is_rec / LAYOUT = ROWLATTICE;
	VBAR age / RESPONSE = pct_row;
	COLAXIS VALUESROTATE = vertical;
	REFLINE 50 / AXIS = y 
					LINEATTRS = (COLOR = darkred PATTERN = dash);
RUN;


PROC FREQ DATA = group_one;
	WHERE sex = "Female" AND ethnicity = "Non-Hispanic Black";
	TABLE age * is_rec / out = g1_f_b OUTPCT;
RUN;

PROC SGPANEL DATA = g1_f_b; 
	PANELBY is_rec / LAYOUT = ROWLATTICE;
	VBAR age / RESPONSE = pct_row;
	COLAXIS VALUESROTATE = vertical;
	REFLINE 50 / AXIS = y 
					LINEATTRS = (COLOR = darkred PATTERN = dash);
RUN;


/* statin recommendation breakdown by age - high blood pressure */
PROC FREQ DATA = group_two;
	WHERE sex = "Male" AND ethnicity = "Other";
	TABLE age * is_rec / out = g2_m_o OUTPCT;
RUN;

PROC SGPANEL DATA = g2_m_o; 
	PANELBY is_rec / LAYOUT = ROWLATTICE;
	VBAR age / RESPONSE = pct_row;
	COLAXIS VALUESROTATE = vertical;
	REFLINE 50 / AXIS = y 
					LINEATTRS = (COLOR = darkred PATTERN = dash);
RUN;


PROC FREQ DATA = group_two;
	WHERE sex = "Female" AND ethnicity = "Other";
	TABLE age * is_rec / out = g2_f_o OUTPCT;
RUN;

PROC SGPANEL DATA = g2_f_o; 
	PANELBY is_rec / LAYOUT = ROWLATTICE;
	VBAR age / RESPONSE = pct_row;
	COLAXIS VALUESROTATE = vertical;
	REFLINE 50 / AXIS = y 
					LINEATTRS = (COLOR = darkred PATTERN = dash);
RUN;


PROC FREQ DATA = group_two;
	WHERE sex = "Male" AND ethnicity = "Non-Hispanic Black";
	TABLE age * is_rec / out = g2_m_b OUTPCT;
RUN;

PROC SGPANEL DATA = g2_m_b; 
	PANELBY is_rec / LAYOUT = ROWLATTICE;
	VBAR age / RESPONSE = pct_row;
	COLAXIS VALUESROTATE = vertical;
	REFLINE 50 / AXIS = y 
					LINEATTRS = (COLOR = darkred PATTERN = dash);
RUN;


PROC FREQ DATA = group_two;
	WHERE sex = "Female" AND ethnicity = "Non-Hispanic Black";
	TABLE age * is_rec / out = g2_f_b OUTPCT;
RUN;

PROC SGPANEL DATA = g2_f_b; 
	PANELBY is_rec / LAYOUT = ROWLATTICE;
	VBAR age / RESPONSE = pct_row;
	COLAXIS VALUESROTATE = vertical;
	REFLINE 50 / AXIS = y 
					LINEATTRS = (COLOR = darkred PATTERN = dash);
RUN;


/*******************************************************/
/*****/
/*****	DATA MODELING */
/*****/
/********************************************************/

/* preliminary models */
/* C = 97.2 */
PROC LOGISTIC DATA = group_one;
        CLASS ethnicity (REF = "Other")
        		has_hype_med_char (REF = "0") 
                is_diabetic_char (REF = "0")
                does_smoke_char (REF = "0") / PARAM = REFERENCE;
        MODEL is_rec (EVENT = "1") = 
        		age ethnicity sbp high_chol total_chol 
        		has_hype_med_char is_diabetic_char 
        		does_smoke_char / EXPB;
RUN;

/* C = 96.8 */
PROC LOGISTIC DATA = group_two;
        CLASS ethnicity (REF = "Other")
        		has_hype_med_char (REF = "0") 
                is_diabetic_char (REF = "0")
                does_smoke_char (REF = "0") / PARAM = REFERENCE;
        MODEL is_rec (EVENT = "1") = 
        		age ethnicity sbp high_chol total_chol 
        		has_hype_med_char is_diabetic_char 
        		does_smoke_char / EXPB;
RUN;


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


/* train-test split - all */
PROC SORT DATA = group_one OUT = group_one_sorted;
	BY ethnicity;
RUN;

PROC SURVEYSELECT DATA = group_one_sorted 
					RATE = 0.7 OUT = group_one_split 
					SEED = 123 OUTALL;
	STRATA ethnicity;
RUN;

PROC FREQ DATA = group_one_split; 
	TABLE ethnicity * selected;
RUN;

DATA g1_train g1_test; 
	SET group_one_split; 
	IF selected = 1 THEN OUTPUT g1_train; 
	ELSE OUTPUT g1_test; 
	DROP selected;
RUN;


PROC LOGISTIC DATA = g1_train;
        CLASS ethnicity (REF = "Other")
        		has_hype_med_char (REF = "0") 
                is_diabetic_char (REF = "0")
                does_smoke_char (REF = "0") / PARAM = REFERENCE;
        MODEL is_rec (EVENT = "1") = 
        		age ethnicity sbp high_chol total_chol 
        		has_hype_med_char is_diabetic_char 
        		does_smoke_char / EXPB;
        SCORE DATA = g1_test OUT = g1_results;
RUN;

DATA g1_results_data;
	SET g1_results;
	RENAME i_is_rec = predicted_val
			P_0 = prob_0
			P_1 = prob_1;
	DROP SelectionProb SamplingWeight f_is_rec;
RUN;

/* 89.28% */
PROC FREQ DATA = g1_results_data;
	TABLE is_rec * predicted_val / nocol norow;
RUN;


/* train-test split - hbp */
PROC SORT DATA = group_two OUT = group_two_sorted;
	BY ethnicity;
RUN;

PROC SURVEYSELECT DATA = group_two_sorted 
					RATE = 0.7 OUT = group_two_split 
					SEED = 123 OUTALL;
	STRATA ethnicity;
RUN;

PROC FREQ DATA = group_two_split; 
	TABLE ethnicity * selected;
RUN;

DATA g2_train g2_test; 
	SET group_two_split; 
	IF selected = 1 THEN OUTPUT g2_train; 
	ELSE OUTPUT g2_test; 
	DROP selected;
RUN;


PROC LOGISTIC DATA = g2_train;
        CLASS ethnicity (REF = "Other")
        		has_hype_med_char (REF = "0") 
                is_diabetic_char (REF = "0")
                does_smoke_char (REF = "0") / PARAM = REFERENCE;
        MODEL is_rec (EVENT = "1") = 
        		age ethnicity sbp high_chol total_chol 
        		has_hype_med_char is_diabetic_char 
        		does_smoke_char / EXPB;
        SCORE DATA = g2_test OUT = g2_results;
RUN;

DATA g2_results_data;
	SET g2_results;
	RENAME i_is_rec = predicted_val
			P_0 = prob_0
			P_1 = prob_1;
	DROP SelectionProb SamplingWeight f_is_rec;
RUN;

/* 88.09% */
PROC FREQ DATA = g2_results_data;
	TABLE is_rec * predicted_val / nocol norow;
RUN;
