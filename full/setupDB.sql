SET FEEDBACK OFF

WHENEVER SQLERROR EXIT 1

--drop tables
begin execute immediate 'drop table DIM_FORMULA CASCADE CONSTRAINTS PURGE'; exception when others then null; end;
/
begin execute immediate 'drop table FCT_CALC_RESULTS CASCADE CONSTRAINTS PURGE'; exception when others then null; end;
/
begin execute immediate 'drop table PAR_CALC_PLAN CASCADE CONSTRAINTS PURGE'; exception when others then null; end;
/
begin execute immediate 'drop table TMP_FORMULA CASCADE CONSTRAINTS PURGE'; exception when others then null; end;
/
begin execute immediate 'drop table PAR_FORMULA_TO_SYMBOL CASCADE CONSTRAINTS PURGE'; exception when others then null; end;
/
begin execute immediate 'drop table TMP_CALC_PLAN CASCADE CONSTRAINTS PURGE'; exception when others then null; end;
/
begin execute immediate 'drop table PAR_SYMBOLTABLE CASCADE CONSTRAINTS PURGE'; exception when others then null; end;
/
begin execute immediate 'drop table PAR_SYMBOL_CRITPLACE CASCADE CONSTRAINTS PURGE'; exception when others then null; end;
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
  ,CONSTRAINT PK_PAR_CALC_PLAN PRIMARY KEY (CUSTOMER, REF_DATE, FORMULA_ID)
);

CREATE TABLE TMP_FORMULA (
   ID varchar(10)          NOT NULL
  ,NAME varchar(1000)
  ,FORMULA varchar(1000)
  ,ABSTRACT_FORMULA varchar(1000)
  ,SAFE_FORMULA varchar(4000)
  ,CONSTRAINT PK_TMP_FORMULA PRIMARY KEY (ID)
);

CREATE TABLE PAR_FORMULA_TO_SYMBOL (
   FORMULA_ID varchar(10)       NOT NULL
  ,COMPONENT_ID varchar(10)     NOT NULL
  ,ABSTRACT_SYMBOL varchar(10)  NOT NULL
  ,CONSTRAINT FVK_PAR_FORMULA_TO_SYMBOL PRIMARY KEY (FORMULA_ID, COMPONENT_ID)
);

CREATE TABLE TMP_CALC_PLAN (
   CUSTOMER varchar(10)    NOT NULL
  ,REF_DATE date           NOT NULL
  ,FORMULA_ID varchar(10)  NOT NULL
  ,ABSTRACT_FORMULA varchar(1000)
  ,CONSTRAINT FVK_TMP_CALC_PLAN PRIMARY KEY (CUSTOMER, REF_DATE, FORMULA_ID)
);

CREATE TABLE TMP_CALC_RESULTS (
   SOURCE varchar(10)      NOT NULL
  ,CUSTOMER varchar(10)    NOT NULL
  ,REF_DATE date           NOT NULL
  ,FORMULA_ID varchar(10)  NOT NULL
  ,VALUE NUMBER(32,8)
  ,REC_NUM NUMBER(15)
  ,MISSING_VALUE NUMBER(15)
  ,MISSING_TXT varchar(4000)
  ,CONSTRAINT FVK_TMP_CALC_RESULTS PRIMARY KEY (CUSTOMER, REF_DATE, FORMULA_ID)
);

CREATE TABLE PAR_SYMBOLTABLE (
   LITERAL varchar(10)    NOT NULL
  ,SYMCODE varchar(10)    NOT NULL
  ,SYMTYPE varchar(10)    NOT NULL
  ,ARGNUM  number(15)     NOT NULL
  ,PRECEDENCE number(15)  NOT NULL
  ,CONSTRAINT FVK_PAR_SYMBOLTABLE PRIMARY KEY (LITERAL, SYMCODE)
);

CREATE TABLE PAR_SYMBOL_CRITPLACE (
   SYMCODE varchar(10)    NOT NULL
  ,ARGORDER  number(15)     NOT NULL
  ,CRITPLACE number(32,8)
  ,CRITINTERV_LTYPE varchar(10)
  ,CRITINTERV_LVALUE number(32,8)
  ,CRITINTERV_UTYPE varchar(10)
  ,CRITINTERV_UVALUE number(32,8)
  ,CONSTRAINT FVK_PAR_SYMBOL_CRITPLACE PRIMARY KEY (SYMCODE, ARGORDER)
  ,CONSTRAINT CHK_PAR_SYMBOL_CRITPLACE CHECK (
    --either
     (  CRITPLACE is null 
      and (    CRITINTERV_LTYPE is not null
           and CRITINTERV_UTYPE is not null) 
     )
     --or
     OR
     (  CRITPLACE is not null 
      and (    CRITINTERV_LTYPE is null 
           and CRITINTERV_LVALUE is null
           and CRITINTERV_UTYPE is null
           and CRITINTERV_UVALUE is null) 
     )
    )
);

exit 0;