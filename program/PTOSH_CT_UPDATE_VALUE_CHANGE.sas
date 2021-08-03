**************************************************************************
Program Name : PTOSH_CT_UPDATE_VALUE_CHANGE.sas
Author : Ohtsuka Mariko
Date : 2021-8-3
SAS version : 9.4
**************************************************************************;
proc datasets library=work kill nolist; quit;
options mprint mlogic symbolgen noquotelenmax;
%macro GET_THISFILE_FULLPATH;
    %local _fullpath _path;
    %let _fullpath=;
    %let _path=;

    %if %length(%sysfunc(getoption(sysin)))=0 %then
      %let _fullpath=%sysget(sas_execfilepath);
    %else
      %let _fullpath=%sysfunc(getoption(sysin));
    &_fullpath.
%mend GET_THISFILE_FULLPATH;
%macro GET_DIRECTORY_PATH(input_path, directory_level);
    %let input_path_len=%length(&input_path.);
    %let temp_path=&input_path.;

    %do i = 1 %to &directory_level.;
      %let temp_len=%scan(&temp_path., -1, '\');
      %let temp_path=%substr(&temp_path., 1, %length(&temp_path.)-%length(&temp_len.)-1);
      %put &temp_path.;
    %end;
    %let _path=&temp_path.;
    &_path.
%mend GET_DIRECTORY_PATH;
%let thisfile=%GET_THISFILE_FULLPATH;
%let projectpath=%GET_DIRECTORY_PATH(&thisfile., 2);
%inc "&projectpath.\program\macro\PTOSH_CT_UPDATE_LIBNAME.sas";
* Main processing start;
%EXEC_VALUE_ONLY_CHANGE(ds_submission_value_change, CDISC_Submission_Value, 8);
%GET_USED1_USED2(ds_submission_value_change);
%EXEC_VALUE_ONLY_CHANGE(ds_nci_change, NCI_Preferred_Term, 10);
%ds2csv (data=ds_submission_value_change, runmode=b, csvfile=&outputpath.\Submission Value_change.csv, labels=Y);
%ds2csv (data=ds_nci_change, runmode=b, csvfile=&outputpath.\NCI Preferred Term_change.csv, labels=Y);
