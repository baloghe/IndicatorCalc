SET FEEDBACK OFF

WHENEVER SQLERROR EXIT 1


/****  DROP   -- START ****/
DECLARE
  --error types
  obj_not_exists EXCEPTION;
  PRAGMA EXCEPTION_INIT(obj_not_exists, -4043);
  
  --other vars
  sqlStr varchar2(10000);
  errStr varchar2(100);
  cmdStr varchar2(1000);
   
  TYPE curTp IS REF CURSOR;
  cTask  curTp;
BEGIN
  sqlStr := 'select errStr, cmdStr from (
          select 1 as ord, ''obj_not_exists'' as errStr,''DROP TYPE LEXER'' as cmdStr from dual
    union select 2,''obj_not_exists'',''DROP TYPE LEXER_SYMBOLTABLE'' from dual
    union select 3,''obj_not_exists'',''DROP TYPE VARR_CHAR_SYMBOL'' from dual
    union select 4,''obj_not_exists'',''DROP TYPE CHAR_SYMBOL'' from dual
    union select 5,''obj_not_exists'',''DROP TYPE LEXER_CHARCLASS'' from dual
    union select 6,''obj_not_exists'',''DROP TYPE VARR_FORMULA_SYMB'' from dual
    union select 7,''obj_not_exists'',''DROP TYPE FORMULA_SYMB'' from dual
    union select 8,''obj_not_exists'',''DROP TYPE FORMULA'' from dual
    union select 9,''obj_not_exists'',''DROP TYPE VARR_SYMBOL_CRITPLACE'' from dual
    union select 10,''obj_not_exists'',''DROP TYPE SYMBOL_CRITPLACE'' from dual
    union select 11,''obj_not_exists'',''DROP TYPE FORMULAPART'' from dual
    union select 12,''obj_not_exists'',''DROP TYPE SYMBOLSTACK'' from dual
    union select 13,''obj_not_exists'',''DROP TYPE VARR_SYMBOL'' from dual
    union select 14,''obj_not_exists'',''DROP TYPE SYMBOL'' from dual
    union select 15,''obj_not_exists'',''DROP TYPE VARR_POS_CRITPLACE'' from dual
    union select 16,''obj_not_exists'',''DROP TYPE POS_CRITPLACE'' from dual
    union select 17,''obj_not_exists'',''DROP TYPE CRITPLACE'' from dual
    union select 18,''obj_not_exists'',''DROP TYPE CRITINTERV'' from dual
    ) order by ord';
  OPEN cTask FOR sqlStr
        ;
  LOOP
    FETCH cTask INTO errStr, cmdStr;
    EXIT WHEN cTask%notfound;
    
    if(errStr = 'obj_not_exists') then
      begin 
        execute immediate cmdStr;
      exception when obj_not_exists then
        dbms_output.put_line('obj_not_exists: ' || cmdStr);
      end;
    else
      dbms_output.put_line('ERROR: INVALID ERRSTR: ' || errStr || '  -->>  ' || cmdStr);
    end if;
  END LOOP;
END;
/

/****  DROP   -- END ****/



/****  CREATE   -- START ****/

/* TYPE CRITINTERV  -- START */
CREATE OR REPLACE TYPE CRITINTERV AUTHID CURRENT_USER IS OBJECT(
   lowerBarrierType char(1)   -- 'Z': alulr�l z�rt, 'N': alulr�l ny�lt korl�tos, 'V': alulr�l korl�tlan intervallum
  ,lowerBarrierValue number    -- lowerBarrierType in ('Z','N') eset�n �rtelmes
  ,upperBarrierType char(1)   -- 'Z': fel�lr�l z�rt, 'N': fel�lr�l ny�lt korl�tos, 'V': fel�lr�l korl�tlan intervallum
  ,upperBarrierValue number    -- upperBarrierType in ('Z','N') eset�n �rtelmes
  
  ,MEMBER FUNCTION toString RETURN VARCHAR2
  ,MEMBER FUNCTION getCaseCondition(varvar IN varchar2) RETURN VARCHAR2
);
/

CREATE OR REPLACE TYPE BODY CRITINTERV AS
  MEMBER FUNCTION toString RETURN VARCHAR2 IS
      ak varchar2(20);
      fk varchar2(20);
    BEGIN
      if lowerBarrierType is null then return 'lowerBarrierType NULL'; end if;
      if upperBarrierType is null then return 'upperBarrierType NULL'; end if;
      /*als�*/
      if(lowerBarrierType = 'V') then ak := '(-inf';
      else
        if(lowerBarrierValue is null) then return 'LowerBarrier NULL'; end if;
        if(lowerBarrierType = 'Z') then ak := '[';
        else ak := '(';
        end if;
        ak := trim(ak) || lowerBarrierValue;
      end if;
      /*fels�*/
      if(upperBarrierType = 'V') then fk := 'inf)';
      else
        if(upperBarrierValue is null) then return 'UpperBarrier NULL'; end if;
        if(upperBarrierType = 'Z') then fk := ']';
        else fk := ')';
        end if;
        fk := upperBarrierValue || trim(fk);
      end if;
      /*return*/
      return trim(ak) || ' , ' || trim(fk);
    END toString;
    
    MEMBER FUNCTION getCaseCondition(varvar IN varchar2) RETURN VARCHAR2 IS
        ak varchar2(1000);
        fk varchar2(1000);
      BEGIN
        /* hib�s t�lt�s eset�n NULL-t adunk vissza */
        if(lowerBarrierType is null or upperBarrierType is null) then return null;
        else
          if(lowerBarrierType != 'V' and lowerBarrierValue is null) then return null; end if;
          if(upperBarrierType != 'V' and upperBarrierValue is null) then return null; end if;
        end if;
        /* akkor a korl�t defin�ci�k helyesek. Ha mindk�t korl�t v�gtelen, akkor TRUE-t adunk vissza */
        if(lowerBarrierType = 'V' and upperBarrierType = 'V') then return ' TRUE '; end if;
        /* egy�bk�nt meg sz�molunk... */
        ak := '';
        fk := '';
        if(upperBarrierType != 'V') then -- fels� korl�t (kiv�ve v�gtelen)
          if(upperBarrierType = 'N') then 
            fk := '(' || varvar || ' < ' || upperBarrierValue || ')';
          else fk := '(' || varvar || ' <= ' || upperBarrierValue || ')';
          end if;
        end if;
        if(lowerBarrierType != 'V') then -- als� korl�t (kiv�ve v�gtelen)
          if(lowerBarrierType = 'N') then
            ak := '(' || varvar || ' > ' || lowerBarrierValue || ')';
          else ak := '(' || varvar || ' >= ' || lowerBarrierValue || ')';
          end if;
        end if;
        /* mit adjunk vissza...? */
        if(lowerBarrierType = 'V') then -- alulr�l v�gtelen, fel�lr�l korl�tos
          return fk;
        elsif(upperBarrierType = 'V') then -- fel�lr�l v�gtelen, alulr�l korl�tos
          return ak;
        else -- mindk�t ir�nyb�l korl�tos
          return '(' || ak || ' AND ' || fk || ')';
        end if;
      END getCaseCondition;
END;
/
/* TYPE CRITINTERV  -- END */

/* TYPE CRITPLACE  -- START */
CREATE OR REPLACE TYPE CRITPLACE AUTHID CURRENT_USER IS OBJECT(
   critValue number           -- kritikus �rt�k (pl. oszt�sn�l a nevez� eset�n 0)
  ,critInterval CRITINTERV  -- poz�ci�hoz tartoz� kritikus intervallum (pl. LN(x) eset�n x <= 0)
  
  ,MEMBER FUNCTION toString RETURN VARCHAR2
  ,MEMBER FUNCTION getCaseCondition(varvar IN varchar2) RETURN VARCHAR2
);
/

CREATE OR REPLACE TYPE BODY CRITPLACE AS
  MEMBER FUNCTION toString RETURN VARCHAR2 IS
    BEGIN
      if(critValue is not null and critInterval is not null) then return 'Critical place and interval at the same time!!'; end if;
      if(critValue is null and critInterval is null) then return 'NULL'; end if;
      if(critValue is not null) then return critValue; end if;
      if(critInterval is not null) then return critInterval.toString(); end if;
      return 'other error!';
    END toString;
    
  MEMBER FUNCTION getCaseCondition(varvar IN varchar2) RETURN VARCHAR2 IS
    BEGIN
      if(critValue is not null) then 
        return '(' || varvar || ' = ' || critValue || ')'; 
      else 
        return critInterval.getCaseCondition(varvar);
      end if;
    END;
