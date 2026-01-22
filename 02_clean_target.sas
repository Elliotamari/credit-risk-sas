/* 02_clean_target.sas
   Target engineering and base numeric sanitisation
   Output: WORK.LC_MODEL_BASE
*/

%include "&project./00_setup.sas";

data work.lc_model_base;
  set work.lc_raw;

  length loan_status_clean $60;
  loan_status_clean = strip(loan_status);

  /* Normalise rare label */
  if loan_status_clean = "Default" then loan_status_clean = "Charged Off";

  /* Target: 1 = bad, 0 = good */
  if loan_status_clean in (
        "Charged Off",
        "Does not meet the credit policy. Status:Charged Off"
     ) then default = 1;
  else if loan_status_clean in (
        "Fully Paid",
        "Does not meet the credit policy. Status:Fully Paid"
     ) then default = 0;
  else default = .;

  /* Keep only final outcomes */
  if default in (0,1);

  /* DTI cleaning */
  dti_clean = dti;
  if dti_clean = 999 then dti_clean = .;
  if dti_clean ne . and dti_clean > 60 then dti_clean = 60;

  /* Income cleaning + log */
  annual_inc_clean = annual_inc;
  if annual_inc_clean ne . and annual_inc_clean > 500000 then annual_inc_clean = 500000;

  if annual_inc_clean > 0 then log_annual_inc = log(annual_inc_clean);
  else log_annual_inc = .;

  /* Revol utilisation cap */
  revol_util_clean = revol_util;
  if revol_util_clean ne . and revol_util_clean > 100 then revol_util_clean = 100;

  /* FICO mid */
  fico_mid = mean(fico_range_low, fico_range_high);

  /* Drop obvious leakage or heavy text */
  drop id member_id url desc title;

run;

/* Target distribution check */
proc freq data=work.lc_model_base;
  tables loan_status_clean*default / missing;
run;

/* Numeric sanity check */
proc means data=work.lc_model_base n nmiss mean min p50 max;
  var annual_inc annual_inc_clean log_annual_inc
      dti dti_clean
      revol_util revol_util_clean
      fico_range_low fico_range_high fico_mid
      int_rate loan_amnt;
run;
