/*******************************************************/
/*****/
/*****	DATA PULL */
/*****/
/********************************************************/

/* pull nhanes transport data files */
FILENAME nh_demo url "https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/P_DEMO.XPT";
FILENAME nh_tChol url "https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/P_TCHOL.XPT";
FILENAME nh_hChol url "https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/P_HDL.XPT";
FILENAME nh_lChol url "https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/P_TRIGLY.XPT";
FILENAME nh_diab url "https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/P_DIQ.XPT";
FILENAME nh_smoke url "https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/P_SMQ.XPT";
FILENAME nh_bPres url "https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/P_BPQ.XPT";
FILENAME nh_bmi url "https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/P_BMX.XPT";
FILENAME nh_creat url "https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/P_BIOPRO.XPT";
FILENAME nh_blood url "https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/P_BPXO.XPT";

LIBNAME nh_demo xport;
LIBNAME nh_tChol xport;
LIBNAME nh_hChol xport;
LIBNAME nh_lChol xport;
LIBNAME nh_diab xport;
LIBNAME nh_smoke xport;
LIBNAME nh_bPres xport;
LIBNAME nh_bmi xport;
LIBNAME nh_creat xport;
LIBNAME nh_blood xport;


/* data file location */
LIBNAME nh_data "/home/u63563888/schiltz24/nhanes/nhanesData/2017_raw";

PROC COPY inlib = nh_demo out = nh_data; RUN;
PROC COPY inlib = nh_tChol out = nh_data; RUN;
PROC COPY inlib = nh_hChol out = nh_data; RUN;
PROC COPY inlib = nh_lChol out = nh_data; RUN;
PROC COPY inlib = nh_diab out = nh_data; RUN;
PROC COPY inlib = nh_smoke out = nh_data; RUN;
PROC COPY inlib = nh_bPres out = nh_data; RUN;
PROC COPY inlib = nh_bmi out = nh_data; RUN;
PROC COPY inlib = nh_creat out = nh_data; RUN;
PROC COPY inlib = nh_blood out = nh_data; RUN;


/*******************************************************/
/*****/
/*****	DATA MERGE */
/*****/
/********************************************************/

/* set library */
LIBNAME nhanes "/home/u63563888/schiltz24/nhanes/nhanesData/2017_raw";

/* create datasets */
DATA blood_pressure;
    SET nhanes.p_bpq;
    KEEP SEQN BPQ040A BPQ090D BPQ100D BPD035;
RUN;

DATA demographics;
    SET nhanes.p_demo;
    KEEP SEQN RIDAGEYR RIAGENDR RIDRETH3;
RUN;

DATA diabetes;
    SET nhanes.p_diq;
    KEEP SEQN DIQ010;
RUN;

DATA high_chol;
    SET nhanes.p_hdl;
    KEEP SEQN LBDHDD;
RUN;

DATA low_chol;
    SET nhanes.p_trigly;
    KEEP SEQN LBDLDLN;
RUN;

DATA smoking;
    SET nhanes.p_smq;
    KEEP SEQN SMQ040 SMQ020;
RUN;

DATA total_chol;
    SET nhanes.p_tchol;
    KEEP SEQN LBXTC;
RUN;

DATA bmi;
    SET nhanes.p_bmx;
    KEEP SEQN BMXBMI;
RUN;

DATA creatinine;
   SET nhanes.p_biopro;
   KEEP SEQN LBXSCR;
RUN;

DATA blood_measures;
   SET nhanes.p_bpxo;
   KEEP SEQN BPXOSY1 BPXOSY2 BPXOSY3
   		BPXODI1 BPXODI2 BPXODI3;
RUN;


/* merge datasets */
DATA merged_nhanes;
	MERGE blood_pressure demographics diabetes 
			high_chol low_chol smoking total_chol
			bmi creatinine blood_measures;
	BY SEQN;
RUN;


/* export merged dataset */
LIBNAME exp_path "/home/u63563888/schiltz24/nhanes/nhanesData/year_merged";

DATA exp_path.nhanes_data_17;
	SET merged_nhanes;
RUN;


/*******************************************************/
/*****/
/*****	DATA CLEANING */
/*****/
/********************************************************/

/* get data */
LIBNAME nh_path "/home/u63563888/schiltz24/nhanes/nhanesData/year_merged";


