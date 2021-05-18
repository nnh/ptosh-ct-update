**************************************************************************
Program Name : PTOSH_CT_UPDATE_CODELIST_CHANGE.sas
Author : Ohtsuka Mariko
Date : 2021-5-11
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
%EXEC_CODELIST_CHANGE;
%EXEC_CODE_ONLY_CHANGE;
%EXEC_ADD_DEL(wk_before, wk_after, del, 3);
%EXEC_ADD_DEL(wk_after, wk_before, add, 4);
*%ds2csv (data=codelist_change, runmode=b, csvfile=&outputpath.\codelist_change.csv, labels=Y);
%ds2csv (data=code_only_change, runmode=b, csvfile=&outputpath.\code_only_change.csv, labels=Y);
*%ds2csv (data=add, runmode=b, csvfile=&outputpath.\code_add.csv, labels=Y);
*%ds2csv (data=del, runmode=b, csvfile=&outputpath.\code_del.csv, labels=Y);
