alter session set nls_date_format = 'yyyy-mm-dd hh24:mi:ss';
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '. ' ;
SET SERVEROUTPUT ON;

/***  UNIT TESTS  ***/

/*** TYPE CRITINTERV  -- START ***/
/*        (lowerBarrierType , lowerBarrierValue , upperBarrierType , upperBarrierValue)   */
declare
  inter_openinf_openinf CRITINTERV;
  inter_openinf_open5 CRITINTERV;
  inter_openm2_openinf CRITINTERV;
  inter_openm2_open5 CRITINTERV;
  inter_closedm2_closed6 CRITINTERV;
begin
  dbms_output.put_line('UNIT TESTS / TYPE CRITINTERV   -- START');
  
  inter_openinf_openinf := CRITINTERV('V',0,'V',0);
  dbms_output.put_line('inter_openinf_openinf = ' || inter_openinf_openinf.toString());
  dbms_output.put_line('       CASE condition = ' || inter_openinf_openinf.getCaseCondition('MYVAR'));
  
  inter_openinf_open5 := CRITINTERV('V',0,'N',5);
  dbms_output.put_line('inter_openinf_open5 = ' || inter_openinf_open5.toString());
  dbms_output.put_line('     CASE condition = ' || inter_openinf_open5.getCaseCondition('MYVAR'));
  
  inter_openm2_openinf := CRITINTERV('N',-2,'V',0);
  dbms_output.put_line('inter_openm2_openinf = ' || inter_openm2_openinf.toString());
  dbms_output.put_line('      CASE condition = ' || inter_openm2_openinf.getCaseCondition('MYVAR'));
  
  inter_openm2_open5 := CRITINTERV('N',-2,'N',5);
  dbms_output.put_line('inter_openm2_open5 = ' || inter_openm2_open5.toString());
  dbms_output.put_line('    CASE condition = ' || inter_openm2_open5.getCaseCondition('MYVAR'));
  
  inter_closedm2_closed6 := CRITINTERV('Z',-2,'Z',6);
  dbms_output.put_line('inter_closedm2_closed6 = ' || inter_closedm2_closed6.toString());
  dbms_output.put_line('        CASE condition = ' || inter_closedm2_closed6.getCaseCondition('MYVAR'));
  
  dbms_output.put_line('UNIT TESTS / TYPE CRITINTERV   -- END');
end;
/
/*** TYPE CRITINTERV  -- END ***/

/*** TYPE CRITPLACE  -- START ***/
/*        (critValue , critInterval)*/
declare
  cp1 CRITPLACE;
  cp2 CRITPLACE;
  cp3 CRITPLACE;
  cp4 CRITPLACE;
  
  str varchar(1000);
begin
  dbms_output.put_line('UNIT TESTS / TYPE CRITPLACE   -- START');
  
  cp1 := CRITPLACE(3, CRITINTERV('N',-2,'N',5));
  dbms_output.put_line('cp1 = ' || cp1.toString());
  begin str := cp1.getCaseCondition('MYVAR'); exception when others then str := 'cp1: ERROR '; end;
  dbms_output.put_line('   CASE condition = ' || str);
  
  cp2 := CRITPLACE(null,null);
  dbms_output.put_line('cp2 = ' || cp2.toString());
  begin str := cp2.getCaseCondition('MYVAR'); exception when others then str := 'cp2: ERROR '; end;
  dbms_output.put_line('   CASE condition = ' || str);
  
  
  cp3 := CRITPLACE(3,null);
  dbms_output.put_line('cp3 = ' || cp3.toString());
  begin str := cp3.getCaseCondition('MYVAR'); exception when others then str := 'cp3: ERROR '; end;
  dbms_output.put_line('   CASE condition = ' || str);
  
  
  cp4 := CRITPLACE(null, CRITINTERV('N',-2,'N',5));
  dbms_output.put_line('cp4 = ' || cp4.toString());
  begin str := cp4.getCaseCondition('MYVAR'); exception when others then str := 'cp4: ERROR '; end;
  dbms_output.put_line('   CASE condition = ' || str);
  
  dbms_output.put_line('UNIT TESTS / TYPE CRITPLACE   -- END');
