alter session set nls_date_format = 'yyyy-mm-dd hh24:mi:ss';
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '. ' ;
SET SERVEROUTPUT ON;

---------------------------------------------
-- "External" information   -- START
---------------------------------------------
--drop tables
begin execute immediate 'drop table DIM_FORMULA'; exception when others then null; end;
/
begin execute immediate 'drop table FCT_CALC_RESULTS'; exception when others then null; end;
/
begin execute immediate 'drop table PAR_CALC_PLAN'; exception when others then null; end;
/

--table creation
CREATE TABLE DIM_FORMULA (
   ID varchar(10)          NOT NULL
  ,NAME varchar(1000)
  ,FORMULA varchar(1000)
  ,CONSTRAINT PK_DIM_FORMULA PRIMARY KEY (ID)
);

CREATE TABLE FCT_CALC_RESULTS (
   CUSTOMER varchar(10)    NOT NULL
  ,REF_DATE date           NOT NULL
  ,FORMULA_ID varchar(10)  NOT NULL
  ,VALUE NUMBER(32,8)
  ,CONSTRAINT FVK_FCT_CALC_RESULTS PRIMARY KEY (CUSTOMER, REF_DATE, FORMULA_ID)
);

CREATE TABLE PAR_CALC_PLAN (
   CUSTOMER varchar(10)    NOT NULL
  ,REF_DATE date           NOT NULL
  ,FORMULA_ID varchar(10)  NOT NULL
  ,CONSTRAINT FVK_PAR_CALC_PLAN PRIMARY KEY (CUSTOMER, REF_DATE, FORMULA_ID)
);

--populate tables
insert into DIM_FORMULA (ID,NAME,FORMULA) values('CAR','Capital Adequacy Ratio','[CAP] / [RWA]');
insert into DIM_FORMULA (ID,NAME,FORMULA) values('LDR','Loans to Deposits Ratio','[CTOT] / [DTOT]');
insert into DIM_FORMULA (ID,NAME,FORMULA) values('RORWA','Return on RWA','([PBT] - [ITE]) / [RWA]');
insert into DIM_FORMULA (ID,NAME,FORMULA) values('CAP','Capital','');
insert into DIM_FORMULA (ID,NAME,FORMULA) values('RWA','Risk-weighted asset','');
insert into DIM_FORMULA (ID,NAME,FORMULA) values('LTOT','Loans total','');
insert into DIM_FORMULA (ID,NAME,FORMULA) values('DTOT','Deposits total','');
insert into DIM_FORMULA (ID,NAME,FORMULA) values('PBT','Profits before tax','');
insert into DIM_FORMULA (ID,NAME,FORMULA) values('TAX','Income tax','');

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

insert into PAR_CALC_PLAN (CUSTOMER,REF_DATE,FORMULA_ID) values('Alpha Bank',to_date('2011-12-31','yyyy-mm-dd'),'CAR');
insert into PAR_CALC_PLAN (CUSTOMER,REF_DATE,FORMULA_ID) values('Alpha Bank',to_date('2011-12-31','yyyy-mm-dd'),'LDR');
insert into PAR_CALC_PLAN (CUSTOMER,REF_DATE,FORMULA_ID) values('Beta Bank',to_date('2011-12-31','yyyy-mm-dd'),'CAR');
insert into PAR_CALC_PLAN (CUSTOMER,REF_DATE,FORMULA_ID) values('Beta Bank',to_date('2012-1-31','yyyy-mm-dd'),'CAR');
insert into PAR_CALC_PLAN (CUSTOMER,REF_DATE,FORMULA_ID) values('Beta Bank',to_date('2011-12-31','yyyy-mm-dd'),'RORWA');

commit;
---------------------------------------------
-- "External" information   -- END
---------------------------------------------


---------------------------------------------
-- Preprocessing   -- START
---------------------------------------------

--DIM_FORMULA
alter table DIM_FORMULA add ABSTRACT_FORMULA varchar(1000);

--PAR_FORMULA_TO_SYMBOL
begin execute immediate 'drop table PAR_FORMULA_TO_SYMBOL'; exception when others then null; end;
/

create table PAR_FORMULA_TO_SYMBOL (
   FORMULA_ID varchar(10)       NOT NULL
  ,COMPONENT_ID varchar(10)     NOT NULL
  ,ABSTRACT_SYMBOL varchar(10)  NOT NULL
  ,CONSTRAINT PK_PAR_FORMULA_TO_SYMBOL PRIMARY KEY (FORMULA_ID, COMPONENT_ID)
);

--PAR_CALC_PLAN 
alter table PAR_CALC_PLAN add ABSTRACT_FORMULA varchar(1000);

--Here comes the first magical part where we populate the new table & new columns with simple DML statements.
--Later on magic will be replaced with a procedure that takes "External" information as input
--and transforms it as required.
update DIM_FORMULA set ABSTRACT_FORMULA='a1/a2' where ID in ('CAR','LDR');
update DIM_FORMULA set ABSTRACT_FORMULA='(a1-a2)/a3' where ID in ('RORWA');

