
SET FEEDBACK OFF

WHENEVER SQLERROR EXIT 1

/****  PACKAGE   -- START ****/
create or replace
PACKAGE FORMULA_CALC_PKG AUTHID CURRENT_USER AS
   PROCEDURE RUN_SQL(sqlStr in varchar2, callpoint in varchar2);
   PROCEDURE FORMULA_PREPROCESS;
   PROCEDURE FORMULA_CALC_MAIN(calc_plan_table in varchar2, source_table in varchar2, temp_table in varchar2);
   PROCEDURE FORMULA_CALC_STEP(absFormula IN varchar2, safeFormula IN varchar2, temp_table in varchar2, calc_plan_table in varchar2);
   FUNCTION GET_SQL(absFormula IN varchar2, argNum IN NUMBER, safeFormula IN VARCHAR2, temp_table in varchar2, calc_plan_table in varchar2) RETURN VARCHAR2;
END FORMULA_CALC_PKG;
/

create or replace
PACKAGE BODY FORMULA_CALC_PKG AS
  PROCEDURE RUN_SQL(sqlStr in varchar2, callpoint in varchar2) is
    begin
      execute immediate sqlStr;
    exception when others then
      dbms_output.put_line(callpoint || ' FAILED sqlStr=');
      dbms_output.put_line(sqlStr);
      RAISE;
    end;

  PROCEDURE FORMULA_PREPROCESS IS
      TYPE cTpFormDef IS REF CURSOR;
      cForm  cTpFormDef;
      TYPE cRecTp IS RECORD ( id 		DIM_FORMULA.id%type
                             ,name 		DIM_FORMULA.name%type
                             ,formula  	DIM_FORMULA.formula%type);
      rForm cRecTp;
      
	  sqlStr varchar2(20000);
	  
      /* abstract formula ingredients */
      lexi LEXER;
      cTable LEXER_CHARCLASS := LEXER_CHARCLASS(null,null,null,null,null,null,null);
      sTable LEXER_SYMBOLTABLE := LEXER_SYMBOLTABLE(VARR_CHAR_SYMBOL());
      lexAbsFormula varchar2(200);
      lexSafeFormula varchar2(2000);
      lexFormula FORMULA;
      idx integer;
      lexSymb varchar2(200);
      lexComponent varchar2(500);
    begin
      /* reset temporary and param tables */
      RUN_SQL('truncate table TMP_FORMULA reuse storage','FORMULA_PREPROCESS :: truncate');
      RUN_SQL('truncate table PAR_FORMULA_TO_SYMBOL reuse storage','FORMULA_PREPROCESS :: truncate');
      commit;
      
      /* init abstract formula generator */
      cTable.initialize;
      sTable.initFromTables('PAR_SYMBOLTABLE'
                    ,'LITERAL'
                    ,'SYMCODE'
                    ,'SYMTYPE'
                    ,'ARGNUM'
                    ,'PRECEDENCE'
                    ,'PAR_SYMBOL_CRITPLACE'
                    ,'SYMCODE'
                    ,'ARGORDER'
                    ,'CRITPLACE'
                    ,'CRITINTERV_LTYPE'
                    ,'CRITINTERV_LVALUE'
                    ,'CRITINTERV_UTYPE'
                    ,'CRITINTERV_UVALUE'
                    );
      lexi := LEXER(null,null,null,cTable,sTable);
      
      /* iterate through the formulae and generate:
        - abstract formula
        - safe formula
        - symbol substitutes for formula components
      */
      sqlStr := 'select id, name, formula
                 from DIM_FORMULA';
      OPEN cForm FOR 
        sqlStr
        ;
      LOOP
        FETCH cForm INTO rForm;
        EXIT WHEN cForm%notfound;
        
        begin
          lexi.processFormulaID(rForm.formula);
          if(lexi.formula_part is not null) then
            lexAbsFormula := lexi.formula_part.toString();
            lexFormula := FORMULA(lexi.formula_part,null);
            lexFormula.createCritPlaces;
            lexSafeFormula := lexFormula.getSafeFormula;
            sqlStr := 'insert into TMP_FORMULA (id, name, formula, abstract_formula, safe_formula)
                     values(''' || rForm.id || ''', ''' || rForm.name || ''', ''' || rForm.formula || ''', ''' || lexAbsFormula || ''', ''' || lexSafeFormula || ''')';
            run_sql(sqlStr,'FORMULA_CALC_PKG.FORMULA_PREPROCESS');
            
            idx := lexi.formulaID_to_aSymb.FIRST;
            while(idx is not null) loop
              lexSymb := lexi.formulaID_to_aSymb(idx).mutato_azonosito;
              lexComponent := lexi.formulaID_to_aSymb(idx).absztrakt_szimbolum.literal;
              sqlStr := 'insert into PAR_FORMULA_TO_SYMBOL (formula_id, component_id, abstract_symbol)
                       values(''' || rForm.id || ''', ''' || lexSymb || ''', ''' || lexComponent || ''')';
              run_sql(sqlStr,'FORMULA_CALC_PKG.FORMULA_PREPROCESS');
              
              idx := lexi.formulaID_to_aSymb.next(idx);
            end loop;--(idx is not null)
          end if;--(lexi.formula_part is not null)
        end;
      END LOOP;--fetch
    end FORMULA_PREPROCESS;
    
    
    PROCEDURE FORMULA_CALC_MAIN(calc_plan_table in varchar2, source_table in varchar2, temp_table in varchar2) IS
      TYPE cTp IS REF CURSOR;
      cForm  cTp;
      
      sqlStr varchar2(20000);
      
      absFormula varchar2(1000);
      safeFormula varchar2(1000);
    begin
      --initialize temp table
      RUN_SQL('truncate table ' || temp_table || ' reuse storage'
              ,'FORMULA_CALC_MAIN :: initialize temp calc table / truncate');
              
      RUN_SQL('insert into ' || temp_table || '(SOURCE,CUSTOMER,REF_DATE,FORMULA_ID,VALUE) 
               select ''init'',CUSTOMER,REF_DATE,FORMULA_ID,VALUE
               from ' || source_table
              ,'FORMULA_CALC_MAIN :: initialize temp calc table / populate');
      
      --evaluate formulae
      sqlStr := 'select distinct ABSTRACT_FORMULA, SAFE_FORMULA 
                  from TMP_FORMULA 
                  where ABSTRACT_FORMULA is not null';
      OPEN cForm FOR 
        sqlStr
        ;
      LOOP
        FETCH cForm INTO absFormula, safeFormula;
        EXIT WHEN cForm%notfound;
                       
        dbms_output.put_line('FORMULA_CALC_MAIN :: call FORMULA_CALC_STEP with params');
        dbms_output.put_line('    absFormula='||absFormula||',safeFormula='||safeFormula);
        FORMULA_CALC_STEP(absFormula,safeFormula,temp_table,calc_plan_table);
      END LOOP;--fetch
    end FORMULA_CALC_MAIN;
    
    
    PROCEDURE FORMULA_CALC_STEP(absFormula IN varchar2, safeFormula IN varchar2, temp_table in varchar2, calc_plan_table in varchar2) is
      sqlStr varchar2(20000);
      
      argNum number(15);
      recNum number(15);
    begin
      
      --truncate tmp_calc_plan
      RUN_SQL('truncate table TMP_CALC_PLAN reuse storage','FORMULA_CALC_STEP :: truncate temp plan table');
      
      sqlStr := 'select distinct p.CUSTOMER, p.REF_DATE, p.FORMULA_ID, ''' || absFormula || ''' as ABSTRACT_FORMULA
                  from TMP_FORMULA t
                  left join PAR_CALC_PLAN p
                    on p.FORMULA_ID = t.ID
                  where t.ABSTRACT_FORMULA = ''' || absFormula || '''';
      RUN_SQL('insert into ' || calc_plan_table || ' (CUSTOMER,REF_DATE,FORMULA_ID,ABSTRACT_FORMULA) ' || sqlStr
          ,'FORMULA_CALC_STEP :: populate temp plan table with absFormula=' || absFormula);
      
      execute immediate 'select count(1) from (
                            select distinct abstract_symbol
                            from PAR_FORMULA_TO_SYMBOL p
                            inner join TMP_FORMULA t
                              on p.FORMULA_ID = t.ID
                            where t.ABSTRACT_FORMULA = ''' || absFormula || '''
                          )' 
            into argNum;
      
      execute immediate 'select count(1) from TMP_CALC_PLAN'
            into recNum;
      
      sqlStr :=  'MERGE INTO ' || temp_table || ' t
                    USING (' || GET_SQL(absFormula,argNum,safeFormula,temp_table,calc_plan_table) || ') s
                    ON (    t.SOURCE = s.SOURCE
                        and t.CUSTOMER = s.CUSTOMER
                        and t.REF_DATE = s.REF_DATE
                        and t.FORMULA_ID = s.FORMULA_ID)
                        
                  WHEN MATCHED THEN
                    UPDATE SET t.VALUE = s.VALUE
                    
                  WHEN NOT MATCHED THEN
                    INSERT (t.SOURCE, t.CUSTOMER, t.REF_DATE, t.FORMULA_ID, t.VALUE, t.REC_NUM, t.MISSING_VALUE, t.MISSING_TXT)
                    VALUES (s.SOURCE, s.CUSTOMER, s.REF_DATE, s.FORMULA_ID, s.VALUE, s.REC_NUM, s.MISSING_VALUE, s.MISSING_TXT)';
      
      dbms_output.put_line('   FORMULA_CALC_STEP :: sql='   || GET_SQL(absFormula,argNum,safeFormula,temp_table,calc_plan_table) );
      
      RUN_SQL(sqlStr, 'FORMULA_CALC_STEP :: absFormula=' || absFormula);
      
    end FORMULA_CALC_STEP;
    
    
    FUNCTION GET_SQL(absFormula IN varchar2, argNum IN NUMBER, safeFormula IN VARCHAR2, temp_table in varchar2, calc_plan_table in varchar2) RETURN VARCHAR2 is
      sqlStr varchar2(20000);
      tmpStr varchar2(20000);
      idx number(15);
    begin
      sqlStr :=  'SELECT ''' || absFormula ||''' as SOURCE, CUSTOMER, REF_DATE, FORMULA_ID
                             , FORMULA_RESULT as VALUE, REC_NUM, MISSING_VALUE, MISSING_TXT
                  FROM
                  (
                    SELECT REF_DATE, CUSTOMER, FORMULA_ID';
                    
      --generate symbols 1 to argNum
      tmpStr := '';
      for idx in 1..argNum loop
        tmpStr := tmpStr || ',a' || idx;
      end loop; --next idx
      
      sqlStr := sqlStr || tmpStr || '
                          ,' || safeFormula || ' as FORMULA_RESULT
                          ,rec_num, MISSING_VALUE
                            ,case when MISSING_VALUE>0 then MISSING_TXT else '''' end as MISSING_TXT
                      FROM (
                        SELECT  T.REF_DATE, T.CUSTOMER, T.FORMULA_ID';
                        
      --generate values from input tables (one per symbol)
      tmpStr := '';
      for idx in 1..argNum loop
        tmpStr := tmpStr || ',x' || idx || '.VALUE as a' || idx;
      end loop; --next idx
      
      sqlStr := sqlStr || tmpStr || '
                                ,COUNT(*) as REC_NUM';
      
      --generate sum of missing values
      tmpStr := ',SUM(X1.MISSING_VALUE';
      for idx in 2..argNum loop
        tmpStr := tmpStr || ' + X' || idx || '.MISSING_VALUE';
      end loop; --next idx
      tmpStr := tmpStr || ')/ ' || argNum || ' as MISSING_VALUE';
      
      sqlStr := sqlStr || tmpStr;
      
      --generate max of missing text
      tmpStr := ',MAX(X1.MISSING_TXT';
      for idx in 2..argNum loop
        tmpStr := tmpStr || ' || '':'' || X' || idx || '.MISSING_TXT';
      end loop; --next idx
      tmpStr := tmpStr || ') as MISSING_TXT';
      
      sqlStr := sqlStr || tmpStr || '
                        FROM
                        ' || calc_plan_table || ' T
                        ';
                        
      --generate one nested query per symbol
      for idx in 1..argNum loop
        tmpStr := ',(
                       SELECT T' || idx || '.REF_DATE, T' || idx || '.CUSTOMER, T' || idx || '.FORMULA_ID
                             ,FM' || idx || '.VALUE
                             ,CASE WHEN FM' || idx || '.VALUE IS NULL THEN 1 ELSE 0 END AS MISSING_VALUE
                             ,CASE WHEN FM' || idx || '.VALUE IS NULL 
                                   THEN P' || idx || '.COMPONENT_ID || '':'' || to_char(T' || idx || '.REF_DATE)
                                   ELSE '''' END AS MISSING_TXT
                       FROM
                         TMP_CALC_PLAN T' || idx || '
                       INNER JOIN 
                         PAR_FORMULA_TO_SYMBOL P' || idx || '
                         ON T' || idx || '.FORMULA_ID=P' || idx || '.FORMULA_ID
                       LEFT JOIN 
                         ' || temp_table || ' FM' || idx || '
                       ON     T' || idx || '.REF_DATE=FM' || idx || '.REF_DATE 
                          AND T' || idx || '.CUSTOMER=FM' || idx || '.CUSTOMER 
                          AND P' || idx || '.COMPONENT_ID=FM' || idx || '.FORMULA_ID
                       
                       WHERE P' || idx || '.ABSTRACT_SYMBOL = ''a' || idx || '''
                      ) X' || idx || ' 
                      ';
        
        sqlStr := sqlStr || tmpStr;
      end loop; --next idx
      
      --generate WHERE clause
      tmpStr := 'WHERE T.REF_DATE = X1.REF_DATE AND T.CUSTOMER = X1.CUSTOMER AND T.FORMULA_ID = X1.FORMULA_ID ';
      for idx in 2..argNum loop
        tmpStr := tmpStr || ' AND T.REF_DATE = X' || idx || '.REF_DATE AND T.CUSTOMER = X' || idx || '.CUSTOMER AND T.FORMULA_ID = X' || idx || '.FORMULA_ID ';
      end loop; --next idx
      
      sqlStr := sqlStr || tmpStr || '
                 GROUP BY T.REF_DATE, T.CUSTOMER, T.FORMULA_ID';
                 
      --generate GROUP BY elements (one per symbol);
      tmpStr := '';
      for idx in 1..argNum loop
        tmpStr := tmpStr || ',X' || idx || '.VALUE';
      end loop; --next idx
      
      sqlStr := sqlStr || tmpStr || '
              )
            )';
      
      return sqlStr;
    end;
END;
/
/****  PACKAGE   -- END ****/

commit;
EXIT 0;