end;
/
/*** TYPE CRITPLACE  -- END ***/

/*** TYPE SYMBOL  -- START ***/
/*        (literal , simboltype, argNum, criticalArgs, precedence, simbollevel)*/
declare
  symProd SYMBOL;
  symAdd SYMBOL;
  symDiv SYMBOL;
  symPow SYMBOL;
  symObr SYMBOL;
  symLN SYMBOL;
  symVar SYMBOL;
  
  function symToString(sym in SYMBOL) return varchar is
  begin
    if(sym is null) then return 'NULL'; end if;
    return sym.literal || ' -> type=' || sym.getType() || ', argNum=' || sym.getArgNum() || ', critArgNum=' || sym.getCriticalArgNum();
  end;
  
begin
  dbms_output.put_line('UNIT TESTS / TYPE SYMBOL   -- START');
  
  symProd := SYMBOL('*','I',2,null,1,0);
  dbms_output.put_line('symProd = ' || symToString(symProd) );
  
  symAdd := SYMBOL('+','I',2,null,0,0);
  dbms_output.put_line('symAdd = ' || symToString(symAdd) );
  
  symDiv := SYMBOL('/','I',2,VARR_POS_CRITPLACE(POS_CRITPLACE(2,CRITPLACE(0,null)) ) ,2,null);
  dbms_output.put_line('symDiv = ' || symToString(symDiv) );
  
  symPow := SYMBOL('**','I',2,null,2,0);
  dbms_output.put_line('symPow = ' || symToString(symPow) );
  
  symObr := SYMBOL('(','N',0,null,0,null);
  dbms_output.put_line('symObr = ' || symToString(symObr) );
  
  symLN := SYMBOL('LN','F',1,VARR_POS_CRITPLACE(POS_CRITPLACE(1,CRITPLACE(null,CRITINTERV('V',null,'Z',0))) ) ,3,null);
  dbms_output.put_line('symLN = ' || symToString(symLN) );
  
  symVar := SYMBOL('a3','V',0,null,0,0);
  dbms_output.put_line('symVar = ' || symToString(symVar) );
  
  dbms_output.put_line('UNIT TESTS / TYPE SYMBOL   -- END');
end;
/
/*** TYPE SYMBOL  -- END ***/

/*** TYPE SYMBOLSTACK  -- START ***/
/*        (strictErrorHandling , stackErrCode , position , maximalSize , top)*/
declare
  stack SYMBOLSTACK;
  sa1 SYMBOL;
  sdv SYMBOL;
  sln SYMBOL;
  sob SYMBOL;
  sb1 SYMBOL;
  sad SYMBOL;
  sb2 SYMBOL;
  scb SYMBOL;
  
  sym SYMBOL;
  
  str varchar2(1000);
  
  function symToString(sym in SYMBOL) return varchar is
  begin
    if(sym is null) then return 'NULL'; end if;
    return sym.literal || ' -> type=' || sym.getType() || ', argNum=' || sym.getArgNum() || ', critArgNum=' || sym.getCriticalArgNum();
  end;
  
