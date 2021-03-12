**************************************************************************
Program Name : PTOSH_CT_UPDATE_3B.sas
Author : Ohtsuka Mariko
Date : 2021-3-11
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
%macro SPLIT_3B(input_ds, header);
    proc sql noprint;
        create table merge_before_after_3b_3_&header. as
        select &header._Codelist_Name as Codelist_Name, &header._CodelistId as CodelistId, 
               &header._Codelist_Code as Codelist_Code, &header._Code as Code,
               &header._CDISC_Submission_Value as CDISC_Submission_Value, 
               &header._NCI_Preferred_Term as NCI_Preferred_Term
        from &input_ds.;
    quit;
    %EDIT_OUTPUT_COLS(merge_before_after_3b_3_&header., ds_3b_&header.);
%mend SPLIT_3B;
%let thisfile=%GET_THISFILE_FULLPATH;
%let projectpath=%GET_DIRECTORY_PATH(&thisfile., 2);
%inc "&projectpath.\program\macro\PTOSH_CT_UPDATE_LIBNAME.sas";
%EXEC_1A;
* Main processing start;
/*2020-12-18CTÇ∆2017-12-22CTÇ…Ç®Ç¢ÇƒCODELIST code + codeÇ™àÍívÇ∑ÇÈÇ‡ÇÃÇ…Ç®Ç¢ÇƒÅASubmission ValueÇ‹ÇΩÇÕNCI Preferred TermÇ™ïœçXÇ≥ÇÍÇΩÇ‡ÇÃÇÃàÍóóíäèoÇàÀóäÇ∑ÇÈ
*/
proc sql noprint;
    create table merge_before_after_3b as
    select a.Codelist_Name as a_Codelist_Name, a.CodelistId as a_CodelistId, 
           a.Codelist_Code as a_Codelist_Code, a.Code as a_Code,
           a.CDISC_Submission_Value as a_CDISC_Submission_Value, 
           a.NCI_Preferred_Term as a_NCI_Preferred_Term,
           b.Codelist_Name as b_Codelist_Name, b.CodelistId as b_CodelistId, 
           b.Codelist_Code as b_Codelist_Code, b.Code as b_Code,
           b.CDISC_Submission_Value as b_CDISC_Submission_Value, 
           b.NCI_Preferred_Term as b_NCI_Preferred_Term
    from before a, after b
    where (a.Codelist_Code = b.Codelist_Code) and
          (a.Code = b.Code);
quit;
data merge_before_after_3b_2;
    set merge_before_after_3b;
    where (a_Codelist_Name^=b_Codelist_Name) or
          (a_CDISC_Submission_Value^=b_CDISC_Submission_Value) or
          (a_NCI_Preferred_Term^=b_NCI_Preferred_Term);
run;
%SPLIT_3B(merge_before_after_3b_2, a);
%SPLIT_3B(merge_before_after_3b_2, b);
%ds2csv (data=ds_3b_a, runmode=b, csvfile=&outputpath.\3b_2017_12_22.csv, labels=Y);
%ds2csv (data=ds_3b_b, runmode=b, csvfile=&outputpath.\3b_2020_11_06.csv, labels=Y);