/* clean data */
DATA nhanes;
    SET nh_path.nhanes_data_17;
    
    WHERE RIDAGEYR BETWEEN 40 AND 79;
    
    /* include those who were never told they had hypertension */
   	IF BPD035 >= 13 AND BPD035 <=80 THEN DO;
   		IF BPQ040A = 1 THEN has_hype_med = 1;
   		ELSE IF BPQ040A = 2 THEN has_hype_med = 0;
   		ELSE has_hype_med = .;
   	END;
   	ELSE IF BPD035 = . THEN has_hype_med = 0;
   	ELSE has_hype_med = .;
    
    LENGTH sex $ 7;
	IF RIAGENDR = 1 THEN DO;
		sex = "Male";
		eGFR = 142 * 
				MIN(LBXSCR/0.9, 1)**-0.302 * 
				MAX(LBXSCR/0.9, 1)**-1.2 * 
				0.9938**RIDAGEYR;
	END;
	ELSE IF RIAGENDR = 2 THEN DO;
		sex = "Female";
		eGFR = 142 * 
				MIN(LBXSCR/0.7, 1)**(-0.241) *
				MAX(LBXSCR/0.7, 1)**(-1.2) * 
				0.9938**RIDAGEYR *
				1.012;	
	END;
	ELSE sex = "";
	
	LENGTH ethnicity $ 18;
	IF RIDRETH3 = 1 THEN ethnicity = "Mexican American";
	ELSE IF RIDRETH3 = 2 THEN ethnicity = "Other Hispanic";
	ELSE IF RIDRETH3 = 3 THEN ethnicity = "Non-Hispanic White";
	ELSE IF RIDRETH3 = 4 THEN ethnicity = "Non-Hispanic Black";
	ELSE IF RIDRETH3 = 6 THEN ethnicity = "Non-Hispanic Asian";
	ELSE IF RIDRETH3 = 7 THEN ethnicity = "Other Race";
	ELSE ethnicity = "";
	
	IF DIQ010 = 1 THEN is_diabetic = 1;
	ELSE IF DIQ010 = 2 OR DIQ010 = 3 THEN is_diabetic = 0;
	ELSE is_diabetic = .;
	
	/* originally only used question for those who smoked 100+ */
	IF SMQ020 = 1 THEN DO;
		IF SMQ040 = 1 OR SMQ040 = 2 THEN does_smoke = 1;
		ELSE IF SMQ040 = 3 THEN does_smoke = 0;
		ELSE does_smoke = .;
	END;
	ELSE IF SMQ020 = 2 THEN does_smoke = 0;
	ELSE does_smoke = .;
	
	/* systolic/diastolic blood pressure readings */
	sbp = MEAN(BPXOSY1, BPXOSY2, BPXOSY3);
	dbp = MEAN(BPXODI1, BPXODI2, BPXODI3);

	/* binary - has high blood pressure */
	IF sbp >= 130 AND sbp <= 139 OR 
		dbp >= 80 AND dbp <= 89
		THEN has_hbp = 1;
	ELSE has_hbp = 0; 
	
	/* statin medication */
	IF BPQ090D = 1 THEN DO;
		IF BPQ100D = 1 THEN is_taking_statin = 1;
		ELSE IF BPQ100D = 2 THEN is_taking_statin = 0;
		ELSE is_taking_statin = .;
	END;
	ELSE IF BPQ090D = 2 THEN is_taking_statin = 0;
	ELSE is_taking_statin = .;
	
	RENAME RIDAGEYR = age;
	RENAME LBDHDD = high_chol;
	RENAME LBDLDLN = low_chol;
	RENAME LBXTC = total_chol;
	
	DROP BPQ040A RIAGENDR RIDRETH3 DIQ010 
			BPD035 SMQ020 SMQ040
			BPXOSY1 BPXOSY2 BPXOSY3
			BPXODI1 BPXODI2 BPXODI3;
	
	/* PREVENT calculator variables */
	/* BMI - creatinine - statin med - eGFR */
	DROP BMXBMI LBXSCR BPQ090D BPQ100D eGFR is_taking_statin;
RUN;


/* get complete cases - except LDL  */
DATA comp_nhanes;
	SET nhanes;

	IF (CMISS(of _ALL_) = 0) OR 
		(CMISS(of _ALL_) = 1 AND low_chol = .);
RUN;


/* export cleaned dataset */
LIBNAME exp_path "/home/u63563888/schiltz24/nhanes/nhanesData/cleaned";

DATA exp_path.nhanes_cleaned_17;
	SET comp_nhanes;
RUN;