begin
  dbms_output.put_line('UNIT TESTS / TYPE SYMBOLSTACK   -- START');
  
  sa1 := SYMBOL('a1','V',0,null,0,0);
  sdv := SYMBOL('/','I',2,VARR_POS_CRITPLACE(POS_CRITPLACE(2,CRITPLACE(0,null)) ) ,2,null);
  sln := SYMBOL('LN','F',1,VARR_POS_CRITPLACE(POS_CRITPLACE(1,CRITPLACE(null,CRITINTERV('V',null,'Z',0))) ) ,3,null);
  sob := SYMBOL('(','N',0,null,0,null);
  sb1 := SYMBOL('b1','V',0,null,0,0);
  sad := SYMBOL('+','I',2,null,0,0);
  sb2 := SYMBOL('b2','V',0,null,0,0);
  scb := SYMBOL(')','Z',0,null,0,null);
  
  --STRICT error handling
  dbms_output.put_line('-- STRICT error handling');
  stack := SYMBOLSTACK(1,0,null,0,0);
  stack.initialize();
  begin
    sym := stack.getTop();
    dbms_output.put_line('   top of empty stack=' || symToString(sym));
  exception when others then
    dbms_output.put_line('   top of empty stack :: error=' || SQLERRM);
  end;
  
  --LOOSE error handling
  dbms_output.put_line('-- LOOSE error handling');
  stack := SYMBOLSTACK(0,0,null,0,0);
  stack.initialize();
  begin
    sym := stack.getTop();
    dbms_output.put_line('   top of empty stack=' || symToString(sym));
  exception when others then
    dbms_output.put_line('   top of empty stack :: error=' || SQLERRM);
  end;
  
  stack.push(sa1);
  dbms_output.put_line('   pushed: ' || sa1.literal);
  dbms_output.put_line('   isEmpty=' || (CASE stack.isEmpty() when true then 'Yes' ELSE 'No' END));
  sym := stack.getTop();
  dbms_output.put_line('   top of stack=' || symToString(sym));
  stack.pop(sym);
  dbms_output.put_line('   pop stack=' || symToString(sym));
  dbms_output.put_line('   isEmpty=' || (CASE stack.isEmpty() when true then 'Yes' ELSE 'No' END));
  
  dbms_output.put_line('-- insert some formula');
  stack.push(sa1);
  stack.push(sdv);
  stack.push(sln);
  stack.push(sob);
  stack.push(sb1);
  stack.push(sad);
  stack.push(sb2);
  stack.push(scb);
  dbms_output.put_line('   stack=' || stack.toString());
  str := '';
  while(not stack.isEmpty()) loop
    stack.pop(sym);
    str := sym.literal || str;
  end loop;
  dbms_output.put_line('   formula reconstructed=' || str);
  
  dbms_output.put_line('UNIT TESTS / TYPE SYMBOLSTACK   -- END');
end;
/
/*** TYPE SYMBOLSTACK  -- END ***/


/*** TYPE FORMULAPART  -- START ***/
declare
  sarr VARR_SYMBOL;
  fpart FORMULAPART;
  
  function VarrSymbolToString(vs in VARR_SYMBOL) return varchar is
    ret varchar(1000);
    sym SYMBOL;
    idx number;
  begin
    if(vs is null) then
      return 'NULL';
    elsif(vs.count = 0) then
      return 'EMPTY';
    else
      idx := vs.FIRST;
      ret := vs(vs.FIRST).literal;
      idx := vs.next(idx);
      while idx is not null loop
        ret := trim(ret) || ';' || trim(vs(idx).literal );
        idx := vs.next(idx);
      end loop;
      return ret;
    end if;
  end;
  
begin
  dbms_output.put_line('UNIT TESTS / TYPE FORMULAPART   -- START');
  
  sarr := VARR_SYMBOL();
  sarr.extend(); sarr(sarr.last) := SYMBOL('b1','V',0,null,0,0);
  sarr.extend(); sarr(sarr.last) := SYMBOL('+','I',2,null,0,0);
  sarr.extend(); sarr(sarr.last) := SYMBOL('b2','V',0,null,0,0);
  dbms_output.put_line('  sarr=' || VarrSymbolToString(sarr) );
  
  fpart := FORMULAPART(sarr);
  dbms_output.put_line('  fpart=' || fpart.toString() );
  
  dbms_output.put_line('UNIT TESTS / TYPE FORMULAPART   -- END');
end;
/
/*** TYPE FORMULAPART  -- END ***/

/*** TYPE FORMULA  -- START ***/
declare
  sa1 SYMBOL;
  sdv SYMBOL;
  sln SYMBOL;
  sob SYMBOL;
  sb1 SYMBOL;
  sad SYMBOL;
  sb2 SYMBOL;
  scb SYMBOL;
  
  sarr VARR_SYMBOL;
  
  fmain FORMULAPART;  
  form1 FORMULA;
