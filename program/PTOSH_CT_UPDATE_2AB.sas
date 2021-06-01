**************************************************************************
Program Name : PTOSH_CT_UPDATE_2AB.sas
Author : Ohtsuka Mariko
Date : 2021-6-1
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
%MATCH_USED(raw_before, before);
proc sql noprint;
    create table ds_2ab as
    select *, . as Codelist_Code_Code, . as seq
    from before
    where Code not in (select Code from raw_after)
    order by Code, Codelist_Code;
quit;
%EDIT_OUTPUT_DS(ds_2ab);
%ds2csv (data=ds_2ab, runmode=b, csvfile=&outputpath.\2ab.csv, labels=Y);
