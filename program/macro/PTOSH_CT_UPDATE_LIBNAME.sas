**************************************************************************
Program Name : PTOSH_CT_UPDATE_LIBNAME.sas
Author : Ohtsuka Mariko
Date : 2020-5-19
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
%macro EXEC_UNMATCHED();
    data wk_before;
        set raw_before;
        Codelist_Code_Code=cats(Codelist_code, Code);
    run;
    data wk_after;
        set raw_after;
        Codelist_Code_Code=cats(Codelist_code, Code);
    run;
    proc sql noprint;
        create table match_codelist_code as
        select a.Codelist_Code_Code
        from wk_before a, wk_after b
        where a.Codelist_Code_Code = b.Codelist_Code_Code;
    
        create table unmatch_codelist_or_code_before as
        select *
        from wk_before
        where Codelist_Code_Code not in (select Codelist_Code_Code from match_codelist_code)
        order by Codelist_Code_Code;    

        create table unmatch_codelist_or_code_after as
        select *
        from wk_after
        where Codelist_Code_Code not in (select Codelist_Code_Code from match_codelist_code)
        order by Codelist_Code_Code;    
    quit;
%mend EXEC_UNMATCHED;
%macro IMPORT_USED();
    proc import datafile="&inputpath.\used.csv"
        out=used
        dbms=csv replace;
        guessingrows=MAX;
        getnames=no;
    run;
%mend IMPORT_USED;
%macro MATCH_USED(input_ds, output_ds);
    proc sql noprint;
        create table &output_ds. as
        select a.*, b.var1 as used_Codelist_Id, b.var4 as used_Submission_Value
        from &input_ds. a left join used b on (a.CodelistId = b.var1) and (a.CDISC_Submission_Value = b.var4);
    quit;
%mend MATCH_USED;
%macro EXEC_CODELIST_CHANGE();
    %EXEC_UNMATCHED;
    proc sql noprint;
        create table change_bef as
        select distinct a.*, 1 as seq
        from Unmatch_codelist_or_code_before a, Unmatch_codelist_or_code_after b
        where (a.Codelist_Code ^= b.Codelist_Code) and
              (a.Code = b.Code)
        order by a.Code, a.Codelist_Code;
    quit;
    * set used flag;
    %MATCH_USED(change_bef, change_bef_used);
    proc sql noprint;
        create table change_aft as
        select distinct a.*, 2 as seq
        from Unmatch_codelist_or_code_after a, Unmatch_codelist_or_code_before b
        where (a.Codelist_Code ^= b.Codelist_Code) and
              (a.Code = b.Code)
        order by a.Code, a.Codelist_Code;
    quit;
    * set used flag;
    proc sql noprint;
        create table change_bef_used_ari as
        select *
        from change_bef_used
        where used_Submission_Value ^= '';

        create table change_aft_used_ari as
        select distinct a.*, '' as used_Codelist_Id, 'used_ari' as used_Submission_Value
        from change_aft a, change_bef_used_ari b 
        where a.Code = b.Code;

        create table change_aft_used_nashi as
        select distinct a.*, '' as used_Codelist_Id, '' as used_Submission_Value
        from change_aft a
        where a.Code not in (select Code from change_aft_used_ari);

        create table change_aft_used as
        select * from change_aft_used_ari
        outer union corr
        select * from change_aft_used_nashi;
    quit;
    proc sql noprint;
        create table temp_codelist_change as
        select * from change_bef_used
        outer union corr
        select * from change_aft_used;
    quit;
    proc sql noprint;
        create table codelist_change as
        select distinct *
        from temp_codelist_change
        order by Code, CDISC_Submission_Value, seq, Codelist_Code;
    quit;
%mend EXEC_CODELIST_CHANGE;
%macro EDIT_OUTPUT_DS(target_ds);
    data temp_ds;
        set &target_ds.;
    run;
    data &target_ds.;
        set temp_ds;
        if seq=0 then do;
          flag='aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';  * Dummy for length setting;
        end;
        else if seq=1 then do;
          flag='change_before';
        end;
        else if seq=2 then do;
          flag='change_after';
        end;
        else if seq=3 then do;
          flag='del';
        end;
        else if seq=4 then do;
          flag='add';
        end;
        else if seq=5 then do;
          flag='change_code_only_before';
        end;
        else if seq=6 then do;
          flag='change_code_only_after';
        end;
        if used_Submission_Value^='' then do;
          used=1;
        end;
        else do;
          used=.;
        end;
        drop Codelist_Code_Code seq used_Codelist_Id used_Submission_Value;
    run;
%mend EDIT_OUTPUT_DS;
%macro EXEC_ADD_DEL(target_1, target_2, output_ds, seq);
    proc sql noprint;
        create table temp_add_del_1 as
        select *, &seq. as seq
        from &target_1.
        where Codelist_Code_Code not in (select Codelist_Code_Code from &target_2.);
    quit;
    proc sql noprint;
        create table temp_add_del_2_1 as
        select *
        from temp_add_del_1
        where Codelist_Code_Code not in (select Codelist_Code_Code from codelist_change);
    quit;
    proc sql noprint;
        create table temp_add_del_2_2 as
        select *
        from temp_add_del_2_1
        where Codelist_Code_Code not in (select Codelist_Code_Code from code_only_change);
    quit;
    * set used flag;
    %MATCH_USED(temp_add_del_2_2, temp_add_del_3);
    proc sql noprint;
        create table &output_ds. as
        select distinct *
        from temp_add_del_3
        order by Codelist_Code, Code;
    quit;
%mend EXEC_ADD_DEL;
%macro EXEC_CODE_ONLY_CHANGE();
    %MATCH_USED(wk_before, code_only_change_before);
    proc sql noprint;
        create table temp_code_only_change as
        select a.Codelist_code, a.CodelistId as before_CodelistId, b.CodelistId as after_CodelistId, 
               a.CDISC_Submission_Value, a.Code as before_Code, b.Code as after_Code,
               a.Codelist_Code_Code as before_Codelist_Code_Code, b.Codelist_Code_Code as after_Codelist_Code_Code,
               a.used_Submission_Value
        from code_only_change_before a, wk_after b
        where (a.Codelist_code = b.Codelist_code) and
              (strip(a.CDISC_Submission_Value) = strip(b.CDISC_Submission_Value)) and
              (a.Code ^= b.Code);
    quit;
    proc sql noprint;
        create table code_only_change as
        select a.*, 5 as seq, b.used_Submission_Value, '' as used_Codelist_Id
        from wk_before a, temp_code_only_change b
        where a.Codelist_code_Code = b.before_Codelist_Code_Code
        union
        select a.*, 6 as seq, b.used_Submission_Value, '' as used_Codelist_Id
        from wk_after a, temp_code_only_change b
        where a.Codelist_code_Code = b.after_Codelist_Code_Code
        order by Codelist_Code, CDISC_Submission_Value, Seq;
    quit;
%mend EXEC_CODE_ONLY_CHANGE;
%let inputpath=&projectpath.\input\rawdata;
%let extpath=&projectpath.\input\ext;
%let outputpath=&projectpath.\output;
%let before_file_name=SDTM Terminology 2017-12-22.csv;
%let after_file_name=SDTM Terminology 2020-11-06.csv;
%IMPORT_BEF_AFT;
%IMPORT_USED;
