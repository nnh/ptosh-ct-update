**************************************************************************
Program Name : PTOSH_CT_UPDATE_3A.sas
Author : Ohtsuka Mariko
Date : 2021-3-15
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
%EXEC_1A;
* Main processing start;
proc import datafile="&extpath.\existents.csv"
    out=existents
    dbms=csv replace;
    guessingrows=MAX;
run;
%MERGE_BEF_AFT(after, merge_before_after, merge_before_after_3a, Codelist_Code);
proc sort data=before out=before_3a;
    by Codelist_Code Code;
run;
proc sort data=merge_before_after_3a out=merge_before_after_3a_1;
    by Codelist_Code Code;
run;
%MERGE_BEF_AFT(merge_before_after_3a_1, before_3a, merge_before_after_3a_2, %str(Codelist_Code Code));
%EDIT_OUTPUT_COLS(merge_before_after_3a_2, ds_3a);
%ds2csv (data=ds_3a, runmode=b, csvfile=&outputpath.\3a_0.csv, labels=Y);
proc sql noprint;
    create table ds_3a_existents as
    select a.*
    from ds_3a a, existents b
    where (a.Codelist_Code = b.VAR3) and (a.Code = b.VAR4);
quit;
%ds2csv (data=ds_3a_existents, runmode=b, csvfile=&outputpath.\3a.csv, labels=Y);