insert into PAR_FORMULA_TO_SYMBOL(FORMULA_ID,COMPONENT_ID,ABSTRACT_SYMBOL) values('CAR','CAP','a1');
insert into PAR_FORMULA_TO_SYMBOL(FORMULA_ID,COMPONENT_ID,ABSTRACT_SYMBOL) values('CAR','RWA','a2');
insert into PAR_FORMULA_TO_SYMBOL(FORMULA_ID,COMPONENT_ID,ABSTRACT_SYMBOL) values('LDR','LTOT','a1');
insert into PAR_FORMULA_TO_SYMBOL(FORMULA_ID,COMPONENT_ID,ABSTRACT_SYMBOL) values('LDR','DTOT','a2');
insert into PAR_FORMULA_TO_SYMBOL(FORMULA_ID,COMPONENT_ID,ABSTRACT_SYMBOL) values('RORWA','PBT','a1');
insert into PAR_FORMULA_TO_SYMBOL(FORMULA_ID,COMPONENT_ID,ABSTRACT_SYMBOL) values('RORWA','ITE','a2');
insert into PAR_FORMULA_TO_SYMBOL(FORMULA_ID,COMPONENT_ID,ABSTRACT_SYMBOL) values('RORWA','RWA','a3');

update PAR_CALC_PLAN set ABSTRACT_FORMULA='a1/a2' where FORMULA_ID in ('CAR','LDR');
update PAR_CALC_PLAN set ABSTRACT_FORMULA='(a1-a2)/a3' where FORMULA_ID in ('RORWA');

commit;
---------------------------------------------
-- Preprocessing   -- END
---------------------------------------------


---------------------------------------------
-- Processing a1/a2  -- START
---------------------------------------------
--Second magic: input ABSTRACT_FORMULA transformed to SAFE_FORMULA
--and dynamic SQL generated


WITH TMP_CALC_PLAN as (
  select p.customer, p.ref_date, p.formula_id
        ,c.component_id, c.abstract_symbol as component_symbol
  from PAR_CALC_PLAN p
  left join PAR_FORMULA_TO_SYMBOL c
    on p.formula_id = c.formula_id
)
SELECT REF_DATE, CUSTOMER, FORMULA_ID
           , FORMULA_RESULT, REC_NUM, MISSING_VALUE, MISSING_TXT
FROM
(
  SELECT REF_DATE, CUSTOMER, FORMULA_ID, a1, a2
        ,(case when a1 is null or a2 is null or a2 = 0 then NULL else a1/a2 end) as FORMULA_RESULT
        ,rec_num, MISSING_VALUE
        ,case when MISSING_VALUE>0 then MISSING_TXT else '' end as MISSING_TXT
  FROM (
    SELECT  T.REF_DATE, T.CUSTOMER, T.FORMULA_ID
      ,X1.VALUE as A1
      ,X2.VALUE as A2
    
      ,COUNT(*) as REC_NUM
      ,SUM(X1.MISSING_VALUE + X2.MISSING_VALUE)/ 2 as MISSING_VALUE
      ,max(X1.MISSING_TXT || ':' || X2.MISSING_TXT) as MISSING_TXT
    
    FROM
    TMP_CALC_PLAN T
    ,(
       SELECT T1.REF_DATE, T1.CUSTOMER, T1.FORMULA_ID
         ,FM1.VALUE
         ,CASE WHEN FM1.VALUE IS NULL THEN 1 ELSE 0 END AS MISSING_VALUE
         ,CASE WHEN FM1.VALUE IS NULL 
               THEN T1.COMPONENT_ID || ':' || to_char(T1.REF_DATE)
               ELSE '' END AS MISSING_TXT
       FROM
         TMP_CALC_PLAN T1
       LEFT JOIN 
         FCT_CALC_RESULTS FM1
       ON     T1.REF_DATE=FM1.REF_DATE 
          AND T1.CUSTOMER=FM1.CUSTOMER 
          AND T1.COMPONENT_ID=FM1.FORMULA_ID
       WHERE T1.COMPONENT_SYMBOL = 'a1'
    ) X1
    ,(
       SELECT T2.REF_DATE, T2.CUSTOMER, T2.FORMULA_ID
         ,FM2.VALUE
         ,CASE WHEN FM2.VALUE IS NULL THEN 1 ELSE 0 END AS MISSING_VALUE
         ,CASE WHEN FM2.VALUE IS NULL 
               THEN T2.COMPONENT_ID || ':' || to_char(T2.REF_DATE)
               ELSE '' END AS MISSING_TXT
       FROM
         TMP_CALC_PLAN T2
       LEFT JOIN 
         FCT_CALC_RESULTS FM2
       ON     T2.REF_DATE=FM2.REF_DATE 
          AND T2.CUSTOMER=FM2.CUSTOMER 
          AND T2.COMPONENT_ID=FM2.FORMULA_ID
       WHERE T2.COMPONENT_SYMBOL = 'a2'
    ) X2
    
    
    WHERE 
           T.REF_DATE = X1.REF_DATE AND T.CUSTOMER = X1.CUSTOMER AND T.FORMULA_ID = X1.FORMULA_ID
       AND T.REF_DATE = X2.REF_DATE AND T.CUSTOMER = X2.CUSTOMER AND T.FORMULA_ID = X2.FORMULA_ID
    
    
    group by T.REF_DATE, T.CUSTOMER, T.FORMULA_ID, X1.VALUE, X2.VALUE
  )
);

---------------------------------------------
-- Processing a1/a2  -- END
---------------------------------------------