/*--------------------------------------------------------------
  03_feature_engineering.sas
  Purpose:
    - Create modelling-ready features from lc_model_base
    - Consistent naming: *_num, *_clean, *_flag
    - Add missing indicators (bank-friendly)
    - Keep a curated feature set (no leakage)
  Input:  work.lc_model_base
  Output: work.lc_model (final modelling dataset)
--------------------------------------------------------------*/

%let IN  = work.lc_model_base;
%let OUT = work.lc_model;

/*---------------------------
  1) Feature Engineering
---------------------------*/
data &OUT;
  set &IN;

  /* ---------- Numeric: term (months) ---------- */
  /* term is usually like: " 36 months" -> 36 */
  term_m = input(compress(term,,'kd'), best.);
  if term_m not in (36,60) then term_m = .;

  /* ---------- Numeric: interest rate ---------- */
  /* In some LC exports, int_rate is like "13.56%". In yours it's numeric already.
     This keeps the code robust either way. */
  length int_rate_num 8;
  if vtype(int_rate)='C' then int_rate_num = input(compress(int_rate,,'kd'), best.)/100;
  else int_rate_num = int_rate/100; /* convert to proportion if numeric percent */
  /* If your int_rate is already a percent (e.g., 12.38), int_rate_num becomes 0.1238 */

  /* ---------- DTI (already cleaned in 02, but we keep consistent rules here) ---------- */
  dti_clean2 = dti_clean;
  if dti_clean2 ne . and dti_clean2 > 60 then dti_clean2 = 60;
  dti_miss_flag = missing(dti_clean2);

  /* ---------- Income (already cleaned in 02) ---------- */
  annual_inc_clean2 = annual_inc_clean;
  inc_miss_flag = missing(annual_inc_clean2);

  /* Stable log income */
  if annual_inc_clean2 > 0 then log_inc = log(annual_inc_clean2);
  else log_inc = .;

  /* ---------- Revol util (already cleaned in 02) ---------- */
  revol_util_clean2 = revol_util_clean;
  revutil_miss_flag = missing(revol_util_clean2);

  /* ---------- FICO ---------- */
  fico_mid2 = fico_mid;
  fico_miss_flag = missing(fico_mid2);

  /* ---------- Caps for a few common numeric risk drivers ---------- */
  /* Keep rules simple and documented (banks love this) */
  loan_amnt_cap = loan_amnt;
  if loan_amnt_cap ne . and loan_amnt_cap > 40000 then loan_amnt_cap = 40000;

  revol_bal_cap = revol_bal;
  if revol_bal_cap ne . and revol_bal_cap > 200000 then revol_bal_cap = 200000;

  open_acc_cap = open_acc;
  if open_acc_cap ne . and open_acc_cap > 60 then open_acc_cap = 60;

  total_acc_cap = total_acc;
  if total_acc_cap ne . and total_acc_cap > 150 then total_acc_cap = 150;

  /* ---------- Categorical normalisation (trim + standardise blanks) ---------- */
  length home_ownership_c verification_status_c purpose_c emp_length_c
         grade_c sub_grade_c application_type_c addr_state_c $40;

  home_ownership_c      = upcase(strip(home_ownership));
  verification_status_c = upcase(strip(verification_status));
  purpose_c             = upcase(strip(purpose));
  emp_length_c          = upcase(strip(emp_length));
  grade_c               = upcase(strip(grade));
  sub_grade_c           = upcase(strip(sub_grade));
  application_type_c    = upcase(strip(application_type));
  addr_state_c          = upcase(strip(addr_state));

  /* Replace empty strings with "UNKNOWN" */
  array catvars{8} $ home_ownership_c verification_status_c purpose_c emp_length_c
                     grade_c sub_grade_c application_type_c addr_state_c;
  do i=1 to dim(catvars);
    if catvars{i} = "" then catvars{i} = "UNKNOWN";
  end;
  drop i;

  /* OPTIONAL: group rare emp_length categories (simplify scorecard) */
  /* Typical LC values: "< 1 year", "10+ years", "n/a", etc. */
  length emp_length_grp $20;
  if emp_length_c in ("N/A","UNKNOWN") then emp_length_grp = "UNKNOWN";
  else if index(emp_length_c,"10") then emp_length_grp = "10+";
  else if index(emp_length_c,"9") then emp_length_grp = "9";
  else if index(emp_length_c,"8") then emp_length_grp = "8";
  else if index(emp_length_c,"7") then emp_length_grp = "7";
  else if index(emp_length_c,"6") then emp_length_grp = "6";
  else if index(emp_length_c,"5") then emp_length_grp = "5";
  else if index(emp_length_c,"4") then emp_length_grp = "4";
  else if index(emp_length_c,"3") then emp_length_grp = "3";
  else if index(emp_length_c,"2") then emp_length_grp = "2";
  else if index(emp_length_c,"1") then emp_length_grp = "1";
  else if index(emp_length_c,"<") then emp_length_grp = "<1";
  else emp_length_grp = "OTHER";

  /*---------------------------
    Keep only modelling fields
    (no leakage + neat naming)
  ---------------------------*/
  keep
    default

    /* numeric */
    loan_amnt_cap term_m int_rate_num installment
    dti_clean2 log_inc annual_inc_clean2
    fico_mid2 revol_bal_cap revol_util_clean2
    open_acc_cap total_acc_cap

    /* missing flags */
    dti_miss_flag inc_miss_flag revutil_miss_flag fico_miss_flag

    /* categorical */
    home_ownership_c verification_status_c purpose_c emp_length_grp
    grade_c sub_grade_c application_type_c addr_state_c
  ;
run;

/*---------------------------
  2) Quality checks
---------------------------*/

/* Missing rates */
proc means data=&OUT n nmiss;
  var loan_amnt_cap term_m int_rate_num installment dti_clean2 log_inc annual_inc_clean2
      fico_mid2 revol_bal_cap revol_util_clean2 open_acc_cap total_acc_cap
      dti_miss_flag inc_miss_flag revutil_miss_flag fico_miss_flag;
run;

/* Category distribution */
proc freq data=&OUT;
  tables home_ownership_c verification_status_c purpose_c emp_length_grp
         grade_c sub_grade_c application_type_c addr_state_c / missing;
run;

/* Target rate sanity */
proc freq data=&OUT;
  tables default;
run;
