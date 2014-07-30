ALTER session SET nls_date_format        = 'yyyy-mm-dd hh24:mi:ss';
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '. ' ;
SET SERVEROUTPUT ON;
/***  UNIT TESTS  -- for the package  ***/
/*** RUN_SQL  -- START ***/
BEGIN
  dbms_output.put_line('UNIT TESTS PACKAGE / RUN_SQL   -- START');
  FORMULA_CALC_PKG.run_sql('select proba from dual', 'HeLlO');
  dbms_output.put_line('UNIT TESTS PACKAGE / RUN_SQL   -- END');
END;
/
/*** RUN_SQL  -- END ***/
/*** FORMULA_PREPROCESS  -- START ***/
DECLARE
  pNum NUMBER(15);
  fNum NUMBER(15);
BEGIN
  dbms_output.put_line('UNIT TESTS PACKAGE / FORMULA_PREPROCESS   -- START');
  FORMULA_CALC_PKG.FORMULA_PREPROCESS;
  EXECUTE immediate 'select count(1) from PAR_FORMULA_TO_SYMBOL' INTO pNum;
  EXECUTE immediate 'select count(1) from TMP_FORMULA' INTO fNum;
  dbms_output.put_line('PAR_FORMULA_TO_SYMBOL: ' || pNum || ', TMP_FORMULA: ' || fNum);
  dbms_output.put_line('UNIT TESTS PACKAGE / FORMULA_PREPROCESS   -- END');
END;
/
/*** FORMULA_PREPROCESS  -- END ***/
/*** GET_SQL  -- START ***/
SET SERVEROUTPUT ON;
BEGIN
  dbms_output.put_line('UNIT TESTS PACKAGE / GET_SQL   -- START');
  
  dbms_output.put_line( FORMULA_CALC_PKG.GET_SQL('a1/a2', 2 
    , '(case when ((/*1*/ (a2 = 0))) THEN NULL ELSE (a1/a2) END)', 'TMP_CALC_RESULTS', 'TMP_CALC_PLAN') );

  dbms_output.put_line('UNIT TESTS PACKAGE / GET_SQL   -- END');
END;
/
/*** GET_SQL  -- END ***/

/*** FORMULA_CALC_STEP  -- START ***/
SET SERVEROUTPUT ON;
DECLARE
  temp_table varchar2(100) := 'tmp_calc_results';
  source_table varchar2(100) := 'fct_calc_results';
  calc_plan_table varchar2(100) := 'tmp_calc_plan';
  
  absFormula varchar2(1000)   := 'a1/a2';
  safeFormula varchar2(1000)  := '(case when ((/*1*/ (a2 = 0))) THEN NULL ELSE (a1/a2) END)';
BEGIN
  dbms_output.put_line('UNIT TESTS PACKAGE / FORMULA_CALC_STEP   -- START');
  
  dbms_output.put_line('--initialize temp table');
  FORMULA_CALC_PKG.RUN_SQL('truncate table ' || temp_table || ' reuse storage'
          ,'FORMULA_CALC_MAIN :: initialize temp calc table');
          
  FORMULA_CALC_PKG.RUN_SQL('insert into ' || temp_table || '(SOURCE,CUSTOMER,REF_DATE,FORMULA_ID,VALUE) 
           select ''init'',CUSTOMER,REF_DATE,FORMULA_ID,VALUE
           from ' || source_table
          ,'FORMULA_CALC_MAIN :: initialize temp calc table');
  
  dbms_output.put_line('--run calc step for ' || absFormula);
  FORMULA_CALC_PKG.FORMULA_CALC_STEP(absFormula,safeFormula,temp_table,calc_plan_table);

  dbms_output.put_line('UNIT TESTS PACKAGE / FORMULA_CALC_STEP   -- END');
END;
/
/*** FORMULA_CALC_STEP  -- END ***/

/*** FORMULA_CALC_MAIN  -- START ***/
SET SERVEROUTPUT ON;
BEGIN
  dbms_output.put_line('UNIT TESTS PACKAGE / CALC_MAIN   -- START');
  FORMULA_CALC_PKG.FORMULA_PREPROCESS;
  FORMULA_CALC_PKG.FORMULA_CALC_MAIN('tmp_calc_plan', 'fct_calc_results', 'tmp_calc_results');
  dbms_output.put_line('UNIT TESTS PACKAGE / CALC_MAIN   -- END');
END;
/
/*** FORMULA_CALC_MAIN  -- END ***/

select *
from tmp_calc_results;