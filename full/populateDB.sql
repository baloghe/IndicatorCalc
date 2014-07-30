SET FEEDBACK OFF

WHENEVER SQLERROR EXIT 1

alter session set nls_date_format = 'yyyy-mm-dd hh24:mi:ss';
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '. ' ;
SET SERVEROUTPUT ON;


--TRUNCATE
truncate table DIM_FORMULA            reuse storage;
truncate table FCT_CALC_RESULTS       reuse storage;
truncate table PAR_CALC_PLAN          reuse storage;
truncate table TMP_FORMULA            reuse storage;
truncate table PAR_FORMULA_TO_SYMBOL  reuse storage;
truncate table TMP_CALC_PLAN          reuse storage;
truncate table PAR_SYMBOLTABLE        reuse storage;
truncate table PAR_SYMBOL_CRITPLACE   reuse storage;

--LOAD

--DIM_FORMULA
insert into DIM_FORMULA (ID,NAME,FORMULA) values('CAR','Capital Adequacy Ratio','[CAP] / [RWA]');
insert into DIM_FORMULA (ID,NAME,FORMULA) values('LDR','Loans to Deposits Ratio','[CTOT] / [DTOT]');
insert into DIM_FORMULA (ID,NAME,FORMULA) values('RORWA','Return on RWA','([PBT] - [ITE]) / [RWA]');
insert into DIM_FORMULA (ID,NAME,FORMULA) values('CAP','Capital','');
insert into DIM_FORMULA (ID,NAME,FORMULA) values('RWA','Risk-weighted asset','');
insert into DIM_FORMULA (ID,NAME,FORMULA) values('LTOT','Loans total','');
insert into DIM_FORMULA (ID,NAME,FORMULA) values('DTOT','Deposits total','');
insert into DIM_FORMULA (ID,NAME,FORMULA) values('PBT','Profits before tax','');
insert into DIM_FORMULA (ID,NAME,FORMULA) values('TAX','Income tax','');

--FCT_CALC_RESULTS
insert into FCT_CALC_RESULTS (CUSTOMER,REF_DATE,FORMULA_ID,VALUE) values('Alpha Bank',to_date('2011-12-31','yyyy-mm-dd'),'CAP',9);
insert into FCT_CALC_RESULTS (CUSTOMER,REF_DATE,FORMULA_ID,VALUE) values('Alpha Bank',to_date('2011-12-31','yyyy-mm-dd'),'RWA',100);
insert into FCT_CALC_RESULTS (CUSTOMER,REF_DATE,FORMULA_ID,VALUE) values('Alpha Bank',to_date('2011-12-31','yyyy-mm-dd'),'LTOT',70);
insert into FCT_CALC_RESULTS (CUSTOMER,REF_DATE,FORMULA_ID,VALUE) values('Alpha Bank',to_date('2011-12-31','yyyy-mm-dd'),'DTOT',50);
insert into FCT_CALC_RESULTS (CUSTOMER,REF_DATE,FORMULA_ID,VALUE) values('Alpha Bank',to_date('2012-1-31','yyyy-mm-dd'),'CAP',10);
insert into FCT_CALC_RESULTS (CUSTOMER,REF_DATE,FORMULA_ID,VALUE) values('Alpha Bank',to_date('2012-1-31','yyyy-mm-dd'),'RWA',101);
insert into FCT_CALC_RESULTS (CUSTOMER,REF_DATE,FORMULA_ID,VALUE) values('Alpha Bank',to_date('2012-1-31','yyyy-mm-dd'),'LTOT',75);
insert into FCT_CALC_RESULTS (CUSTOMER,REF_DATE,FORMULA_ID,VALUE) values('Alpha Bank',to_date('2012-1-31','yyyy-mm-dd'),'DTOT',55);
insert into FCT_CALC_RESULTS (CUSTOMER,REF_DATE,FORMULA_ID,VALUE) values('Beta Bank',to_date('2011-12-31','yyyy-mm-dd'),'CAP',20);
insert into FCT_CALC_RESULTS (CUSTOMER,REF_DATE,FORMULA_ID,VALUE) values('Beta Bank',to_date('2011-12-31','yyyy-mm-dd'),'RWA',200);
insert into FCT_CALC_RESULTS (CUSTOMER,REF_DATE,FORMULA_ID,VALUE) values('Beta Bank',to_date('2011-12-31','yyyy-mm-dd'),'LTOT',150);
insert into FCT_CALC_RESULTS (CUSTOMER,REF_DATE,FORMULA_ID,VALUE) values('Beta Bank',to_date('2011-12-31','yyyy-mm-dd'),'DTOT',110);
insert into FCT_CALC_RESULTS (CUSTOMER,REF_DATE,FORMULA_ID,VALUE) values('Beta Bank',to_date('2012-1-31','yyyy-mm-dd'),'CAP',21);
insert into FCT_CALC_RESULTS (CUSTOMER,REF_DATE,FORMULA_ID,VALUE) values('Beta Bank',to_date('2012-1-31','yyyy-mm-dd'),'RWA',198);
insert into FCT_CALC_RESULTS (CUSTOMER,REF_DATE,FORMULA_ID,VALUE) values('Beta Bank',to_date('2012-1-31','yyyy-mm-dd'),'LTOT',146);
insert into FCT_CALC_RESULTS (CUSTOMER,REF_DATE,FORMULA_ID,VALUE) values('Beta Bank',to_date('2012-1-31','yyyy-mm-dd'),'DTOT',102);
insert into FCT_CALC_RESULTS (CUSTOMER,REF_DATE,FORMULA_ID,VALUE) values('Beta Bank',to_date('2011-12-31','yyyy-mm-dd'),'PBT',10);
insert into FCT_CALC_RESULTS (CUSTOMER,REF_DATE,FORMULA_ID,VALUE) values('Beta Bank',to_date('2011-12-31','yyyy-mm-dd'),'ITE',2);

