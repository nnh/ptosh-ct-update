**************************************************************************
Program Name : PTOSH_CT_UPDATE_LIBNAME.sas
Author : Ohtsuka Mariko
Date : 2020-8-3
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
        set before_used;
        Codelist_Code_Code=cats(Codelist_code, Code);
    run;
    data wk_after;
        set after_used;
        Codelist_Code_Code=cats(Codelist_code, Code);
    run;
    proc sql noprint;
        * If Codelist_code, code matches, it is not checked.;
        create table match_codelist_code as
        select a.Codelist_Code_Code
        from wk_before a, wk_after b
        where a.Codelist_Code_Code = b.Codelist_Code_Code;
        * Codelist_code or code has changed : before;
        create table unmatch_codelist_or_code_before as
        select *
        from wk_before
        where Codelist_Code_Code not in (select Codelist_Code_Code from match_codelist_code)
        order by Codelist_Code_Code;    
        * Codelist_code or code has changed : after;
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
        getnames=yes;
    run;
%mend IMPORT_USED;
%macro MATCH_USED(input_ds, output_ds);
    proc sql noprint;
        create table &output_ds. as
        select a.*, b.used1_flg, b.used2_flg
        from &input_ds. a left join used b on (a.CodelistId = b.cdisc_name) and (a.CDISC_Submission_Value = b.terms_submission_value);
    quit;
%mend MATCH_USED;
%macro GET_UNMATCH_USED(input_ds, output_ds);
    proc sql noprint;
        create table temp_used as
        select *, cats(cdisc_name, terms_submission_value) as key
        from used;
    quit;
    proc sql noprint;
        create table temp_add_used as
        select a.*
        from temp_used a inner join &input_ds. b on (a.cdisc_name = b.CodelistId) and (a.terms_submission_value = b.CDISC_Submission_Value);
    quit;
    proc sql noprint;
        create table &output_ds. as
        select cdisc_name as CodelistId, cdisc_code as Codelist_Code, name as Codelist_Name,
               terms_code as Code, terms_submission_value as CDISC_Submission_Value, 12 as seq
        from (select * from temp_used where is_master = 'FALSE')
        where key not in (select key from temp_add_used)
        order by cdisc_name, input(terms_seq, best12.), name, terms_submission_value;
    quit;
%mend GET_UNMATCH_USED;
%macro EXEC_CODELIST_CHANGE();
    %EXEC_UNMATCHED;
    * Code is not changed, Codelist_code is changed;
    proc sql noprint;
        create table change_bef as
        select distinct a.*, 1 as seq
        from Unmatch_codelist_or_code_before a, Unmatch_codelist_or_code_after b
        where (a.Codelist_Code ^= b.Codelist_Code) and
              (a.Code = b.Code)
        order by a.Code, a.Codelist_Code;
    quit;
    proc sql noprint;
        create table temp_change_aft as
        select distinct a.*, 2 as seq
        from Unmatch_codelist_or_code_after a, Unmatch_codelist_or_code_before b
        where (a.Codelist_Code ^= b.Codelist_Code) and
              (a.Code = b.Code)
        order by a.Code, a.Codelist_Code;
    quit;
    data change_aft;
        set temp_change_aft;
        drop used1_flg used2_flg;
    run;
    * Set the used_flg of "before" to "after";
    proc sql noprint;
        create table change_aft_used as
        select a.*, b.used1_flg, b.used2_flg
        from change_aft a left join (select code, used1_flg, used2_flg from change_bef) b on a.Code = b.Code;
    quit;
    * Output "before" and "after" in vertical;
    proc sql noprint;
        create table temp_codelist_change as
        select * from change_bef
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
        else if seq=7 then do;
          flag='2ab';
        end;
        else if seq=8 then do;
          flag='submission_value_change_before';
        end;
        else if seq=9 then do;
          flag='submission_value_change_after';
        end;
        else if seq=10 then do;
          flag='NCI_preferred_term_before';
        end;
        else if seq=11 then do;
          flag='NCI_preferred_term_after';
        end;
        else if seq=12 then do;
          flag='unmatch';
        end;
        drop Codelist_Code_Code seq;
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
        create table temp_add_del_2 as
        select *
        from temp_add_del_1
        where Codelist_Code_Code not in (select Codelist_Code_Code from codelist_change);
    quit;
    proc sql noprint;
        create table temp_add_del_3 as
        select *
        from temp_add_del_2
        where Codelist_Code_Code not in (select Codelist_Code_Code from code_only_change);
    quit;
    proc sql noprint;
        create table temp_add_del_4 as 
        select distinct *
        from temp_add_del_3
        order by Codelist_Code, Code;
    quit;
    %GET_UNMATCH_USED(temp_add_del_4, unmatch_used);
    data &output_ds.;
        length CodelistId $200. Codelist_Code $200. Codelist_Name $200. Datatype $200. SASFormatName $200. 
               Code $200. Ordernum $200. Rank $200. Codelist_Extensible__Yes_No_ $200. CDISC_Submission_Value $200.
               Translated $2000. lang $200. CTDef $2000. CTListDef $2000. NCI_Preferred_Term $200. used1_flg $200. 
                used2_flg $200. Codelist_Code_Code $200. seq 8.; 
        set temp_add_del_4 unmatch_used;
        format _ALL_;
    run;
