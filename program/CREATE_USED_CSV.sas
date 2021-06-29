**************************************************************************
Program Name : CREATE_USED_CSV.sas
Author : Ohtsuka Mariko
Date : 2021-6-28
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
%let inputpath=&projectpath.\input\rawdata;
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
%macro EXTRACT_CT_FROM_TEMPLATE();
    %local template_col_count i temp default_value_col ct_col type field_type;
    * The first line contains the original column names.;
    data template_header template;
        set raw_template;
        if _N_=1 then do;
          output template_header;
        end;
        else do;
          output template;
        end;
    run;
    * Get the original column names.;
    proc contents noprint
        data=raw_template
        out=template_cols;
    run;
    proc sql noprint;
        select count(*) into:template_col_count
        from template_cols;
    quit;
    %do i = 1 %to &template_col_count.;
      proc sql noprint;
          select var&i. into:temp trimmed
          from template_header;
      quit;
      %if &temp. =field_items_default_value %then %do;
        %let default_value_col=var&i.;
      %end;
      %else %if &temp.=field_items_controlled_terminology.uuid %then %do;
        %let ct_col=var&i.;
      %end;
      %else %if &temp.=field_items_type %then %do;
        %let type=var&i.;
      %end;
      %else %if &temp.=field_items_field_type %then %do;
        %let field_type=var&i.;
      %end;
    %end;
    * Extract the required columns.;
    proc sql noprint;
        create table temp_template_1 as
        select &default_value_col. as terms_submission_value, &ct_col. as uuid, &type. as type, &field_type. as field_type
        from template;
    quit;
    * Extract the CT used in the assignment field.;
    data temp_template_assignment_field;
        set temp_template_1;
        if type='FieldItem::Assigned' and field_type='radio_button' and uuid^='' then output;
    run;
    proc sort data=temp_template_assignment_field nodupkey;
        by terms_submission_value uuid; 
    run; 
    * Extract the CT used as options.;
    data temp_template_options;
        set temp_template_1;
        if type='FieldItem::Article' and uuid^='' then output;
    run;
    proc sort data=temp_template_options nodupkey;
        by uuid; 
    run; 
%mend EXTRACT_CT_FROM_TEMPLATE;
%macro EDIT_VAR_LENGTH(input_ds, output_ds, var_name, var_len);
    data &output_ds.;
        length &var_name. &var_len.;
        set &input_ds.(rename=(&var_name.=temp_var));
        &var_name.=temp_var;
        drop temp_var;
    run;
%mend EDIT_VAR_LENGTH;
%macro PREPARE_SET_USED1_FLG(input_ds, output_ds, seq);
    data &output_ds.;
        set &input_ds.;
        check_terms_submission_value=lowcase(terms_submission_value);
        terms_submission_value_&seq.=terms_submission_value;
        drop terms_submission_value;
    run;
    proc sort data=&output_ds.;
        by check_terms_submission_value uuid;
    run;
%mend PREPARE_SET_USED1_FLG;
%EXTRACT_CT_FROM_TEMPLATE();
%EDIT_VAR_LENGTH(controlled_terminologies, temp_controlled_terminologies, uuid, $200);
%EDIT_VAR_LENGTH(temp_template_assignment_field, temp_template_assignment_field_2, uuid, $200);
%PREPARE_SET_USED1_FLG(temp_controlled_terminologies, temp_controlled_terminologies_2, 1);
%PREPARE_SET_USED1_FLG(temp_template_assignment_field_2, temp_template_assignment_field_3, 2);
* Flag the CT used in the Assign field.;
data ct_assignment_field;
    merge temp_controlled_terminologies_2 temp_template_assignment_field_3 (in=a);
    by check_terms_submission_value uuid;
    if a=1 then used1_flg=1; 
    terms_submission_value=terms_submission_value_1;
    drop terms_submission_value_1 terms_submission_value_2 check_terms_submission_value;
run;
* Flag the CT used as options.;
proc sort data=ct_assignment_field;
    by uuid;
run;
data temp_template_options_2;
    set temp_template_options;
    keep uuid;
run;
data ct_options_1;
    merge ct_assignment_field temp_template_options_2 (in=a);
    by uuid;
    if a=1 then temp_used2_flg=1;
run;
data ct_options;
    set ct_options_1;
    if terms_is_usable='FALSE' then do;
        used2_flg=.;
    end;
    else do;
        used2_flg=temp_used2_flg;
    end;
    drop temp_used2_flg;
run;
* output used.csv;
proc sql noprint;
    create table used as
    select uuid, id, name, cdisc_name, cdisc_code, version, is_master, is_extensible, parity,
           terms_id, terms_label, terms_submission_value, terms_code, terms_seq, terms_is_usable,
           terms_is_master, type, field_type, used1_flg, used2_flg 
    from ct_options
    where (used1_flg=1 or used2_flg=1) and terms_submission_value ne ''
    order by uuid, terms_submission_value;
quit;
%ds2csv (data=used, runmode=b, csvfile=&inputpath.\used.csv, labels=Y);