begin
  dbms_output.put_line('UNIT TESTS / TYPE FORMULA   -- START');
    
  sa1 := SYMBOL('a1','V',0,null,0,0);
  sdv := SYMBOL('/','I',2,VARR_POS_CRITPLACE(POS_CRITPLACE(2,CRITPLACE(0,null)) ) ,2,null);
  sln := SYMBOL('LN','F',1,VARR_POS_CRITPLACE(POS_CRITPLACE(1,CRITPLACE(null,CRITINTERV('V',null,'Z',0))) ) ,3,null);
  sob := SYMBOL('(','N',0,null,0,null);
  sb1 := SYMBOL('b1','V',0,null,0,0);
  sad := SYMBOL('+','I',2,null,0,0);
  sb2 := SYMBOL('b2','V',0,null,0,0);
  scb := SYMBOL(')','Z',0,null,0,null);
  
  sarr := VARR_SYMBOL();
  sarr.extend(); sarr(sarr.last) := sa1;
  sarr.extend(); sarr(sarr.last) := sdv;
  sarr.extend(); sarr(sarr.last) := sln;
  sarr.extend(); sarr(sarr.last) := sob;
  sarr.extend(); sarr(sarr.last) := sb1;
  sarr.extend(); sarr(sarr.last) := sad;
  sarr.extend(); sarr(sarr.last) := sb2;
  sarr.extend(); sarr(sarr.last) := scb;
  
  fmain := FORMULAPART(sarr);
  form1 := FORMULA(fmain, null);
  
  dbms_output.put_line('fmain original=' || fmain.toString() );
  dbms_output.put_line('fmain polish=' || form1.getPolishForm(fmain).toString() );
  
  form1.createCritPlaces;
  dbms_output.put_line('fmain crit places=' || form1.critPlacesToString() );
  
  dbms_output.put_line('fmain safe formula=' || form1.getSafeFormula() );
  
  dbms_output.put_line('UNIT TESTS / TYPE FORMULA   -- END');
end;
/
/*** TYPE FORMULA  -- END ***/

/*** TYPE LEXER_SYMBOLTABLE  -- START ***/
declare
  lst LEXER_SYMBOLTABLE;
  
  function symToString(sym in SYMBOL) return varchar is
  begin
    if(sym is null) then return 'NULL'; end if;
    return sym.literal || ' -> type=' || sym.getType() || ', argNum=' || sym.getArgNum() || ', critArgNum=' || sym.getCriticalArgNum();
  end;
  