END;
/
/* TYPE CRITPLACE  -- END */

/* TYPE POS_CRITPLACE  -- START */
CREATE OR REPLACE TYPE POS_CRITPLACE AUTHID CURRENT_USER IS OBJECT(
   position number       -- m�velet argumentum�nak poz�ci�ja (pl. LN(x) eset�n az egyetlen (1.) argumentum)
  ,crit_place CRITPLACE  -- kapcsol�d� kritikus hely
);
/
/* TYPE POS_CRITPLACE  -- END */

/* TYPE VARR_POS_CRITPLACE  -- START */
CREATE OR REPLACE TYPE VARR_POS_CRITPLACE IS VARRAY(100) OF POS_CRITPLACE;
/
/* TYPE VARR_POS_CRITPLACE  -- END */

/* innen j�n a szimb�lum... */
/* TYPE SYMBOL  -- START */
CREATE OR REPLACE TYPE SYMBOL AUTHID CURRENT_USER IS OBJECT(
  /**
    
  */
   literal varchar2(1000)
   /* N - Nyit�jel, Z - Z�r�jel, I - Infix M�velet , F - f�ggv�ny, V - V�ltoz�, K - Konstans */
  ,simboltype   varchar2(5)
   /* csak I �s F t�pus eset�n k�l�nb�zik 0-t�l, minden m�s esetben 0 */
  ,argNum  number(10)
   /* csak I �s F t�pus eset�n k�l�nb�zHET ''-t�l, minden m�s esetben '' */
   /* v02 TBD: ehelyett VARR_POZICIO_KRITIKUSERTEK_PAR kellene + kapcsol�d� toString(), add() funkci�... */
  ,criticalArgs VARR_POS_CRITPLACE
  /* oper�tor precedencia: akinek magasabb, az "nyer", �rtelme csak I vagy F eset�n van */
  ,precedence integer
  /* szimb�lum szintje a k�plet fastrukt�r�s �br�zol�s�ban -> csak FORMULA haszn�lja!! */
  ,simbollevel integer
  
  
  ,MEMBER FUNCTION getType RETURN VARCHAR2
  ,MEMBER FUNCTION getArgNum RETURN NUMBER
  
  ,MEMBER FUNCTION getCriticalArgNum RETURN NUMBER
  
  /* v02: visszat�r�si �rt�k megv�ltozott */
  ,MEMBER FUNCTION getCriticalArgs RETURN VARR_POS_CRITPLACE
);
/

CREATE OR REPLACE TYPE BODY SYMBOL AS
  /**/
  MEMBER FUNCTION getType RETURN VARCHAR2 IS
    BEGIN
      return trim(upper(simboltype));
    END getType;
    
  /**/
  MEMBER FUNCTION getArgNum RETURN NUMBER IS
    BEGIN
      return argNum;
    END getArgNum;
    
  /**/
  MEMBER FUNCTION getCriticalArgs RETURN VARR_POS_CRITPLACE IS
    BEGIN
      if(getType() != 'I' and getType() != 'F' ) then
        return null;
      else return criticalArgs;
      end if;
    END getCriticalArgs;
    
  /* new v02 */
  MEMBER FUNCTION getCriticalArgNum RETURN NUMBER IS
      idx number;
      cntr number;
    BEGIN
      if(criticalArgs is NULL or (getType != 'I' and getType != 'F') ) then
        return 0;
      else
        cntr := 0;
        idx := criticalArgs.FIRST;
        while idx is not null loop
          cntr := cntr + 1;
          idx := criticalArgs.NEXT(idx);
        end loop;
        return cntr;
      end if;
    END getCriticalArgNum;
END;
/
/* TYPE SYMBOL  -- END */

/* TYPE VARR_SYMBOL  -- START */
CREATE OR REPLACE TYPE VARR_SYMBOL IS VARRAY(100) OF SYMBOL;
/
/* TYPE VARR_SYMBOL  -- END */

/* TYPE SYMBOLSTACK  -- START */
/* SOURCE: http://blog.serpland.com/oracle/plsql-integer-stack-with-object-types */
CREATE OR REPLACE TYPE SYMBOLSTACK AUTHID CURRENT_USER IS OBJECT(
   strictErrorHandling NUMBER   -- !=0: RAISE-zel hib�t dobunk, le�llunk; 0: error-t logolunk, NULL-t adunk vissza
  ,stackErrCode integer         -- alapvet�en 0, de utols� m�velet hib�ja eset�n: 1 - Overflow, 2 - Empty stack (top/pop)
  ,position VARR_SYMBOL  -- bels� v�ltoz�, k�v�lr�l nem haszn�land�
  ,maximalSize INTEGER          -- bels� v�ltoz�, k�v�lr�l nem haszn�land�
  ,top INTEGER                  -- bels� v�ltoz�, k�v�lr�l nem haszn�land�
  
  ,MEMBER PROCEDURE initialize
  ,MEMBER FUNCTION isFull RETURN BOOLEAN
  ,MEMBER FUNCTION isEmpty RETURN BOOLEAN
  ,MEMBER FUNCTION getCount RETURN INTEGER
  ,MEMBER PROCEDURE push (szim IN SYMBOL)
  ,MEMBER PROCEDURE pop (szim OUT SYMBOL)
  ,MEMBER FUNCTION getTop RETURN SYMBOL
  
  ,MEMBER FUNCTION toString RETURN VARCHAR2
);
/

CREATE OR REPLACE TYPE BODY SYMBOLSTACK AS
  /**/
  MEMBER PROCEDURE initialize IS
    BEGIN
      top := 0;
      stackErrCode := 0;
      -- Call Constructor und set element 1 to NULL
      position := VARR_SYMBOL(NULL);
      maximalSize := position.LIMIT; -- Get Varray Size
      position.EXTEND(maximalSize -1, 1); -- copy elements 1 in 2..100
    END initialize;
  
  MEMBER FUNCTION isFull RETURN BOOLEAN IS
    BEGIN
      --stackErrCode := 0;
      RETURN (top = maximalSize); -- Return TRUE when Stack is full
    END isFull;
    
  MEMBER FUNCTION isEmpty RETURN BOOLEAN IS
    BEGIN
      --stackErrCode := 0;
      RETURN (top = 0); -- Return TRUE when Stack is empty
    END isEmpty;
    
  MEMBER FUNCTION getCount RETURN INTEGER IS
    BEGIN
      --stackErrCode := 0;
      IF top is null then 
        return 0;
      else 
        RETURN top;
      end if;
    END;
    
  MEMBER PROCEDURE push (szim IN SYMBOL) IS
    BEGIN
      stackErrCode := 0;
      IF NOT isFull THEN
        top := top + 1; -- Push Integer onto the stack
        position(top) := szim;
      ELSE
        --Stack is full!
        stackErrCode := 1;
        if(strictErrorHandling != 0) then
          RAISE_APPLICATION_ERROR(-20101, 'Error! Stack overflow. '
            ||'limit for stacksize reached.');
        end if;
      END IF;
    END push;
    
  MEMBER PROCEDURE pop (szim OUT SYMBOL) IS
    BEGIN
      stackErrCode := 0;
      IF NOT isEmpty THEN
        szim := position(top);
        top := top -1; -- take top element from stack
      ELSE
        --no element in stack!
        stackErrCode := 2;
        szim := null;
        if(strictErrorHandling != 0) then
          RAISE_APPLICATION_ERROR(-20102, 'Error! No element to pop. '
            ||'stack is empty.');
        end if;
      END IF;
    END pop;
    
  MEMBER FUNCTION getTop RETURN SYMBOL IS
    BEGIN
      --stackErrCode := 0;
      IF NOT isEmpty THEN
--        --BaE_UTIL.logStr('SzimbVerem.getTop :: top=' || top);
        return position(top);
      ELSE
        --no element in stack!
        if(strictErrorHandling != 0) then
          RAISE_APPLICATION_ERROR(-20102, 'Error! No element on top. '
            ||'stack is empty.');
        end if;
        return null;
      END IF;
    END getTop;
    
  MEMBER FUNCTION toString RETURN VARCHAR2 IS
      ret VARCHAR2(1000);
      idx NUMBER;
    BEGIN
      ret := '';
      idx := position.FIRST;
      while idx <= top loop
        ret := trim(position(idx).literal) || ';' || trim(ret);
        idx := position.NEXT(idx);
      end loop;
      return '[' || trim(ret) || ']';
    END;
