**************************************************************************
Program Name : PTOSH_CT_UPDATE_LIBNAME.sas
Author : Ohtsuka Mariko
Date : 2020-3-11
SAS version : 9.4
**************************************************************************;
%macro IMPORT_BEF_AFT();
    proc import datafile="&inputpath.\&before_file_name."
        out=raw_before
        dbms=csv replace;
        guessingrows=MAX;
    run;
    proc import datafile="&inputpath.\&after_file_name."
        out=raw_after
        dbms=csv replace;
        guessingrows=MAX;
    run;
%mend IMPORT_BEF_AFT;
%macro EDIT_OUTPUT_COLS(input_ds, output_ds);
    data &output_ds.;
        format Codelist_Name CodelistId Codelist_Code Code CDISC_Submission_Value NCI_Preferred_Term;
        set &input_ds.;
        temp='';
        label Codelist_Name='ct.name' CodelistId='ct.submission_value' Codelist_Code='ct.code'
              Code='t.code' CDISC_Submission_Value='t.submission_value' NCI_Preferred_Term='t.label';
        keep Codelist_Name CodelistId Codelist_Code Code CDISC_Submission_Value NCI_Preferred_Term;
    run;
%mend EDIT_OUTPUT_COLS;
%macro MERGE_BEF_AFT(input_1, input_2, output, by_var);
    data &output.;
        length CodelistId $200 Codelist_Code $200 Codelist_Name $200 Datatype $200 SASFormatName $200 
               Code $200 Ordernum $200 Rank $200 Codelist_Extensible__Yes_No_ $200 
               CDISC_Submission_Value $200 Translated $1000 lang $200 CTDef $2000 CTListDef $1000 
               NCI_Preferred_Term $1000;
        merge &input_1. &input_2.(in=temp);
        by &by_var.;
        if temp^=1 then output;
    run;
%mend MERGE_BEF_AFT;
%macro EXEC_1A();
    proc sort data=raw_before out=before;
        by Codelist_Code Code;
    run;
    proc sort data=raw_after out=after;
        by Codelist_Code Code;
    run;
    %MERGE_BEF_AFT(after, before, merge_before_after, Codelist_Code)
    %EDIT_OUTPUT_COLS(merge_before_after, ds_1a);
%mend EXEC_1A;
%let inputpath=&projectpath.\input\rawdata;
%let extpath=&projectpath.\input\ext;
%let outputpath=&projectpath.\output;
%let before_file_name=SDTM Terminology 2017-12-22.csv;
%let after_file_name=SDTM Terminology 2020-11-06.csv;
%IMPORT_BEF_AFT;