--PAR_CALC_PLAN
insert into PAR_CALC_PLAN (CUSTOMER,REF_DATE,FORMULA_ID) values('Alpha Bank',to_date('2011-12-31','yyyy-mm-dd'),'CAR');
insert into PAR_CALC_PLAN (CUSTOMER,REF_DATE,FORMULA_ID) values('Alpha Bank',to_date('2011-12-31','yyyy-mm-dd'),'LDR');
insert into PAR_CALC_PLAN (CUSTOMER,REF_DATE,FORMULA_ID) values('Beta Bank',to_date('2011-12-31','yyyy-mm-dd'),'CAR');
insert into PAR_CALC_PLAN (CUSTOMER,REF_DATE,FORMULA_ID) values('Beta Bank',to_date('2012-1-31','yyyy-mm-dd'),'CAR');
insert into PAR_CALC_PLAN (CUSTOMER,REF_DATE,FORMULA_ID) values('Beta Bank',to_date('2011-12-31','yyyy-mm-dd'),'RORWA');

--PAR_SYMBOLTABLE
insert into PAR_SYMBOLTABLE(LITERAL,SYMCODE,SYMTYPE,ARGNUM,PRECEDENCE) values('(','(','N',0,0);
insert into PAR_SYMBOLTABLE(LITERAL,SYMCODE,SYMTYPE,ARGNUM,PRECEDENCE) values(')',')','Z',0,0);
insert into PAR_SYMBOLTABLE(LITERAL,SYMCODE,SYMTYPE,ARGNUM,PRECEDENCE) values('+','+','I',2,1);
insert into PAR_SYMBOLTABLE(LITERAL,SYMCODE,SYMTYPE,ARGNUM,PRECEDENCE) values('-','-','I',2,1);
insert into PAR_SYMBOLTABLE(LITERAL,SYMCODE,SYMTYPE,ARGNUM,PRECEDENCE) values('*','*','I',2,1);
insert into PAR_SYMBOLTABLE(LITERAL,SYMCODE,SYMTYPE,ARGNUM,PRECEDENCE) values('^','**','I',2,1);
insert into PAR_SYMBOLTABLE(LITERAL,SYMCODE,SYMTYPE,ARGNUM,PRECEDENCE) values('**','**','I',2,2);
insert into PAR_SYMBOLTABLE(LITERAL,SYMCODE,SYMTYPE,ARGNUM,PRECEDENCE) values('/','/','I',2,2);
insert into PAR_SYMBOLTABLE(LITERAL,SYMCODE,SYMTYPE,ARGNUM,PRECEDENCE) values('LN','LN','F',2,3);

--PAR_SYMBOL_CRITPLACE
insert into PAR_SYMBOL_CRITPLACE(SYMCODE,ARGORDER,CRITPLACE,CRITINTERV_LTYPE,CRITINTERV_LVALUE,CRITINTERV_UTYPE,CRITINTERV_UVALUE) values('/',2,0,null,null,null,null);
insert into PAR_SYMBOL_CRITPLACE(SYMCODE,ARGORDER,CRITPLACE,CRITINTERV_LTYPE,CRITINTERV_LVALUE,CRITINTERV_UTYPE,CRITINTERV_UVALUE) values('LN',1,null,'V',null,'Z',0);


commit;

exit 0;
