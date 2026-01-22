/* 00_setup.sas
   Project setup: paths, options, global macros
*/

%let project=/workspaces/myfolder/credit-risk-sas;
%let raw_file=accepted_2007_to_2018Q4.csv;

options mprint mlogic symbolgen nodate nonumber;
options validvarname=v7;

title; footnote;