END;
/
/* TYPE SYMBOLSTACK  -- END */



/* TYPE FORMULAPART  -- START */
CREATE OR REPLACE TYPE FORMULAPART AUTHID CURRENT_USER IS OBJECT(
   symbSeries VARR_SYMBOL
  ,MEMBER FUNCTION toString RETURN VARCHAR2  
);
/

CREATE OR REPLACE TYPE BODY FORMULAPART AS

  /**/
  MEMBER FUNCTION toString RETURN VARCHAR2 IS
      idx number;
      ret varchar2(1000);
    BEGIN
      idx := symbSeries.FIRST;
      ret := '';
      while idx is not null loop
        -- normal:
        ret := trim(ret) || trim(symbSeries(idx).literal );
        -- debug:
        --ret := trim(ret) || '[' || trim(symbSeries(idx).literal) || ' :: ' ||  trim(symbSeries(idx).simboltype) || ']';
        idx := symbSeries.NEXT(idx);
      end loop;
      return ret;
    END toString;
END;
/
/* TYPE FORMULAPART  -- END */


/* TYPE SYMBOL_CRITPLACE  -- START */
/* l�nyeg: {r�szk�plet 'V' t�pus� szimb�lumk�nt ; Kritikus hely} p�r */
CREATE OR REPLACE TYPE SYMBOL_CRITPLACE AUTHID CURRENT_USER IS OBJECT(
   symb SYMBOL     -- szimb�lum
  ,crit_place CRITPLACE   -- kritikus hely
);
/
/* TYPE SYMBOL_CRITPLACE  -- END */

/* TYPE VARR_SYMBOL_CRITPLACE  -- START */
/* l�nyeg: {R�szk�plet ; Kritikus �rt�k} p�rok sorozata */
CREATE OR REPLACE TYPE VARR_SYMBOL_CRITPLACE IS VARRAY(100) OF SYMBOL_CRITPLACE;
/
/* TYPE VARR_SYMBOL_CRITPLACE  -- END */

/* TYPE FORMULA  -- START */
CREATE OR REPLACE TYPE FORMULA AUTHID CURRENT_USER IS OBJECT(
   mainFormula FORMULAPART
  ,critPlaces VARR_SYMBOL_CRITPLACE
  
  /* p�ld�nyos�t�s ut�n futtatand�: a f�k�plet lengyelform�ra hoz�sa �s lengyelforma ki�rt�kel�se alapj�n 
    azonos�tja a kritikus r�szk�pleteket, �s az ezekhez tartoz� kritikus �rt�keket */
  ,MEMBER PROCEDURE createCritPlaces 
  
  /* lengyelform�ra hoz�s, h�vja: kritikusErtekeketEloallit */
  ,MEMBER FUNCTION getPolishForm(FORMULA IN FORMULAPART) RETURN FORMULAPART
  
  /* critPlaces string-g� konvert�l�sa, els�sorban tesztel�shez */
  ,MEMBER FUNCTION critPlacesToString RETURN VARCHAR2
  
  /* fastrukt�r�ban elhelyezked� m�velet eredm�nyk�pp l�trehozott szimb�lum fastrukt�rabeli szintje */
  ,MEMBER FUNCTION getNewLevel(s1 IN SYMBOL, s2 IN SYMBOL) RETURN INTEGER
  /* seg�dfv. getNewLevel kisz�m�t�s�hoz: NULL szimb�lum �s nemNull szimb�lum NULL szintj�re 0-t ad,
     k�l�nben a szimb�lum szintj�t */
  ,MEMBER FUNCTION getSafeSymbolLevel(s IN SYMBOL) RETURN INTEGER
  
  /* visszaadja a k�plethez tartoz� (CASE WHEN THEN END) sz�veget, ami m�r kezeli a kritikus �rt�keket �s intervallumokat */
  ,MEMBER FUNCTION getSafeFormula RETURN VARCHAR2
  /* seg�dfv. getSafeFormula kisz�m�t�s�hoz: kritikus helyeket fastrukt�ra-beli szintj�k szerint rendezetten 
     sorolja fel, OR-ral elv�lasztva */
  ,MEMBER FUNCTION enumCritPlaces RETURN VARCHAR2
);
/

CREATE OR REPLACE TYPE BODY FORMULA AS
  /**/
  MEMBER FUNCTION getPolishForm(FORMULA IN FORMULAPART) RETURN FORMULAPART IS
      sStack SYMBOLSTACK;  -- lengyelform�ra hoz�shoz felhaszn�lt verem
      ret VARR_SYMBOL;     -- lengyelforma egy szimb�lumsorozat lesz
      errStr VARCHAR2(1000);          -- hiba
      idx integer;                    -- k�plet aktu�lis szimb�lum�ra mutat� pointer
      tmps SYMBOL;         -- verem m�veletek sor�n haszn�lt szimb�lum
      lastRead SYMBOL;     -- inputr�l (=k�pletb�l) utolj�ra olvasott szimb�lum
      tmps2 SYMBOL;        -- verem m�veletek sor�n haszn�lt szimb�lum (m�sik)
    BEGIN
      /* ha nincs k�plet, nem dolgozunk */
      if(FORMULA is null) then 
        ----BaE_UTIL.logStr('FORMULA.getPolishForm() :: FORMULA IS NULL');
        return null;
      else
        /* egy�bk�nt hajr�... */
        sStack := SYMBOLSTACK(1,null,null,null,null);
        sStack.initialize;
        ret := VARR_SYMBOL(); -- ret := VARR_SZIMB(null);
        idx := FORMULA.symbSeries.FIRST;
        errStr := '';
--        --BaE_UTIL.logStr('getLF.sStack prep idx=' || idx || ', FORMULA=' || FORMULA.toString());
--        if(errStr != '') then
--          --BaE_UTIL.logStr('getLF.sStack prep ERRSTR NEM �RES!!!');
--        end if;
        while ( (idx is not null) and (errStr is null) ) loop  /* addig olvasunk, am�g a k�plet v�g�re nem �r�nk */
--          --BaE_UTIL.logStr('getLF.sStack ciklusba bel�pt�nk');
          lastRead := FORMULA.symbSeries(idx);
--          if(lastRead is null) then 
--            --BaE_UTIL.logStr('getLF.sStack ciklus idx=' || idx || ', lastRead IS NULL !!!');
--          else
--            --BaE_UTIL.logStr('getLF.sStack ciklus idx=' || idx || ', lastRead=' || lastRead.literal);
--          end if;
          if(lastRead.simboltype = 'V' or lastRead.simboltype = 'K') then /* v�ltoz� vagy konstans: nyom�s az outputra */
            ret.extend;
            ret(ret.LAST) := lastRead;
          elsif(lastRead.simboltype = 'N') then /* nyit�jel minden tov�bbi n�lk�l megy a verembe */
            sStack.push(lastRead);
--            --BaE_UTIL.logStr('getLF.sStack ciklus idx=' || idx || ' AFTER N PUSH tartalom=' || sStack.toString() );
          elsif(lastRead.simboltype = 'Z') then /* z�r�jel: nyit�jellel/f�ggv�nnyel bez�r�lag �r�tj�k a vermet �s outputra �rjuk */
            if(sStack.isEmpty) then /* z�r�jelez�si hiba, ha �res a verem */
              errStr := trim(errStr) || 'zarojelezesi hiba poz=' || idx || '. szimbolumnal: sok csukojel, verem �RES;';
            else
              /* �r�t�nk nyit�jelig/fvjelig, de a nyit�jelet/fvjelet bennhagyjuk a veremben */
              if(not sStack.isEmpty) then -- safe getTop START
                tmps2 := sStack.getTop;
              else tmps2 := null;
              end if;  -- safe getTop END
              while( (not sStack.isEmpty) and tmps2.simboltype != 'N' and tmps2.simboltype != 'F') loop
                sStack.pop(tmps);
                ret.extend;
                ret(ret.LAST) := tmps;
                if(not sStack.isEmpty) then  -- safe getTop START
                  tmps2 := sStack.getTop;
                else tmps2 := null; 
                end if;  -- safe getTop END
              end loop;
              /* utols� jel: ha nyit�jel, nem csin�lunk vele semmit, ha fvjel: megy az outputra */
              if(not sStack.isEmpty) then
                sStack.pop(tmps);
              end if;
              if(tmps.simboltype = 'F') then
                ret.extend;
                ret(ret.LAST) := tmps;
              end if;
            end if;
            /*z�r�jel v�ge*/
          elsif(lastRead.simboltype = 'I') then /* INFIX m�velet: ha a most olvasottn�l nagyobb precedenci�j� jel(ek) van(nak)
                                              a veremben, azokat (legfeljebb nyit�jelig VAGY FVjelig) kipakoljuk �s csak ut�na tessz�k 
                                              be a verembe, amit most olvastunk
                                           */
            if(not sStack.isEmpty) then  -- safe getTop START
              tmps2 := sStack.getTop;
            else tmps2 := null;
            end if;  -- safe getTop END
            while(   (not sStack.isEmpty) and tmps2.simboltype != 'N' and tmps2.simboltype != 'F'
                  and tmps2.precedence > lastRead.precedence   ) loop
              sStack.pop(tmps);
              ret.extend;
              ret(ret.LAST) := tmps;
              if(not sStack.isEmpty) then  -- safe getTop START
                tmps2 := sStack.getTop;
              else tmps2 := null;
              end if;  -- safe getTop END
            end loop;
            /* v�g�l a most olvasott jelet a verem tetej�re dobjuk */
            sStack.push(lastRead);
