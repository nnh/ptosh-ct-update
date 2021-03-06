**************************************************************************
Program Name : PTOSH_CT_UPDATE_CODELIST_CHANGE.sas
Author : Ohtsuka Mariko
Date : 2021-8-27
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

%EDIT_OUTPUT_DS(codelist_change);
%EDIT_OUTPUT_DS(code_only_change);
%EDIT_OUTPUT_DS(del);
%EDIT_OUTPUT_DS(add);

%GET_USED1_USED2(codelist_change);
%GET_USED1_USED2(del);
* add;
%GET_ADD_UNMATCH_COUNT(unmatch);
%GET_ADD_UNMATCH_COUNT(add);
proc sql noprint;
    create table add_add_unmatch as
    select a.*, b.unmatch_count
    from temp_add_add a inner join temp_add_unmatch b on a.CodelistId = b.CodelistId;
quit;
data temp_add_1;
    set add;
run;
proc sql noprint;
    create table temp_add_2 as
    select *
    from temp_add_1
    where CodelistId in (select CodelistId from add_add_unmatch)
    order by CodelistId, flag, Code, CDISC_Submission_Value;
quit;
proc sql noprint;
    create table add as
    select distinct a.CodelistId, a.Codelist_Code, a.Codelist_Name, a.Datatype, a.SASFormatName, a.Code,
           a.Ordernum, a.Rank, a.Codelist_Extensible__Yes_No_, a.CDISC_Submission_Value, 
           a.Translated, a.lang, a.CTDef, a.CTListDef, 
           case 
             when (a.Code = '') & (a.flag = 'unmatch') then b.terms_label
             else a.NCI_Preferred_Term 
           end as NCI_Preferred_Term,
           a.used1_flg, a.used2_flg, a.flag
    from temp_add_2 a left join used b on (a.CodelistId = b.cdisc_name) and (a.CDISC_Submission_Value = b.terms_submission_value)
    order by CodelistId, flag, Code, CDISC_Submission_Value;
quit;
%ds2csv (data=codelist_change, runmode=b, csvfile=&outputpath.\codelist_change.csv, labels=Y);
%ds2csv (data=code_only_change, runmode=b, csvfile=&outputpath.\code_only_change.csv, labels=Y);
%ds2csv (data=del, runmode=b, csvfile=&outputpath.\code_del.csv, labels=Y);
%ds2csv (data=add, runmode=b, csvfile=&outputpath.\code_add.csv, labels=Y);