%mend EXEC_ADD_DEL;
%macro EXEC_CODE_ONLY_CHANGE();
    proc sql noprint;
        create table temp_code_only_change as
        select a.Codelist_code, a.CodelistId as before_CodelistId, b.CodelistId as after_CodelistId, 
               a.CDISC_Submission_Value, a.Code as before_Code, b.Code as after_Code,
               a.Codelist_Code_Code as before_Codelist_Code_Code, b.Codelist_Code_Code as after_Codelist_Code_Code,
               a.used1_flg, a.used2_flg
        from wk_before a, wk_after b
        where (a.Codelist_code = b.Codelist_code) and
              (strip(a.CDISC_Submission_Value) = strip(b.CDISC_Submission_Value)) and
              (a.Code ^= b.Code);
    quit;
    data wk_before_1;
        set wk_before;
        drop used1_flg used2_flg;
    run;
    data wk_after_1;
        set wk_after;
        drop used1_flg used2_flg;
    run;
    proc sql noprint;
        create table code_only_change as
        select a.*, 5 as seq, b.used1_flg, b.used2_flg
        from wk_before_1 a, temp_code_only_change b
        where a.Codelist_code_Code = b.before_Codelist_Code_Code
        union
        select a.*, 6 as seq, b.used1_flg, b.used2_flg
        from wk_after_1 a, temp_code_only_change b
        where a.Codelist_code_Code = b.after_Codelist_Code_Code
        order by Codelist_Code, CDISC_Submission_Value, Seq;
    quit;
%mend EXEC_CODE_ONLY_CHANGE;
%macro EXEC_VALUE_ONLY_CHANGE(output_ds_name, target_var, seq);
    %MATCH_USED(raw_before, before);
    proc sql noprint;
        create table after as
        select a.*, b.used1_flg, b.used2_flg
        from raw_after a left join before b on ((a.Codelist_Code = b.Codelist_Code) and (a.Code = b.Code));
    quit;
    proc sql noprint;
        create table ds_codelist_code_code as
        select distinct a.Codelist_Code, a.Code
        from before a, after b
        where (a.Codelist_Code = b.Codelist_Code) and
              (a.Code = b.Code) and
              (strip(a.&target_var.) ^= strip(b.&target_var.));
    quit;
    proc sql noprint;
        create table &output_ds_name. as
        select distinct a.*, &seq. as seq, . as Codelist_Code_Code
        from before a, ds_codelist_code_code b
        where (a.Codelist_Code = b.Codelist_Code) and
              (a.Code = b.Code)
        outer union corr
        select distinct a.*, %eval(&seq.+1) as seq, . as Codelist_Code_Code
        from after a, ds_codelist_code_code b
        where (a.Codelist_Code = b.Codelist_Code) and
              (a.Code = b.Code)
        order by Codelist_Code, Code, seq;
    quit;
    %EDIT_OUTPUT_DS( &output_ds_name.);
%mend EXEC_VALUE_ONLY_CHANGE;
%macro GET_USED1_USED2(target_ds);
    data temp_ds;
        set &target_ds.;
    run;
    data &target_ds.;
        set temp_ds;
        where (used1_flg is not missing) or (used2_flg is not missing); 
    run;
%mend GET_USED1_USED2;
%let inputpath=&projectpath.\input\rawdata;
%let extpath=&projectpath.\input\ext;
%let outputpath=&projectpath.\output;
%let before_file_name=SDTM Terminology 2017-12-22.csv;
%let after_file_name=SDTM Terminology 2020-11-06.csv;
%IMPORT_BEF_AFT;
%IMPORT_USED;
%MATCH_USED(raw_before, before_used);
%MATCH_USED(raw_after, after_used);