--            --BaE_UTIL.logStr('getLF.sStack ciklus idx=' || idx || ' AFTER I PUSH tartalom=' || sStack.toString() );
          /* INFIX v�ge */
          elsif(lastRead.simboltype = 'F') then /* F�ggv�ny: Fvjel ut�n nyit�jelet is v�runk, de azt nem tessz�k a verembe! */
            idx := FORMULA.symbSeries.NEXT(idx); -- eggyel tov�bb l�p�nk!
            if( (idx is null) or FORMULA.symbSeries(idx).simboltype != 'N') then /* nyit�jel helyett valami m�s van */
              errStr := trim(errStr) || 'FVjel hiba ' || idx || ' pozicion: Fvjel utan nincs Nyitojel;';
            else
              sStack.push(lastRead);
            end if;
          /* FV v�ge */
          else /* hiba, ilyen nem lehet! */
            errStr := trim(errStr) || 'Ismeretlen SYMBOL ' || idx || ' pozicion;';
          end if; /* lastRead olvas�s -- END */
          idx := FORMULA.symbSeries.NEXT(idx);
--          --BaE_UTIL.logStr('getLF.sStack ' || idx || ', tartalom ciklus v�g�n: ' || sStack.toString() );
        end loop; /* FORMULA olvas�s v�ge */
--        --BaE_UTIL.logStr('getLF.sStack ciklus v�ge');
        /* ha nem volt hiba, �s van m�g valami a veremben, akkor a tartalm�t �r�ts�k az oputputra 
           ha volt hiba, akkor NULL-t adjunk vissza, �s ink�bb �rjuk a hiba sz�veg�t a LOG-ba
        */
        if(errStr is null ) then
          while (not sStack.isEmpty) loop
            sStack.pop(tmps);
            ret.extend;
            ret(ret.LAST) := tmps;
          end loop;