begin
  dbms_output.put_line('UNIT TESTS / TYPE LEXER_SYMBOLTABLE   -- START');
  
  dbms_output.put_line('Built-in intitialization');
  lst := LEXER_SYMBOLTABLE(null);
  lst.initialize();
  dbms_output.put_line('  opening bracket: ' || symToString(lst.getSymbol('(')) );
  dbms_output.put_line('  closing bracket: ' || symToString(lst.getSymbol(')')) );
  dbms_output.put_line('  addition: ' || symToString(lst.getSymbol('+')) );
  dbms_output.put_line('  multiplication: ' || symToString(lst.getSymbol('*')) );
  dbms_output.put_line('  division: ' || symToString(lst.getSymbol('/')) );
  dbms_output.put_line('  log: ' || symToString(lst.getSymbol('ln')) );
  dbms_output.put_line('  power: ' || symToString(lst.getSymbol('^')) );
  dbms_output.put_line('  nonexistent: ' || symToString(lst.getSymbol('abc*/-')) );
  dbms_output.put_line('-----');
  
  dbms_output.put_line('Intitialization from DB tables');
  lst := LEXER_SYMBOLTABLE(null);
  lst.initFromTables('PAR_SYMBOLTABLE'
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
  dbms_output.put_line('  opening bracket: ' || symToString(lst.getSymbol('(')) );
  dbms_output.put_line('  closing bracket: ' || symToString(lst.getSymbol(')')) );
  dbms_output.put_line('  addition: ' || symToString(lst.getSymbol('+')) );
  dbms_output.put_line('  multiplication: ' || symToString(lst.getSymbol('*')) );
  dbms_output.put_line('  division: ' || symToString(lst.getSymbol('/')) );
  dbms_output.put_line('  log: ' || symToString(lst.getSymbol('ln')) );
  dbms_output.put_line('  power: ' || symToString(lst.getSymbol('^')) );
  dbms_output.put_line('  nonexistent: ' || symToString(lst.getSymbol('abc*/-')) );
  
  dbms_output.put_line('UNIT TESTS / TYPE LEXER_SYMBOLTABLE   -- END');
end;
/
/*** TYPE LEXER_SYMBOLTABLE  -- END ***/

/*** TYPE LEXER  -- START ***/
declare
  lexi LEXER;
  cTable LEXER_CHARCLASS := LEXER_CHARCLASS(null,null,null,null,null,null,null);
  sTable LEXER_SYMBOLTABLE := LEXER_SYMBOLTABLE(null);
  lexFormula FORMULA;
  
  sFrm varchar2(1000);
  idx integer;
  lexSymb varchar2(200);
  lexComponent varchar2(500);
begin
  dbms_output.put_line('UNIT TESTS / TYPE LEXER   -- START');

  cTable.initialize;
  sTable.initialize;
  lexi := LEXER(null,null,null,cTable,sTable);
  
  sFrm := '[ALPHA] / LN ( [BETA] + [GAMMA] )';
  lexi.processFormulaID(sFrm);
  dbms_output.put_line('Formula original: ' || sFrm);
  dbms_output.put_line('   abstract formula: ' || lexi.formula_part.toString());
  lexFormula := FORMULA(lexi.formula_part,null);
  lexFormula.createCritPlaces;
  dbms_output.put_line('   safe formula: ' || lexFormula.getSafeFormula());
  dbms_output.put_line('   replacements:');
  idx := lexi.formulaID_to_aSymb.FIRST;
  while(idx is not null) loop
    lexSymb := lexi.formulaID_to_aSymb(idx).mutato_azonosito;
    lexComponent := lexi.formulaID_to_aSymb(idx).absztrakt_szimbolum.literal;
    dbms_output.put_line('     ' || lexSymb || ' -> ' || lexComponent);
    idx := lexi.formulaID_to_aSymb.next(idx);
  end loop;
  
  
  dbms_output.put_line('-- -- --');
  
  sFrm := 'LN([a]/[b]+[c]/[d])/([e]*[f]-[g])';
  lexi.processFormulaID(sFrm);
  dbms_output.put_line('Formula original: ' || sFrm);
  dbms_output.put_line('   abstract formula: ' || lexi.formula_part.toString());
  lexFormula := FORMULA(lexi.formula_part,null);
  lexFormula.createCritPlaces;
  dbms_output.put_line('   safe formula: ' || lexFormula.getSafeFormula());
  dbms_output.put_line('   replacements:');
  idx := lexi.formulaID_to_aSymb.FIRST;
  while(idx is not null) loop
    lexSymb := lexi.formulaID_to_aSymb(idx).mutato_azonosito;
    lexComponent := lexi.formulaID_to_aSymb(idx).absztrakt_szimbolum.literal;
    dbms_output.put_line('     ' || lexSymb || ' -> ' || lexComponent);
    idx := lexi.formulaID_to_aSymb.next(idx);
  end loop;
  
  dbms_output.put_line('UNIT TESTS / TYPE LEXER   -- END');
end;
/
/*** TYPE LEXER  -- END ***/

/*** TYPE template  -- START ***/
declare
begin
  dbms_output.put_line('UNIT TESTS / TYPE template   -- START');
  
  
  
  dbms_output.put_line('UNIT TESTS / TYPE template   -- END');
end;
/
/*** TYPE template  -- END ***/