**************************************************************************
Program Name : PTOSH_CT_UPDATE_CODE_CHANGE.sas
Author : Ohtsuka Mariko
Date : 2021-5-18
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

%MATCH_USED(raw_before, used_before);
%MATCH_USED(raw_after, used_after);
proc sql noprint;
    create table code_only_change as
    select a.Codelist_code, a.CodelistId as before_CodelistId, b.CodelistId as after_CodelistId, 
           a.CDISC_Submission_Value, a.Code as before_Code, b.Code as after_Code, 
           case 
             when a.used_Submission_Value ^= '' then 1
             else .
           end as before_used,
           case 
             when b.used_Submission_Value ^= '' then 1
             else .
           end as after_used
    from used_before a, used_after b
    where (a.Codelist_code = b.Codelist_code) and
          (strip(a.CDISC_Submission_Value) = strip(b.CDISC_Submission_Value)) and
          (a.Code ^= b.Code)
    order by Codelist_code, before_code, after_code;
quit;
%ds2csv (data=code_only_change, runmode=b, csvfile=&outputpath.\code_only_change.csv, labels=Y);