--          --BaE_UTIL.logStr('getLF.sStack verem �r�t�s v�ge');
          return FORMULAPART(ret);
        else
          --BaE_UTIL.logStr('FORMULA.getPolishForm() ERROR :: ' || trim(errStr));
          return null;
        end if;
        /* akkor k�szen vagyunk */
      end if; -- FORMULA is not null �g v�ge
    END getPolishForm;
    
    MEMBER PROCEDURE createCritPlaces IS
        fkPolish FORMULAPART; -- f�k�plet lengyelform�ja
        sStack SYMBOLSTACK;-- lengyelforma ki�rt�kel�shez felhaszn�lt verem
        lastRead  SYMBOL;  -- verem m�veletekn�l haszn�lt �tmeneti szimb�lum
        idx  INTEGER;                 -- lengyelforma elemeire tett mutat�
        critPlaceErrStr VARCHAR2(1000); -- Error string
        cntr INTEGER;                 -- ciklus sz�ml�l�
        s1 SYMBOL;         -- INFIX m�velet els� argumentuma, vagy FVjel argumentuma
        s2 SYMBOL;         -- INFIX m�velet m�sodik argumentuma
        tmps SYMBOL;       -- eredm�ny argumentum
        tmpx SYMBOL;       -- �tmeneti szimb�lum
        xxx SYMBOL_CRITPLACE; -- �tmeneti szimb�lum - kritikus �rt�k p�r
        newlevel INTEGER;               -- �ltalunk l�trehozott szimb�lum sz�m�tott szintje
      BEGIN
        /* n�zz�k, van-e �rtelme dolgozni... */
        if(mainFormula is null) then 
          ----BaE_UTIL.logStr('FORMULA.kritikusErtekeketEloallit ERROR :: mainFormula IS NULL');
          critPlaces := null;
          return;
        end if;
        if(mainFormula is not null) then
          fkPolish := getPolishForm(mainFormula);
          if(fkPolish IS NULL) then
            ----BaE_UTIL.logStr('FORMULA.kritikusErtekeketEloallit ERROR :: mainFormula lengyelform�ja NULL');
            critPlaces := null;
            return;
          end if;
        end if;
        /* akkor csin�ljuk... fkPolish m�r lefutott 
          elkezdj�k "ki�rt�kelni" a lengyelform�t, de ahelyett, hogy konkr�t �rt�ket helyettes�ten�nk be egy-egy m�veletbe,
          ink�bb csak kijel�lj�k a m�veletet �s szimb�lumk�nt bedobjuk a verembe.
          K�zben n�zz�k, hogy melyik m�veletnek milyen kritikus �rt�kei vannak, �s ezekhez milyen r�szk�plet tartozik
        */
        idx := fkPolish.symbSeries.FIRST;
        critPlaceErrStr := '';
        sStack := SYMBOLSTACK(1,null,null,null,null);
        sStack.initialize;
        critPlaces := VARR_SYMBOL_CRITPLACE();
        
        while ( (idx is not null) and (critPlaceErrStr is null) ) loop  -- lastRead START
          lastRead := fkPolish.symbSeries(idx);
          if(lastRead.simboltype = 'V' or lastRead.simboltype = 'K') then -- v�ltoz� vagy konstans: Verembe vele!
            sStack.push(lastRead);
          /* v�ltoz� END */
          elsif(lastRead.simboltype = 'I') then -- INFIX m�velet, k�l�n z�r�jel nem kell. K�t oldalt kivessz�k, eredm�nyt a verembe!
            if(lastRead.argNum = 1) then -- 
              critPlaceErrStr := trim(critPlaceErrStr) || 'INFIX m�velet 1 argumentummal! idx=' || idx 
                              || ', literal=' || lastRead.literal 
                              || ', argNum=' || lastRead.argNum || ';';
            elsif(lastRead.argNum = 2) then
              sStack.pop(s2); -- j� lenne, ha legal�bb 1 argumentum lenne
              if( not(sStack.isEmpty) ) then -- a m�sodik nem felt�tlen�l kell, pl. el�jeln�l
                sStack.pop(s1);
              end if;
              /* VIZSG�LAT: van-e kritikus �rt�k, �s mi az? */
              if(lastRead.criticalArgs is not null) then -- mert nem biztos, hogy van egy�ltal�n...
                FOR cntr IN lastRead.criticalArgs.FIRST..lastRead.criticalArgs.LAST LOOP -- INFIX kritikus �rt�kek START
                  if(lastRead.criticalArgs(cntr).position = 1 AND (s1 is not null) ) then -- els� argumentum �rintett
                    /* megadjuk a szimb�lum szintj�t, ha �res volna! */
                    if(s1.simbollevel is null) then
                      s1.simbollevel := 0;
                    end if;
                    critPlaces.extend;
                    critPlaces(critPlaces.LAST) := SYMBOL_CRITPLACE(
                                                              s1 , lastRead.criticalArgs(cntr).crit_place);
                  elsif(lastRead.criticalArgs(cntr).position = 2 AND (s2 is not null) ) then -- m�sodik argumentum �rintett
                    /* megadjuk a szimb�lum szintj�t, ha �res volna! */
                    if(s2.simbollevel is null) then
                      s2.simbollevel := 0;
                    end if;
                    critPlaces.extend;
                    critPlaces(critPlaces.LAST) := SYMBOL_CRITPLACE(
                                                              s2 , lastRead.criticalArgs(cntr).crit_place);
                  else -- ilyen nem lehets�ges
                    critPlaceErrStr := trim(critPlaceErrStr) || 'INFIX m�velet 3+ argumentum�nak van kritikus �rt�ke! idx=' || idx 
                                || ', literal=' || lastRead.literal 
                                || ', cntr=' || cntr || ';';
                  end if;
                END LOOP; -- INFIX kritikus �rt�kek END
              end if; -- vizsg�lat v�ge
              /* eredm�nyt bedobjuk a verembe, hogy k�s�bb kivehess�k:*/              
              -- SYMBOL('literal' , 'simboltype' , argNum , null, 0, newlevel)
              ----BaE_UTIL.logStr('FORMULA.createCritPlaces getNewLevel :: ' || getNewLevel(s1,s2) );
              if(s1 is not null) then -- k�t argumentum volt
                tmps := SYMBOL(s1.literal || lastRead.literal || s2.literal , 'V' , 0, null, 0, getNewLevel(s1,s2));
              else -- csak el�jel volt
                tmps := SYMBOL(lastRead.literal || s2.literal , 'V' , 0, null, 0, getNewLevel(null,s2));
              end if;
              sStack.push(tmps);
            /* INFIX end */
            else
              critPlaceErrStr := trim(critPlaceErrStr) || 'INFIX m�velet 3+ argumentummal! idx=' || idx 
                              || ', literal=' || lastRead.literal 
                              || ', argNum=' || lastRead.argNum || ';';
            end if;
          /* INFIX END */
          elsif(lastRead.simboltype = 'F') then -- FVjel, k�l�n z�r�jel KELL. argumentumot kivessz�k, z�r�jelbe tessz�k, eredm�nyt a verembe!
            sStack.pop(s1);
            /* VIZSG�LAT: van-e kritikus �rt�k, �s mi az? */
            if(lastRead.criticalArgs is not null) then -- nem biztos, hogy van...
              FOR cntr IN lastRead.criticalArgs.FIRST..lastRead.criticalArgs.LAST LOOP -- FVjel kritikus �rt�kek START
                if(lastRead.criticalArgs(cntr).position = 1) then -- els� argumentum �rintett
                  critPlaces.extend;
                  critPlaces(critPlaces.LAST) := SYMBOL_CRITPLACE(
                                                            s1 , lastRead.criticalArgs(cntr).crit_place);
                else -- most csak 1 argumentumos FVjeleink vannak!
                  critPlaceErrStr := trim(critPlaceErrStr) || 'FVjel 2+ argumentummal m�g nincs lefejlesztve! idx=' || idx 
                              || ', literal=' || lastRead.literal 
                              || ', cntr=' || cntr || ';';
                end if;
              END LOOP; -- FVjel kritikus �rt�kek END
            end if; -- vizsg�lat v�ge
            /* eredm�nyt bedobjuk a verembe, hogy k�s�bb kivehess�k */
            -- SYMBOL('literal' , 'simboltype' , argNum , null, 0, newlevel)
            tmps := SYMBOL(lastRead.literal || '(' || s1.literal || ')' , 'V' , 0, null, 0, getNewLevel(s1,null));
            sStack.push(tmps);
          /* FVjel END */
          else -- ismeretlen szimb�lum
            critPlaceErrStr := trim(critPlaceErrStr) || 'Ismeretlen SYMBOL idx=' || idx || ', simboltype=' || lastRead.simboltype || ';';
          end if;
          idx := fkPolish.symbSeries.NEXT(idx);
        end loop; -- lastRead END
        /* akkor tank�nyv szerint az eredm�ny a veremben keletkezett... de kit �rdekel ez most...? */
        if(critPlaceErrStr is not null) then
          ----BaE_UTIL.logStr('FORMULA.createCritPlaces ERROR :: ' || trim(critPlaceErrStr) );
          null;
        end if;
      END createCritPlaces;
      
      MEMBER FUNCTION getNewLevel(s1 IN SYMBOL, s2 IN SYMBOL) RETURN INTEGER IS
          szint1 INTEGER;
          szint2 INTEGER;
        BEGIN
          szint1 := getSafeSymbolLevel(s1);
          szint2 := getSafeSymbolLevel(s2);
          if(szint1 > szint2) then return szint1+1;
          else return szint2+1;
          end if;
        END getNewLevel;
        
      MEMBER FUNCTION getSafeSymbolLevel(s IN SYMBOL) RETURN INTEGER IS
        BEGIN
          if(s is null) then return 0;
          elsif(s.simbollevel is null) then return 0;
          else return s.simbollevel;
          end if;
        END;
      
      MEMBER FUNCTION critPlacesToString RETURN VARCHAR2 IS
          ret VARCHAR2(1000); -- visszat�r�si �rt�k
          idx INTEGER;        -- cikulsv�ltoz�
        BEGIN
          if(critPlaces is null or critPlaces.count=0) then
            ret := 'NULL';
            return ret;
          end if;
          FOR idx IN critPlaces.FIRST..critPlaces.LAST LOOP
            ret := trim(ret) || '[' || critPlaces(idx).symb.literal || ' {s=' || critPlaces(idx).symb.simbollevel || '}] :: ' || critPlaces(idx).crit_place.toString() || ';';
          END LOOP;
          return '[' || ret || ']';
        END critPlacesToString;
        
      MEMBER FUNCTION getSafeFormula RETURN VARCHAR2 IS
        BEGIN
          /* ha nincs kritikus hely, akkor visszaadjuk az eredeti k�pletet */
          if(critPlaces is null or critPlaces.count=0) then 
            return mainFormula.toString();
          else return '(case when (' || enumCritPlaces || ') THEN NULL ELSE (' || mainFormula.toString() || ') END)';
          end if;
        END;
      
      MEMBER FUNCTION enumCritPlaces RETURN VARCHAR2 IS
          ret varchar2(2000);
          type sVarrType is VARRAY(100) OF VARCHAR2(2000); -- fastrukt�ra szintenk�nt 1 bejegyz�s
          sVarr sVarrType;
          idx INTEGER; -- ciklusv�ltoz�
          tlevel INTEGER; -- aktu�lisan olvasott kritikus hely fastrukt�ra-beli szintje
          tstr varchar2(2000); -- aktu�lisan olvasott kritikus helyb�l gener�lt string
        BEGIN
          /* el�sz�r n�zz�k, vannak-e egy�ltal�n kritikus helyek... */
          if(critPlaces is null or critPlaces.count=0) then return null;
          end if;
          /* ezek szerint van legal�bb 1 kritikus hely... */
          
          /* az a baj, hogy a kritikus helyek nem felt�tlen�l a fastrukt�ra-beli szintj�knek megfelel� sorrendben vannak
          critPlaces t�mbben. */
          sVarr := sVarrType(null);
          sVarr.EXTEND(sVarr.LIMIT -1, 1); -- copy elements 1 in 2..100
          /* v�gigmegy�nk a kritikus �rt�keken, �s berakjuk �ket a megfelel� slot-okba */
          idx := critPlaces.FIRST;
          while(idx is not null) LOOP
            tlevel := critPlaces(idx).symb.simbollevel + 1;
            tstr := trim(critPlaces(idx).crit_place.getCaseCondition(critPlaces(idx).symb.literal));
            if(tlevel is not null) then
              if(sVarr(tlevel) is null) then
                sVarr(tlevel) := '(/*' || tlevel || '*/ ' || tstr || ')'; -- debug m�d
                /*sVarr(tlevel) := '(' || tstr || ')';  -- �les �zem*/
              else
                sVarr(tlevel) := trim(sVarr(tlevel)) || 'OR (/*' || tlevel || '*/ ' || tstr || ')'; -- debug m�d
                /*sVarr(tlevel) := trim(sVarr(tlevel)) || 'OR (' || tstr || ')'; -- �les �zem*/
              end if;
            end if;
            idx := critPlaces.next(idx);
          END LOOP; -- next IDX
          /* v�gigmegy�nk a slotokon */
          ret := '';
          FOR idx IN sVarr.FIRST..sVarr.LAST LOOP
            tstr := sVarr(idx);
            if(tstr is not null) then
              if(ret is null) then -- az els�re vad�szunk
                ret := trim(tstr);
              else
                ret := ret || ' OR ' || trim(tstr);
              end if;
            end if;
          END LOOP; -- next IDX
          return ret;
        END;
END;
/
/* TYPE FORMULA  -- END */

