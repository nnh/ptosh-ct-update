**************************************************************************
Program Name : QC_CREATE_USED_CSV.sas
Author : Ohtsuka Mariko
Date : 2021-6-28
SAS version : 9.4
**************************************************************************;
proc datasets library=work kill nolist; quit;
options mprint mlogic symbolgen noquotelenmax;
%let inputpath=C:\Users\Mariko\Box Sync\Projects\NMC ISR èÓïÒÉVÉXÉeÉÄå§ãÜé∫\Ptosh\SDTM Terminology\ptosh-ct-update\input\rawdata;
filename csv_1 "&inputpath.\template.csv" encoding="utf-8";
filename csv_2 "&inputpath.\controlled_terminologies.csv" encoding="utf-8";
proc import datafile=csv_1
    out=raw_template
    dbms=csv replace;
    guessingrows=MAX;
    getnames=no;
run;
proc import datafile=csv_2
    out=controlled_terminologies
    dbms=csv replace;
    guessingrows=MAX;
run;
proc sql noprint;
    create table template as
    select var17 as uuid, var12 as terms_submission_value, var5 as type, var10 as field_type
    from raw_template
    where uuid ne 'uuid';
quit;
proc sql noprint;
    create table template_1 as
    select *
    from template
    where type = 'FieldItem::Assigned';
quit;
proc sql noprint;
    create table template_2 as
    select distinct *
    from template_1
    where field_type = 'radio_button'
    order by terms_submission_value, uuid;
quit;
proc sql noprint;
    create table template_option_1 as
    select distinct uuid, type, field_type, terms_submission_value
    from template
    where type = 'FieldItem::Article'
    order by uuid;
quit;
proc sql noprint;
    create table assignfield as
    select a.*, 1 as used1_flg, b.type, b.field_type
    from controlled_terminologies a inner join template_2 b on (upcase(a.terms_submission_value) = upcase(b.terms_submission_value)) and (a.uuid = b.uuid);
quit;
data checkassignfield;
    set assignfield;
    checkkey=cats(uuid, terms_submission_value);
    drop used1_flg;
run;
data checkct;
    set controlled_terminologies;
    checkkey=cats(uuid, terms_submission_value);
run;
proc sql noprint;
    create table not_assignfield as
    select *, . as used1_flg
    from checkct
    where checkkey not in (select checkkey from checkassignfield);
quit;
data ds_assignfield;
    set assignfield not_assignfield;
run;
proc sql noprint;
    create table option as
    select distinct a.*, 1 as used2_flg
    from ds_assignfield a right join template_option_1 b on (a.uuid = b.uuid);
quit;
data check_option;
    set option;
    drop used2_flg;
run;
proc sql noprint;
    create table not_option as
    select distinct *, . as used2_flg
    from ds_assignfield
    where uuid not in (select uuid from check_option); 
quit;
data ds_option;
    set option not_option;
run;
data temp_used_1;
    set ds_option;
    where used1_flg=1 or used2_flg=1;
run;
proc sql noprint;
    create table temp_used_2 as
    select distinct uuid, id, name, cdisc_name, cdisc_code, version, is_master, is_extensible, parity, terms_id, terms_label, terms_submission_value, terms_code, terms_seq, terms_is_usable, terms_is_master, type, field_type, used1_flg, used2_flg
    from temp_used_1
    where uuid ne ''
    order by uuid, terms_submission_value;
quit;
%ds2csv (data=temp_used_2, runmode=b, csvfile=C:\Users\Mariko\Desktop\qc_used.csv, labels=Y);
