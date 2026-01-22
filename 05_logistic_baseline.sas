/*--------------------------------------------------------------
  Purpose:
    - Baseline PD model using Logistic Regression
    - Produce bank-friendly model diagnostics:
        * AUC (ROC)
        * KS statistic
        * Confusion matrix at a chosen cutoff
        * Decile table + lift
  Input:  work.train, work.test
  Output: work.scored_test, work.roc_test, work.decile_table
--------------------------------------------------------------*/

%let target = default;
%let seed   = 42;

/* PD probability variable (PROC LOGISTIC output naming can vary)
   We'll explicitly output it as PD in the SCORE step */
%let pdvar = PD;

/* ----------------------------
   1) Train logistic regression
-----------------------------*/
ods exclude all;

ods output Association        = work.auc_train
           ParameterEstimates = work.params_logit;

proc logistic data=work.train descending;
  class
    home_ownership_c
    verification_status_c
    purpose_c
    emp_length_grp
    grade_c
    sub_grade_c
    application_type_c
    addr_state_c
    / param=glm;

  model &target(event='1') =
    loan_amnt_cap term_m int_rate_num installment dti_clean2
    log_inc fico_mid2
    revol_bal_cap revol_util_clean2
    open_acc_cap total_acc_cap
    dti_miss_flag inc_miss_flag revutil_miss_flag fico_miss_flag
    home_ownership_c verification_status_c purpose_c emp_length_grp
    grade_c sub_grade_c application_type_c addr_state_c;

  /* Score TEST set and save PD explicitly */
  score data=work.test out=work.scored_test outroc=work.roc_test;
run;

ods exclude none;

/* ----------------------------
   2) AUC (ROC)
-----------------------------*/
title "AUC (Train) - Association Table";
proc print data=work.auc_train noobs; run;
title;

/* ----------------------------
   3) KS Statistic from ROC table
   KS = max(Sensitivity - (1 - Specificity))
-----------------------------*/
data work.ks_calc;
  set work.roc_test;
  ks = _sensit_ - _1mspec_;
run;

title "KS Statistic (Test)";
proc sql;
  select max(ks) as KS format=8.4 from work.ks_calc;
quit;
title;

/* ----------------------------
   4) Create a clean PD variable
   PROC LOGISTIC score outputs probabilities as:
     P_0 and P_1 (prob of each class)
   We'll standardise to PD = P_1
-----------------------------*/
data work.scored_test2;
  set work.scored_test;
  PD = P_1;
  if missing(PD) then delete;
run;

/* ----------------------------
   5) Confusion matrix at cutoff
   Pick a simple cutoff (example 0.20 = overall bad rate).
   Banks often compare multiple cutoffs later.
-----------------------------*/
%let cutoff = 0.20;

data work.conf;
  set work.scored_test2;
  pred = (PD >= &cutoff);
run;

title "Confusion Matrix (Test) at Cutoff=&cutoff";
proc freq data=work.conf;
  tables default*pred / norow nocol nopercent;
run;
title;

/* ----------------------------
   6) Decile table + lift
-----------------------------*/
proc rank data=work.scored_test2 out=work.test_rank groups=10 descending;
  var PD;
  ranks decile;
run;

data work.test_rank;
  set work.test_rank;
  decile = decile + 1;
run;

proc sql;
  create table work.decile_table as
  select
    decile,
    count(*) as n,
    sum(default) as bads,
    mean(default) as bad_rate format=percent8.2,
    mean(PD) as avg_pd format=8.4
  from work.test_rank
  group by decile
  order by decile;
quit;

proc sql noprint;
  select sum(bads) into :total_bads from work.decile_table;
  select sum(n)    into :total_n    from work.decile_table;
quit;

data work.decile_table2;
  set work.decile_table;
  retain cum_bads 0 cum_n 0;
  cum_bads + bads;
  cum_n + n;

  pct_bads_captured = cum_bads / &total_bads;
  pop_pct           = cum_n / &total_n;

  overall_bad_rate = &total_bads / &total_n;
  lift = bad_rate / overall_bad_rate;

  format pct_bads_captured pop_pct percent8.2 lift 8.3 overall_bad_rate percent8.2;
run;

title "Decile Table (Test) with Lift + Cumulative Bad Capture";
proc print data=work.decile_table2 noobs; run;
title;