/* TYPE FORMULA_SYMB  -- START */
CREATE OR REPLACE TYPE FORMULA_SYMB AUTHID CURRENT_USER IS OBJECT(
   mutato_azonosito varchar2(2000)
  ,absztrakt_szimbolum SYMBOL
);
/
/* TYPE FORMULA_SYMB  -- END */

/* TYPE VARR_FORMULA_SYMB  -- START */
CREATE OR REPLACE TYPE VARR_FORMULA_SYMB IS VARRAY(100) OF FORMULA_SYMB;
/
/* TYPE VARR_FORMULA_SYMB  -- END */

/* TYPE LEXER_CHARCLASS  -- START */
CREATE OR REPLACE TYPE LEXER_CHARCLASS AUTHID CURRENT_USER IS OBJECT(
   sABC varchar2(100)  -- �b�c�
  ,sB VARCHAR2(10)     -- blank
  ,sD VARCHAR2(10)     -- sz�mok
  ,sINZ VARCHAR2(20)   -- infix m�veletek �s gomb�ly� z�r�jelek
  ,sP varchar2(10)     -- tizedespont
  ,sOB varchar2(10)    -- sz�gletes nyit�jel: [
  ,sCB varchar2(10)    -- sz�gletes csuk�jel: ]
  
  /* felt�lt�s */
  ,MEMBER PROCEDURE initialize
  
  /* karakteroszt�ly visszaad�sa */
  ,MEMBER FUNCTION getCharClass(actChar IN VARCHAR2) RETURN VARCHAR2
);
/

CREATE OR REPLACE TYPE BODY LEXER_CHARCLASS AS

  MEMBER PROCEDURE initialize IS
    BEGIN
      sABC := '_a�bcde�fghi�jklmno���pqrstu���vwxyzA�BCDE�FGHI�JKLMNO���PQRSTU���VWXYZ';
      sB := ' ';
      sD := '0123456789';
      sINZ := '+-*/()^';
      sP := '.';
      sOB := '[';
      sCB := ']';
    END initialize;
    
  MEMBER FUNCTION getCharClass(actChar IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
      if( actChar is null or instr(actChar,sB)>0 ) then return 'b';
      elsif( instr(sABC,actChar)>0 ) then return 'abc';
      elsif( instr(sD,actChar)>0 ) then return 'd';
      elsif( instr(sINZ,actChar)>0 ) then return 'm';
      elsif( instr(sP,actChar)>0 ) then return 'p';
      elsif( instr(sOB,actChar)>0 ) then return 'OB';
      elsif( instr(sCB,actChar)>0 ) then return 'CB';
      else return '*';
      end if;
    END getCharClass;
END;
/
/* TYPE LEXER_CHARCLASS  -- END */

/* TYPE CHAR_SYMBOL  -- START */
CREATE OR REPLACE TYPE CHAR_SYMBOL AUTHID CURRENT_USER IS OBJECT(
   literal varchar2(100)
  ,symb   SYMBOL
);
/
/* TYPE CHAR_SYMBOL  -- END */

/* TYPE VARR_CHAR_SYMBOL  -- START */
CREATE OR REPLACE TYPE VARR_CHAR_SYMBOL IS VARRAY(100) OF CHAR_SYMBOL;
/
/* TYPE VARR_CHAR_SYMBOL  -- END */

/* TYPE LEXER_SYMBOLTABLE  -- START */
create or replace
TYPE LEXER_SYMBOLTABLE AUTHID CURRENT_USER IS OBJECT(
   /* Infix m�veletek, nyit� �s csuk�jelek, fvjelek hozz�rendel�se a saj�t liter�ljukhoz
      -> ezen m�veleti jelek eset�ben a kritikus helyek k�l�n defin�ci�b�l sz�rmaznak
   */
   symboltable   VARR_CHAR_SYMBOL
  
  ,MEMBER PROCEDURE initialize
  
  ,MEMBER PROCEDURE initFromTables(inTSymTab    in varchar2
                                  ,inCLiteral   in varchar2
                                  ,inCSymCode1  in varchar2
                                  ,inCSymType   in varchar2
                                  ,inCArgNum    in varchar2
                                  ,inCPrec      in varchar2
                                  ,inTSymCrit   in varchar2
                                  ,inCSymCode2  in varchar2
                                  ,inCArgOrder  in varchar2
                                  ,inCCritPlace in varchar2
                                  ,inCLType     in varchar2
                                  ,inCLValue    in varchar2
                                  ,inCUType     in varchar2
                                  ,inCUValue    in varchar2
                                  )
  
  ,MEMBER FUNCTION getSymbol(str IN VARCHAR2) RETURN SYMBOL
);
/

CREATE OR REPLACE TYPE BODY LEXER_SYMBOLTABLE AS

  MEMBER PROCEDURE initialize IS
    BEGIN
      /* most jobb h�j�n beverj�k ide k�zzel, de persze jobb lenne, ha param�tert�bl�b�l t�lt�dne */
      symboltable := VARR_CHAR_SYMBOL();
      /* nyit� jel */
      symboltable.extend;
      symboltable(symboltable.last) := CHAR_SYMBOL('(' , SYMBOL('(','N',0,null,0,null));
      /* csuk� jel */
      symboltable.extend;
      symboltable(symboltable.last) := CHAR_SYMBOL(')' , SYMBOL(')','Z',0,null,0,null));
      /* + jel */
      symboltable.extend;
      symboltable(symboltable.last) := CHAR_SYMBOL('+' , SYMBOL('+','I',2,null,1,null));
      /* - jel */
      symboltable.extend;
      symboltable(symboltable.last) := CHAR_SYMBOL('-' , SYMBOL('-','I',2,null,1,null));
      /* * jel */
      symboltable.extend;
      symboltable(symboltable.last) := CHAR_SYMBOL('*' , SYMBOL('*','I',2,null,2,null));
      /* hatv�nyoz�s 1 :: ^ */
      symboltable.extend;
      symboltable(symboltable.last) := CHAR_SYMBOL('^' , SYMBOL('**','I',2,null,2,null));
      /* hatv�nyoz�s 1 :: ** */
      symboltable.extend;
      symboltable(symboltable.last) := CHAR_SYMBOL('**' , SYMBOL('**','I',2,null,2,null));
      /* / jel */
      symboltable.extend;
      symboltable(symboltable.last) := CHAR_SYMBOL('/' , SYMBOL('/','I',2,VARR_POS_CRITPLACE(POS_CRITPLACE(2,CRITPLACE(0,null)) ) ,2,null));
      /* LN FVjel */
      symboltable.extend;
      symboltable(symboltable.last) := CHAR_SYMBOL('LN' , SYMBOL('LN','F',2,VARR_POS_CRITPLACE(POS_CRITPLACE(1,CRITPLACE(null,CRITINTERV('V',null,'Z',0))) ) ,3,null));
    END initialize;
  
  MEMBER PROCEDURE initFromTables(inTSymTab    in varchar2
                                  ,inCLiteral   in varchar2
                                  ,inCSymCode1  in varchar2
                                  ,inCSymType   in varchar2
                                  ,inCArgNum    in varchar2
                                  ,inCPrec      in varchar2
                                  ,inTSymCrit   in varchar2
                                  ,inCSymCode2  in varchar2
                                  ,inCArgOrder  in varchar2
                                  ,inCCritPlace in varchar2
                                  ,inCLType     in varchar2
                                  ,inCLValue    in varchar2
                                  ,inCUType     in varchar2
                                  ,inCUValue    in varchar2
                                  ) IS
      TYPE curTp IS REF CURSOR;
      cRec  curTp;
      cRec2 curTp;
      
      curSql  varchar2(20000);
      curSql2 varchar2(20000);
      
      CLiteral varchar2(1000);
      CSymCode varchar2(1000);
      CSymType varchar2(1000);
      CArgNum number(15);
      CPrec   number(15);
      
      CArgOrder number(15);
      CCritPlace number(32,8);
      CLType varchar2(1000);
      CLValue number(32,8);
      CUType varchar2(1000);
      CUValue number(32,8);
      
      sym SYMBOL;
      vps VARR_POS_CRITPLACE;
      
    BEGIN
      symboltable := VARR_CHAR_SYMBOL();
      
      curSql := 'select ' || inCLiteral || ', ' || inCSymCode1 || ', ' || inCSymType || ', ' || inCArgNum || ', ' || inCPrec || '
                 from ' || inTSymTab
            ;
      --dbms_output.put_line('SQL 1 =' || curSql);
      open cRec for curSql;
      LOOP
        FETCH cRec INTO CLiteral, CSymCode, CSymType, CArgNum, CPrec;
        EXIT WHEN cRec%notfound;
        
        vps := null;
        
        curSql2 := 'select ' || inCArgOrder || ', ' || inCCritPlace || ', ' || inCLType || '
                       ,' || inCLValue || ', ' || inCUType || ', ' || inCUValue || '
                 from ' || inTSymCrit || '
                 where ' || inCSymCode2 || ' = ''' || CSymCode || ''''
            ;
        --dbms_output.put_line('  SQL 2 =' || curSql2);
        open cRec2 for curSql2; 
        loop
          FETCH cRec2 INTO CArgOrder, CCritPlace, CLType, CLValue, CUType, CUValue;
          EXIT WHEN cRec2%notfound;
          
          if(vps is null) then
            vps := VARR_POS_CRITPLACE();
          end if;
          
          vps.extend;
          if(CCritPlace is not null) then
            vps(vps.last) := POS_CRITPLACE(CArgOrder,CRITPLACE(CCritPlace,null));
          else
            vps(vps.last) := POS_CRITPLACE(CArgOrder,CRITPLACE(null,CRITINTERV(CLType,CLValue,CUType,CUValue)));
          end if;
          
        end loop; --end inner loop
        
        sym := SYMBOL(CSymCode,CSymType,CArgNum,vps,CPrec,null);
        
        symboltable.extend;
        symboltable(symboltable.last) := CHAR_SYMBOL(CLiteral,sym);
        
      END LOOP;
      close cRec;
      
    END initFromTables;
  
  MEMBER FUNCTION getSymbol(str IN VARCHAR2) RETURN SYMBOL IS
      idx INTEGER;
      tmpS SYMBOL;
    BEGIN
      idx := symboltable.FIRST;
      while(idx is not null) loop
        if( UPPER(str) = UPPER(symboltable(idx).literal) ) then return symboltable(idx).symb;
        end if;
        idx := symboltable.next(idx);
      end loop;
      /* ha nem siker�lt, akkor NULL-t adunk vissza */
      return null;
    END getSymbol;
END;
/
/* TYPE LEXER_SYMBOLTABLE  -- END */

/* TYPE LEXER  -- START */
CREATE OR REPLACE TYPE LEXER AUTHID CURRENT_USER IS OBJECT(
   /* a rend kedv��rt megtartjuk, amib�l dolgoztunk, h�tha kell m�g */
   formulaID VARCHAR(4000)
   /* mutat� azonos�t�hoz absztrakt k�plet szimb�lumot rendel� lista: processFormulaID() v�gterm�ke */
  ,formulaID_to_aSymb VARR_FORMULA_SYMB
   /* mutat� azonos�t� feldolgoz�s�val keletkez� absztrakt k�plet: processFormulaID() v�gterm�ke */
  ,formula_part FORMULAPART
  
  /* automata �ltal haszn�lt karakteroszt�ly */
  ,charClass LEXER_CHARCLASS
  /* automata �ltal haszn�lt m�veleti t�bla */
  ,symbTable LEXER_SYMBOLTABLE
  
  /* PRIVATE :: processFormulaID �ltal haszn�lt szimb�lum gener�l�s 
    lookS :: lookahead karakter
    extraConsume :: ha lookahead-et is felhaszn�ltunk, akkor a ciklus v�g�n t�bbel kell l�ptetni az indexet
  */
  ,MEMBER PROCEDURE genSymbol(actState IN VARCHAR2, collector IN VARCHAR2, absCnt IN NUMBER, lexErrStr IN OUT VARCHAR2
                                ,lookS IN VARCHAR2, extraConsume OUT integer)
  
   /* PUBLIC :: mutat� azonos�t�b�l absztrakt k�pletet */
  ,MEMBER PROCEDURE processFormulaID(strMutAzon IN VARCHAR2)
  
  /* PUBLIC :: megn�zhetj�k, mit mire helyettes�tett�nk */
  ,MEMBER FUNCTION enumSymbRepl RETURN VARCHAR2
);
/

create or replace
TYPE BODY LEXER AS
 
  MEMBER PROCEDURE processFormulaID(strMutAzon IN VARCHAR2) IS
      actState varchar2(10);    -- automata �llapotok: S, K, F, V, INZ
      actIdx integer;           -- aktu�lis karakter poz�ci�ja strMutAzon-ban
      actChar varchar2(1);      -- aktu�lis karakter
      collector varchar2(1000);    -- ide gy�jtj�k a sz�mokat, fvneveket, v�ltoz�neveket
      lexErrStr varchar2(1000); -- hiba string
      cClass varchar2(10);      -- olvasott karakter oszt�lya
      absCnt integer;           -- l�trehozott v�ltoz�k sz�ma
      lookChar varchar2(1);     -- lookahead karakter
      lClass varchar2(10);      -- lookahead karakter oszt�lya
      extraC integer;           -- lookahead felhaszn�l�s miatti extra l�ptet�s
    BEGIN
      /*lementj�k, amit kaptunk*/
      formulaID := trim(strMutAzon);
      
      actState := 'S';
      actIdx := 1;
      collector := '';
      lexErrStr := '';
      absCnt := 1;
      formula_part := FORMULAPART(VARR_SYMBOL());
      formulaID_to_aSymb := VARR_FORMULA_SYMB();
      while( actIdx <= LENGTH(formulaID) AND lexErrStr is null ) loop
        actChar := SUBSTR(formulaID,actIdx,1);
        cClass := charClass.getCharClass(actChar);
        /* lookahead-et CSAK oper�tor felismer�sre haszn�ljuk => csak akkor van �rtelme megk�pezni, ha cClass = INZ 
           megtartani pedig csak akkor van �rtelme, ha lClass = INZ is teljes�l
        */
        lookChar := '';
        lClass := '';
        if( actIdx < LENGTH(formulaID) AND cClass='m' ) then
          lookChar := SUBSTR(formulaID,actIdx+1,1);
          lClass := charClass.getCharClass(lookChar);
          if(lClass != 'm') then
            lookChar := '';
            lClass := '';
          end if;
        end if;
        /* extra consume alapesetben 0, ezen legfeljebb a megh�vott genSymbol tud v�ltoztatni */
        extraC := 0;
        /* akkor most automata �llapot (actState) �s olvasott karakter (actChar) f�ggv�ny�ben meghat�rozzuk a teend�ket */
        ----BaE_UTIL.logStr('CIKLUS: actIdx=' || actIdx || ', actChar=' || actChar || ', cClass=' || cClass || ', lookChar=' || lookChar || ', lClass=' || lClass);
        --dbms_output.put_line('CIKLUS: actIdx=' || actIdx || ', actChar=' || actChar || ', cClass=' || cClass || ', lookChar=' || lookChar || ', lClass=' || lClass);
        /* Aktu�lis karakter feldolgoz�sa  -- START */
        if(actState = 'S') then
          if(cClass = 'b') then
            null; -- nop
          elsif(cClass = 'm') then -- INZ, aholis figyeln�nk kell a lookahead-re is
            collector := actChar;
            actState := 'INZ';
            genSymbol(actState, collector, absCnt, lexErrStr, lookChar, extraC);
            collector := '';
            actState := 'S';
          elsif(cClass = 'd') then
            collector := collector || actChar;
            actState := 'K';
          elsif(cClass = 'p') then
            collector := collector || actChar;
            actState := 'K';
          elsif(cClass = 'OB') then
            collector := '';
            actState := 'V';
          elsif(cClass = 'abc') then
            collector := actChar;
            actState := 'F';
          else -- Hiba
            lexErrStr := lexErrStr || 'S �llapotban nem v�rt karakter: ' || actChar;
          end if;
        /* 'S' v�ge */
        elsif(actState = 'F') then
          if(cClass = 'b') then
            genSymbol(actState, collector, absCnt, lexErrStr, lookChar, extraC); -- F lez�r�s
            collector := '';
            actState := 'S';
          elsif(cClass = 'm') then -- INZ, �gy kett�t gener�lunk
            genSymbol(actState, collector, absCnt, lexErrStr, lookChar, extraC); -- F lez�r�s �s gener�l�s
            collector := actChar;
            actState := 'INZ';
            genSymbol(actState, collector, absCnt, lexErrStr, lookChar, extraC); -- INZ gener�l�s
            collector := '';
            actState := 'S';
          elsif(cClass = 'abc') then
            collector := collector || actChar;
            actState := 'F';
          elsif(cClass = 'd') then
            collector := collector || actChar;
            actState := 'F';
          elsif(cClass = 'p') then
            collector := collector || actChar;
            actState := 'F';
          elsif(cClass = 'OB') then
            genSymbol(actState, collector, absCnt, lexErrStr, lookChar, extraC); -- F lez�r�s �s gener�l�s
            collector := '';
            actState := 'V';
          else -- Hiba
            lexErrStr := lexErrStr || 'F �llapotban nem v�rt karakter: ' || actChar;
          end if;
        /* 'F' v�ge */
        elsif(actState = 'K') then
          if(cClass = 'b') then
            genSymbol(actState, collector, absCnt, lexErrStr, lookChar, extraC); -- K lez�r�s
            collector := '';
            actState := 'S';
          elsif(cClass = 'm') then -- INZ, �gy kett�t gener�lunk
            genSymbol(actState, collector, absCnt, lexErrStr, lookChar, extraC); -- K lez�r�s �s gener�l�s
            collector := actChar;
            actState := 'INZ';
            genSymbol(actState, collector, absCnt, lexErrStr, lookChar, extraC); -- INZ gener�l�s
            collector := '';
            actState := 'S';
          elsif(cClass = 'd') then
            collector := collector || actChar;
          elsif(cClass = 'p') then
            collector := collector || actChar;
          elsif(cClass = 'OB') then
            genSymbol(actState, collector, absCnt, lexErrStr, lookChar, extraC); -- K lez�r�s �s gener�l�s
            collector := '';
            actState := 'V';
          else -- Hiba
            lexErrStr := lexErrStr || 'K �llapotban nem v�rt karakter: ' || actChar;
          end if;
        /* 'K' v�ge */
        elsif(actState = 'V') then
          if(cClass = 'OB') then -- Hiba
            lexErrStr := lexErrStr || 'V �llapotban nem v�rt karakter: ' || actChar;
          elsif(cClass = 'CB') then
            genSymbol(actState, collector, absCnt, lexErrStr, lookChar, extraC); -- V lez�r�s �s gener�l�s
            absCnt := absCnt + 1;
            collector := '';
            actState := 'S';
          else
            collector := collector || actChar;
          end if;
        /* 'V' v�ge */
        else -- ilyen nem lehet, de ki tudja...
          lexErrStr := lexErrStr || 'Ismeretlen automata �llapot: [' || actState || ']';
        end if;
        /* Aktu�lis karakter feldolgoz�sa  -- END */
        
        /* �j karakterre l�p�nk:
             - alapesetben +1
             - de ha volt extra consume ig�ny (lookahead felhaszn�l�s miatt), akkor m�g annyival */
        actIdx := actIdx + 1 + extraC;
      end loop;
      
      /* szuper, mert nincs t�bb karakter. nem kiz�rt viszont, hogy van valami a gy�jt�ben 
          -> ebben az esetben azt is gyorsan gener�lni kellene... */
      if(collector is not null) then 
        genSymbol(actState, collector, absCnt, lexErrStr, lookChar, extraC);
      end if;
      
      /* ha volt hiba, azt logoljuk, valamint NULL-ra �ll�tjuk a k�pletet is */
      if(lexErrStr is not null) then
        formula_part := null;
        --BaE_UTIL.logStr('LEXER.processFormulaID ERROR :: ' || trim(lexErrStr) );
        --dbms_output.put_line('LEXER.processFormulaID ERROR :: ' || trim(lexErrStr) );
      end if;
    END processFormulaID;
    
    MEMBER PROCEDURE genSymbol(actState IN VARCHAR2, collector IN VARCHAR2, absCnt IN NUMBER, lexErrStr IN OUT VARCHAR2
                                ,lookS IN VARCHAR2, extraConsume OUT integer) IS
        newSymb SYMBOL;    -- l�trehozand� szimb�lum
        tmpNum number;                -- ellen�rz�s: val�ban sz�m az a konstans?
      BEGIN
        /* OUT v�ltoz�t 0-nak inicializ�ljuk */
        extraConsume := 0;
        /*actState-nek megfelel� szimb�lumot gener�lunk collector karaktereib�l*/
        if(actState = 'INZ' or actState = 'F') then  -- infix m�velet, nyit�/csuk� jel vagy Fvjel: megn�zz�k a szimb�lumt�bl�ban
          /* Moh� ki�rt�kel�s: lehet� leghosszabb stringgel illeszt�nk: el�sz�r lookahead-del, ha lehet */
          if(lookS is not null) then
            newSymb := symbTable.getSymbol(collector || lookS);
            if(newSymb is not null) then -- ezek szerint sikeresen felhaszn�ltuk a lookahead-et 2 karakteres oper�torhoz
              extraConsume := 1;
              ----BaE_UTIL.logStr('genSymbol: lookahead felhaszn�lva');
            else -- lookahead-nek nem sok haszn�t vett�k, mert k�t k�l�nb�z� oper�tor k�vetkezett egym�s ut�n
              newSymb := symbTable.getSymbol(collector);
              ----BaE_UTIL.logStr('genSymbol: volt lookahead , de nem volt j�');
            end if;
          else
            newSymb := symbTable.getSymbol(collector);
            ----BaE_UTIL.logStr('genSymbol: nem volt lookahead');
          end if;
        
          /* Ak�r felhaszn�ltuk a lookahead-et, ak�r nem, megn�zz�k, mit kaptunk v�g�l */
          if(newSymb is not null) then
            formula_part.symbSeries.extend;
            formula_part.symbSeries(formula_part.symbSeries.LAST) := newSymb;
          else
            lexErrStr := lexErrStr || 'genSymbol() Ismeretlen szimb�lum: actState=[' || actState || ']  ;  collector=' || collector;
          end if;
        /* INZ �s Fv v�ge */
        elsif(actState = 'K') then -- konstanst kellene gener�lni, m�r ha lehet
          begin
            tmpNum := to_number(collector);
            formula_part.symbSeries.extend;
            formula_part.symbSeries(formula_part.symbSeries.LAST) := SYMBOL(collector,'K',0,null,0,null);
          exception
            when VALUE_ERROR then -- akkor ez m�gsem volt j� �tlet, mert nem sz�m �ll a konstans hely�n
              lexErrStr := lexErrStr || 'genSymbol() Helytelen sz�mform�tum: actState=[' || actState || ']  ;  collector=' || collector;
          end;
        /* K v�ge */
        elsif(actState = 'V') then -- V�ltoz�
          newSymb := SYMBOL('a' || absCnt,'V',0,null,0,null);
          formula_part.symbSeries.extend;
          formula_part.symbSeries(formula_part.symbSeries.LAST) := newSymb;
          /* egy�ttal a gy�jt�ben l�v� Mutat� azonos�t�t hozz�rendelj�k ehhez a szimb�lumhoz */
          formulaID_to_aSymb.extend;
          formulaID_to_aSymb(formulaID_to_aSymb.LAST) := FORMULA_SYMB(collector , newSymb);
        /* V v�ge */
        else
          lexErrStr := lexErrStr || 'genSymbol() Ismeretlen automata �llapot: [' || actState || ']';
        end if;
      --EXCEPTION
        --WHEN OTHERS THEN
        --  lexErrStr := lexErrStr || 'genSymbol() Ismeretlen hiba: actState=[' || actState || ']  ;  collector=' || collector || '  ;  FORMULA=' || formula_part.toString();
      END genSymbol;
      
    MEMBER FUNCTION enumSymbRepl RETURN VARCHAR2 IS
        idx INTEGER;  -- ciklusv�ltoz�
        ret VARCHAR2(4000);  -- amit visszaadunk
      BEGIN
        if(formulaID_to_aSymb is null) then return 'NINCS HELYETTESITES!!';
        end if;
        idx := formulaID_to_aSymb.FIRST;
        ret := '';
        while(idx is not null) loop
          ret := ret || formulaID_to_aSymb(idx).mutato_azonosito || ' -> ' || formulaID_to_aSymb(idx).absztrakt_szimbolum.literal || ';';
          idx := formulaID_to_aSymb.next(idx);
        end loop;
        return ret;
      EXCEPTION
        WHEN OTHERS THEN
          return 'LEXER.enumSymbRepl() : ISMERETLEN HIBA';
      END enumSymbRepl; 
END;
/
/* TYPE LEXER  -- END */

/****  CREATE   -- END ****/


commit;
EXIT 0;
