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
   lowerBarrierType char(1)   -- 'Z': alulról zárt, 'N': alulról nyílt korlátos, 'V': alulról korlátlan intervallum
  ,lowerBarrierValue number    -- lowerBarrierType in ('Z','N') esetén értelmes
  ,upperBarrierType char(1)   -- 'Z': felülrõl zárt, 'N': felülrõl nyílt korlátos, 'V': felülrõl korlátlan intervallum
  ,upperBarrierValue number    -- upperBarrierType in ('Z','N') esetén értelmes
  
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
      /*alsó*/
      if(lowerBarrierType = 'V') then ak := '(-inf';
      else
        if(lowerBarrierValue is null) then return 'LowerBarrier NULL'; end if;
        if(lowerBarrierType = 'Z') then ak := '[';
        else ak := '(';
        end if;
        ak := trim(ak) || lowerBarrierValue;
      end if;
      /*felsõ*/
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
        /* hibás töltés esetén NULL-t adunk vissza */
        if(lowerBarrierType is null or upperBarrierType is null) then return null;
        else
          if(lowerBarrierType != 'V' and lowerBarrierValue is null) then return null; end if;
          if(upperBarrierType != 'V' and upperBarrierValue is null) then return null; end if;
        end if;
        /* akkor a korlát definíciók helyesek. Ha mindkét korlát végtelen, akkor TRUE-t adunk vissza */
        if(lowerBarrierType = 'V' and upperBarrierType = 'V') then return ' TRUE '; end if;
        /* egyébként meg számolunk... */
        ak := '';
        fk := '';
        if(upperBarrierType != 'V') then -- felsõ korlát (kivéve végtelen)
          if(upperBarrierType = 'N') then 
            fk := '(' || varvar || ' < ' || upperBarrierValue || ')';
          else fk := '(' || varvar || ' <= ' || upperBarrierValue || ')';
          end if;
        end if;
        if(lowerBarrierType != 'V') then -- alsó korlát (kivéve végtelen)
          if(lowerBarrierType = 'N') then
            ak := '(' || varvar || ' > ' || lowerBarrierValue || ')';
          else ak := '(' || varvar || ' >= ' || lowerBarrierValue || ')';
          end if;
        end if;
        /* mit adjunk vissza...? */
        if(lowerBarrierType = 'V') then -- alulról végtelen, felülrõl korlátos
          return fk;
        elsif(upperBarrierType = 'V') then -- felülrõl végtelen, alulról korlátos
          return ak;
        else -- mindkét irányból korlátos
          return '(' || ak || ' AND ' || fk || ')';
        end if;
      END getCaseCondition;
END;
/
/* TYPE CRITINTERV  -- END */

/* TYPE CRITPLACE  -- START */
CREATE OR REPLACE TYPE CRITPLACE AUTHID CURRENT_USER IS OBJECT(
   critValue number           -- kritikus érték (pl. osztásnál a nevezõ esetén 0)
  ,critInterval CRITINTERV  -- pozícióhoz tartozó kritikus intervallum (pl. LN(x) esetén x <= 0)
  
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
   position number       -- mûvelet argumentumának pozíciója (pl. LN(x) esetén az egyetlen (1.) argumentum)
  ,crit_place CRITPLACE  -- kapcsolódó kritikus hely
);
/
/* TYPE POS_CRITPLACE  -- END */

/* TYPE VARR_POS_CRITPLACE  -- START */
CREATE OR REPLACE TYPE VARR_POS_CRITPLACE IS VARRAY(100) OF POS_CRITPLACE;
/
/* TYPE VARR_POS_CRITPLACE  -- END */

/* innen jön a szimbólum... */
/* TYPE SYMBOL  -- START */
CREATE OR REPLACE TYPE SYMBOL AUTHID CURRENT_USER IS OBJECT(
  /**
    
  */
   literal varchar2(1000)
   /* N - Nyitójel, Z - Zárójel, I - Infix Mûvelet , F - függvény, V - Változó, K - Konstans */
  ,simboltype   varchar2(5)
   /* csak I és F típus esetén különbözik 0-tól, minden más esetben 0 */
  ,argNum  number(10)
   /* csak I és F típus esetén különbözHET ''-tól, minden más esetben '' */
   /* v02 TBD: ehelyett VARR_POZICIO_KRITIKUSERTEK_PAR kellene + kapcsolódó toString(), add() funkció... */
  ,criticalArgs VARR_POS_CRITPLACE
  /* operátor precedencia: akinek magasabb, az "nyer", értelme csak I vagy F esetén van */
  ,precedence integer
  /* szimbólum szintje a képlet fastruktúrás ábrázolásában -> csak FORMULA használja!! */
  ,simbollevel integer
  
  
  ,MEMBER FUNCTION getType RETURN VARCHAR2
  ,MEMBER FUNCTION getArgNum RETURN NUMBER
  
  ,MEMBER FUNCTION getCriticalArgNum RETURN NUMBER
  
  /* v02: visszatérési érték megváltozott */
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
   strictErrorHandling NUMBER   -- !=0: RAISE-zel hibát dobunk, leállunk; 0: error-t logolunk, NULL-t adunk vissza
  ,stackErrCode integer         -- alapvetõen 0, de utolsó mûvelet hibája esetén: 1 - Overflow, 2 - Empty stack (top/pop)
  ,position VARR_SYMBOL  -- belsõ változó, kívülrõl nem használandó
  ,maximalSize INTEGER          -- belsõ változó, kívülrõl nem használandó
  ,top INTEGER                  -- belsõ változó, kívülrõl nem használandó
  
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
/* lényeg: {részképlet 'V' típusú szimbólumként ; Kritikus hely} pár */
CREATE OR REPLACE TYPE SYMBOL_CRITPLACE AUTHID CURRENT_USER IS OBJECT(
   symb SYMBOL     -- szimbólum
  ,crit_place CRITPLACE   -- kritikus hely
);
/
/* TYPE SYMBOL_CRITPLACE  -- END */

/* TYPE VARR_SYMBOL_CRITPLACE  -- START */
/* lényeg: {Részképlet ; Kritikus érték} párok sorozata */
CREATE OR REPLACE TYPE VARR_SYMBOL_CRITPLACE IS VARRAY(100) OF SYMBOL_CRITPLACE;
/
/* TYPE VARR_SYMBOL_CRITPLACE  -- END */

/* TYPE FORMULA  -- START */
CREATE OR REPLACE TYPE FORMULA AUTHID CURRENT_USER IS OBJECT(
   mainFormula FORMULAPART
  ,critPlaces VARR_SYMBOL_CRITPLACE
  
  /* példányosítás után futtatandó: a fõképlet lengyelformára hozása és lengyelforma kiértékelése alapján 
    azonosítja a kritikus részképleteket, és az ezekhez tartozó kritikus értékeket */
  ,MEMBER PROCEDURE createCritPlaces 
  
  /* lengyelformára hozás, hívja: kritikusErtekeketEloallit */
  ,MEMBER FUNCTION getPolishForm(FORMULA IN FORMULAPART) RETURN FORMULAPART
  
  /* critPlaces string-gé konvertálása, elsõsorban teszteléshez */
  ,MEMBER FUNCTION critPlacesToString RETURN VARCHAR2
  
  /* fastruktúrában elhelyezkedõ mûvelet eredményképp létrehozott szimbólum fastruktúrabeli szintje */
  ,MEMBER FUNCTION getNewLevel(s1 IN SYMBOL, s2 IN SYMBOL) RETURN INTEGER
  /* segédfv. getNewLevel kiszámításához: NULL szimbólum és nemNull szimbólum NULL szintjére 0-t ad,
     különben a szimbólum szintjét */
  ,MEMBER FUNCTION getSafeSymbolLevel(s IN SYMBOL) RETURN INTEGER
  
  /* visszaadja a képlethez tartozó (CASE WHEN THEN END) szöveget, ami már kezeli a kritikus értékeket és intervallumokat */
  ,MEMBER FUNCTION getSafeFormula RETURN VARCHAR2
  /* segédfv. getSafeFormula kiszámításához: kritikus helyeket fastruktúra-beli szintjük szerint rendezetten 
     sorolja fel, OR-ral elválasztva */
  ,MEMBER FUNCTION enumCritPlaces RETURN VARCHAR2
);
/

CREATE OR REPLACE TYPE BODY FORMULA AS
  /**/
  MEMBER FUNCTION getPolishForm(FORMULA IN FORMULAPART) RETURN FORMULAPART IS
      sStack SYMBOLSTACK;  -- lengyelformára hozáshoz felhasznált verem
      ret VARR_SYMBOL;     -- lengyelforma egy szimbólumsorozat lesz
      errStr VARCHAR2(1000);          -- hiba
      idx integer;                    -- képlet aktuális szimbólumára mutató pointer
      tmps SYMBOL;         -- verem mûveletek során használt szimbólum
      lastRead SYMBOL;     -- inputról (=képletbõl) utoljára olvasott szimbólum
      tmps2 SYMBOL;        -- verem mûveletek során használt szimbólum (másik)
    BEGIN
      /* ha nincs képlet, nem dolgozunk */
      if(FORMULA is null) then 
        ----BaE_UTIL.logStr('FORMULA.getPolishForm() :: FORMULA IS NULL');
        return null;
      else
        /* egyébként hajrá... */
        sStack := SYMBOLSTACK(1,null,null,null,null);
        sStack.initialize;
        ret := VARR_SYMBOL(); -- ret := VARR_SZIMB(null);
        idx := FORMULA.symbSeries.FIRST;
        errStr := '';
--        --BaE_UTIL.logStr('getLF.sStack prep idx=' || idx || ', FORMULA=' || FORMULA.toString());
--        if(errStr != '') then
--          --BaE_UTIL.logStr('getLF.sStack prep ERRSTR NEM ÜRES!!!');
--        end if;
        while ( (idx is not null) and (errStr is null) ) loop  /* addig olvasunk, amíg a képlet végére nem érünk */
--          --BaE_UTIL.logStr('getLF.sStack ciklusba beléptünk');
          lastRead := FORMULA.symbSeries(idx);
--          if(lastRead is null) then 
--            --BaE_UTIL.logStr('getLF.sStack ciklus idx=' || idx || ', lastRead IS NULL !!!');
--          else
--            --BaE_UTIL.logStr('getLF.sStack ciklus idx=' || idx || ', lastRead=' || lastRead.literal);
--          end if;
          if(lastRead.simboltype = 'V' or lastRead.simboltype = 'K') then /* változó vagy konstans: nyomás az outputra */
            ret.extend;
            ret(ret.LAST) := lastRead;
          elsif(lastRead.simboltype = 'N') then /* nyitójel minden további nélkül megy a verembe */
            sStack.push(lastRead);
--            --BaE_UTIL.logStr('getLF.sStack ciklus idx=' || idx || ' AFTER N PUSH tartalom=' || sStack.toString() );
          elsif(lastRead.simboltype = 'Z') then /* zárójel: nyitójellel/függvénnyel bezárólag ürítjük a vermet és outputra írjuk */
            if(sStack.isEmpty) then /* zárójelezési hiba, ha üres a verem */
              errStr := trim(errStr) || 'zarojelezesi hiba poz=' || idx || '. szimbolumnal: sok csukojel, verem ÜRES;';
            else
              /* ürítünk nyitójelig/fvjelig, de a nyitójelet/fvjelet bennhagyjuk a veremben */
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
              /* utolsó jel: ha nyitójel, nem csinálunk vele semmit, ha fvjel: megy az outputra */
              if(not sStack.isEmpty) then
                sStack.pop(tmps);
              end if;
              if(tmps.simboltype = 'F') then
                ret.extend;
                ret(ret.LAST) := tmps;
              end if;
            end if;
            /*zárójel vége*/
          elsif(lastRead.simboltype = 'I') then /* INFIX mûvelet: ha a most olvasottnál nagyobb precedenciájú jel(ek) van(nak)
                                              a veremben, azokat (legfeljebb nyitójelig VAGY FVjelig) kipakoljuk és csak utána tesszük 
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
            /* végül a most olvasott jelet a verem tetejére dobjuk */
            sStack.push(lastRead);
--            --BaE_UTIL.logStr('getLF.sStack ciklus idx=' || idx || ' AFTER I PUSH tartalom=' || sStack.toString() );
          /* INFIX vége */
          elsif(lastRead.simboltype = 'F') then /* Függvény: Fvjel után nyitójelet is várunk, de azt nem tesszük a verembe! */
            idx := FORMULA.symbSeries.NEXT(idx); -- eggyel tovább lépünk!
            if( (idx is null) or FORMULA.symbSeries(idx).simboltype != 'N') then /* nyitójel helyett valami más van */
              errStr := trim(errStr) || 'FVjel hiba ' || idx || ' pozicion: Fvjel utan nincs Nyitojel;';
            else
              sStack.push(lastRead);
            end if;
          /* FV vége */
          else /* hiba, ilyen nem lehet! */
            errStr := trim(errStr) || 'Ismeretlen SYMBOL ' || idx || ' pozicion;';
          end if; /* lastRead olvasás -- END */
          idx := FORMULA.symbSeries.NEXT(idx);
--          --BaE_UTIL.logStr('getLF.sStack ' || idx || ', tartalom ciklus végén: ' || sStack.toString() );
        end loop; /* FORMULA olvasás vége */
--        --BaE_UTIL.logStr('getLF.sStack ciklus vége');
        /* ha nem volt hiba, és van még valami a veremben, akkor a tartalmát ürítsük az oputputra 
           ha volt hiba, akkor NULL-t adjunk vissza, és inkább írjuk a hiba szövegét a LOG-ba
        */
        if(errStr is null ) then
          while (not sStack.isEmpty) loop
            sStack.pop(tmps);
            ret.extend;
            ret(ret.LAST) := tmps;
          end loop;
--          --BaE_UTIL.logStr('getLF.sStack verem ürítés vége');
          return FORMULAPART(ret);
        else
          --BaE_UTIL.logStr('FORMULA.getPolishForm() ERROR :: ' || trim(errStr));
          return null;
        end if;
        /* akkor készen vagyunk */
      end if; -- FORMULA is not null ág vége
    END getPolishForm;
    
    MEMBER PROCEDURE createCritPlaces IS
        fkPolish FORMULAPART; -- fõképlet lengyelformája
        sStack SYMBOLSTACK;-- lengyelforma kiértékeléshez felhasznált verem
        lastRead  SYMBOL;  -- verem máveleteknél használt átmeneti szimbólum
        idx  INTEGER;                 -- lengyelforma elemeire tett mutató
        critPlaceErrStr VARCHAR2(1000); -- Error string
        cntr INTEGER;                 -- ciklus számláló
        s1 SYMBOL;         -- INFIX mûvelet elsõ argumentuma, vagy FVjel argumentuma
        s2 SYMBOL;         -- INFIX mûvelet második argumentuma
        tmps SYMBOL;       -- eredmény argumentum
        tmpx SYMBOL;       -- átmeneti szimbólum
        xxx SYMBOL_CRITPLACE; -- átmeneti szimbólum - kritikus érték pár
        newlevel INTEGER;               -- általunk létrehozott szimbólum számított szintje
      BEGIN
        /* nézzük, van-e értelme dolgozni... */
        if(mainFormula is null) then 
          ----BaE_UTIL.logStr('FORMULA.kritikusErtekeketEloallit ERROR :: mainFormula IS NULL');
          critPlaces := null;
          return;
        end if;
        if(mainFormula is not null) then
          fkPolish := getPolishForm(mainFormula);
          if(fkPolish IS NULL) then
            ----BaE_UTIL.logStr('FORMULA.kritikusErtekeketEloallit ERROR :: mainFormula lengyelformája NULL');
            critPlaces := null;
            return;
          end if;
        end if;
        /* akkor csináljuk... fkPolish már lefutott 
          elkezdjük "kiértékelni" a lengyelformát, de ahelyett, hogy konkrét értéket helyettesítenénk be egy-egy mûveletbe,
          inkább csak kijelöljük a mûveletet és szimbólumként bedobjuk a verembe.
          Közben nézzük, hogy melyik mûveletnek milyen kritikus értékei vannak, és ezekhez milyen részképlet tartozik
        */
        idx := fkPolish.symbSeries.FIRST;
        critPlaceErrStr := '';
        sStack := SYMBOLSTACK(1,null,null,null,null);
        sStack.initialize;
        critPlaces := VARR_SYMBOL_CRITPLACE();
        
        while ( (idx is not null) and (critPlaceErrStr is null) ) loop  -- lastRead START
          lastRead := fkPolish.symbSeries(idx);
          if(lastRead.simboltype = 'V' or lastRead.simboltype = 'K') then -- változó vagy konstans: Verembe vele!
            sStack.push(lastRead);
          /* változó END */
          elsif(lastRead.simboltype = 'I') then -- INFIX mûvelet, külön zárójel nem kell. Két oldalt kivesszük, eredményt a verembe!
            if(lastRead.argNum = 1) then -- 
              critPlaceErrStr := trim(critPlaceErrStr) || 'INFIX mûvelet 1 argumentummal! idx=' || idx 
                              || ', literal=' || lastRead.literal 
                              || ', argNum=' || lastRead.argNum || ';';
            elsif(lastRead.argNum = 2) then
              sStack.pop(s2); -- jó lenne, ha legalább 1 argumentum lenne
              if( not(sStack.isEmpty) ) then -- a második nem feltétlenül kell, pl. elõjelnél
                sStack.pop(s1);
              end if;
              /* VIZSGÁLAT: van-e kritikus érték, és mi az? */
              if(lastRead.criticalArgs is not null) then -- mert nem biztos, hogy van egyáltalán...
                FOR cntr IN lastRead.criticalArgs.FIRST..lastRead.criticalArgs.LAST LOOP -- INFIX kritikus értékek START
                  if(lastRead.criticalArgs(cntr).position = 1 AND (s1 is not null) ) then -- elsõ argumentum érintett
                    /* megadjuk a szimbólum szintjét, ha üres volna! */
                    if(s1.simbollevel is null) then
                      s1.simbollevel := 0;
                    end if;
                    critPlaces.extend;
                    critPlaces(critPlaces.LAST) := SYMBOL_CRITPLACE(
                                                              s1 , lastRead.criticalArgs(cntr).crit_place);
                  elsif(lastRead.criticalArgs(cntr).position = 2 AND (s2 is not null) ) then -- második argumentum érintett
                    /* megadjuk a szimbólum szintjét, ha üres volna! */
                    if(s2.simbollevel is null) then
                      s2.simbollevel := 0;
                    end if;
                    critPlaces.extend;
                    critPlaces(critPlaces.LAST) := SYMBOL_CRITPLACE(
                                                              s2 , lastRead.criticalArgs(cntr).crit_place);
                  else -- ilyen nem lehetséges
                    critPlaceErrStr := trim(critPlaceErrStr) || 'INFIX mûvelet 3+ argumentumának van kritikus értéke! idx=' || idx 
                                || ', literal=' || lastRead.literal 
                                || ', cntr=' || cntr || ';';
                  end if;
                END LOOP; -- INFIX kritikus értékek END
              end if; -- vizsgálat vége
              /* eredményt bedobjuk a verembe, hogy késõbb kivehessük:*/              
              -- SYMBOL('literal' , 'simboltype' , argNum , null, 0, newlevel)
              ----BaE_UTIL.logStr('FORMULA.createCritPlaces getNewLevel :: ' || getNewLevel(s1,s2) );
              if(s1 is not null) then -- két argumentum volt
                tmps := SYMBOL(s1.literal || lastRead.literal || s2.literal , 'V' , 0, null, 0, getNewLevel(s1,s2));
              else -- csak elõjel volt
                tmps := SYMBOL(lastRead.literal || s2.literal , 'V' , 0, null, 0, getNewLevel(null,s2));
              end if;
              sStack.push(tmps);
            /* INFIX end */
            else
              critPlaceErrStr := trim(critPlaceErrStr) || 'INFIX mûvelet 3+ argumentummal! idx=' || idx 
                              || ', literal=' || lastRead.literal 
                              || ', argNum=' || lastRead.argNum || ';';
            end if;
          /* INFIX END */
          elsif(lastRead.simboltype = 'F') then -- FVjel, külön zárójel KELL. argumentumot kivesszük, zárójelbe tesszük, eredményt a verembe!
            sStack.pop(s1);
            /* VIZSGÁLAT: van-e kritikus érték, és mi az? */
            if(lastRead.criticalArgs is not null) then -- nem biztos, hogy van...
              FOR cntr IN lastRead.criticalArgs.FIRST..lastRead.criticalArgs.LAST LOOP -- FVjel kritikus értékek START
                if(lastRead.criticalArgs(cntr).position = 1) then -- elsõ argumentum érintett
                  critPlaces.extend;
                  critPlaces(critPlaces.LAST) := SYMBOL_CRITPLACE(
                                                            s1 , lastRead.criticalArgs(cntr).crit_place);
                else -- most csak 1 argumentumos FVjeleink vannak!
                  critPlaceErrStr := trim(critPlaceErrStr) || 'FVjel 2+ argumentummal még nincs lefejlesztve! idx=' || idx 
                              || ', literal=' || lastRead.literal 
                              || ', cntr=' || cntr || ';';
                end if;
              END LOOP; -- FVjel kritikus értékek END
            end if; -- vizsgálat vége
            /* eredményt bedobjuk a verembe, hogy késõbb kivehessük */
            -- SYMBOL('literal' , 'simboltype' , argNum , null, 0, newlevel)
            tmps := SYMBOL(lastRead.literal || '(' || s1.literal || ')' , 'V' , 0, null, 0, getNewLevel(s1,null));
            sStack.push(tmps);
          /* FVjel END */
          else -- ismeretlen szimbólum
            critPlaceErrStr := trim(critPlaceErrStr) || 'Ismeretlen SYMBOL idx=' || idx || ', simboltype=' || lastRead.simboltype || ';';
          end if;
          idx := fkPolish.symbSeries.NEXT(idx);
        end loop; -- lastRead END
        /* akkor tankönyv szerint az eredmény a veremben keletkezett... de kit érdekel ez most...? */
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
          ret VARCHAR2(1000); -- visszatérési érték
          idx INTEGER;        -- cikulsváltozó
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
          /* ha nincs kritikus hely, akkor visszaadjuk az eredeti képletet */
          if(critPlaces is null or critPlaces.count=0) then 
            return mainFormula.toString();
          else return '(case when (' || enumCritPlaces || ') THEN NULL ELSE (' || mainFormula.toString() || ') END)';
          end if;
        END;
      
      MEMBER FUNCTION enumCritPlaces RETURN VARCHAR2 IS
          ret varchar2(2000);
          type sVarrType is VARRAY(100) OF VARCHAR2(2000); -- fastruktúra szintenként 1 bejegyzés
          sVarr sVarrType;
          idx INTEGER; -- ciklusváltozó
          tlevel INTEGER; -- aktuálisan olvasott kritikus hely fastruktúra-beli szintje
          tstr varchar2(2000); -- aktuálisan olvasott kritikus helybõl generált string
        BEGIN
          /* elõször nézzük, vannak-e egyáltalán kritikus helyek... */
          if(critPlaces is null or critPlaces.count=0) then return null;
          end if;
          /* ezek szerint van legalább 1 kritikus hely... */
          
          /* az a baj, hogy a kritikus helyek nem feltétlenül a fastruktúra-beli szintjüknek megfelelõ sorrendben vannak
          critPlaces tömbben. */
          sVarr := sVarrType(null);
          sVarr.EXTEND(sVarr.LIMIT -1, 1); -- copy elements 1 in 2..100
          /* végigmegyünk a kritikus értékeken, és berakjuk õket a megfelelõ slot-okba */
          idx := critPlaces.FIRST;
          while(idx is not null) LOOP
            tlevel := critPlaces(idx).symb.simbollevel + 1;
            tstr := trim(critPlaces(idx).crit_place.getCaseCondition(critPlaces(idx).symb.literal));
            if(tlevel is not null) then
              if(sVarr(tlevel) is null) then
                sVarr(tlevel) := '(/*' || tlevel || '*/ ' || tstr || ')'; -- debug mód
                /*sVarr(tlevel) := '(' || tstr || ')';  -- éles üzem*/
              else
                sVarr(tlevel) := trim(sVarr(tlevel)) || 'OR (/*' || tlevel || '*/ ' || tstr || ')'; -- debug mód
                /*sVarr(tlevel) := trim(sVarr(tlevel)) || 'OR (' || tstr || ')'; -- éles üzem*/
              end if;
            end if;
            idx := critPlaces.next(idx);
          END LOOP; -- next IDX
          /* végigmegyünk a slotokon */
          ret := '';
          FOR idx IN sVarr.FIRST..sVarr.LAST LOOP
            tstr := sVarr(idx);
            if(tstr is not null) then
              if(ret is null) then -- az elsõre vadászunk
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
   sABC varchar2(100)  -- ábécé
  ,sB VARCHAR2(10)     -- blank
  ,sD VARCHAR2(10)     -- számok
  ,sINZ VARCHAR2(20)   -- infix mûveletek és gombölyû zárójelek
  ,sP varchar2(10)     -- tizedespont
  ,sOB varchar2(10)    -- szögletes nyitójel: [
  ,sCB varchar2(10)    -- szögletes csukójel: ]
  
  /* feltöltés */
  ,MEMBER PROCEDURE initialize
  
  /* karakterosztály visszaadása */
  ,MEMBER FUNCTION getCharClass(actChar IN VARCHAR2) RETURN VARCHAR2
);
/

CREATE OR REPLACE TYPE BODY LEXER_CHARCLASS AS

  MEMBER PROCEDURE initialize IS
    BEGIN
      sABC := '_aábcdeéfghiíjklmnoóöõpqrstuúüûvwxyzAÁBCDEÉFGHIÍJKLMNOÓÖÕPQRSTUÚÜÛVWXYZ';
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
   /* Infix mûveletek, nyitó és csukójelek, fvjelek hozzárendelése a saját literáljukhoz
      -> ezen mûveleti jelek esetében a kritikus helyek külön definícióból származnak
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
      /* most jobb híján beverjük ide kézzel, de persze jobb lenne, ha paramétertáblából töltõdne */
      symboltable := VARR_CHAR_SYMBOL();
      /* nyitó jel */
      symboltable.extend;
      symboltable(symboltable.last) := CHAR_SYMBOL('(' , SYMBOL('(','N',0,null,0,null));
      /* csukó jel */
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
      /* hatványozás 1 :: ^ */
      symboltable.extend;
      symboltable(symboltable.last) := CHAR_SYMBOL('^' , SYMBOL('**','I',2,null,2,null));
      /* hatványozás 1 :: ** */
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
      /* ha nem sikerült, akkor NULL-t adunk vissza */
      return null;
    END getSymbol;
END;
/
/* TYPE LEXER_SYMBOLTABLE  -- END */

/* TYPE LEXER  -- START */
CREATE OR REPLACE TYPE LEXER AUTHID CURRENT_USER IS OBJECT(
   /* a rend kedvéért megtartjuk, amibõl dolgoztunk, hátha kell még */
   formulaID VARCHAR(4000)
   /* mutató azonosítóhoz absztrakt képlet szimbólumot rendelõ lista: processFormulaID() végterméke */
  ,formulaID_to_aSymb VARR_FORMULA_SYMB
   /* mutató azonosító feldolgozásával keletkezõ absztrakt képlet: processFormulaID() végterméke */
  ,formula_part FORMULAPART
  
  /* automata által használt karakterosztály */
  ,charClass LEXER_CHARCLASS
  /* automata által használt mûveleti tábla */
  ,symbTable LEXER_SYMBOLTABLE
  
  /* PRIVATE :: processFormulaID által használt szimbólum generálás 
    lookS :: lookahead karakter
    extraConsume :: ha lookahead-et is felhasználtunk, akkor a ciklus végén többel kell léptetni az indexet
  */
  ,MEMBER PROCEDURE genSymbol(actState IN VARCHAR2, collector IN VARCHAR2, absCnt IN NUMBER, lexErrStr IN OUT VARCHAR2
                                ,lookS IN VARCHAR2, extraConsume OUT integer)
  
   /* PUBLIC :: mutató azonosítóból absztrakt képletet */
  ,MEMBER PROCEDURE processFormulaID(strMutAzon IN VARCHAR2)
  
  /* PUBLIC :: megnézhetjük, mit mire helyettesítettünk */
  ,MEMBER FUNCTION enumSymbRepl RETURN VARCHAR2
);
/

create or replace
TYPE BODY LEXER AS
 
  MEMBER PROCEDURE processFormulaID(strMutAzon IN VARCHAR2) IS
      actState varchar2(10);    -- automata állapotok: S, K, F, V, INZ
      actIdx integer;           -- aktuális karakter pozíciója strMutAzon-ban
      actChar varchar2(1);      -- aktuális karakter
      collector varchar2(1000);    -- ide gyûjtjük a számokat, fvneveket, változóneveket
      lexErrStr varchar2(1000); -- hiba string
      cClass varchar2(10);      -- olvasott karakter osztálya
      absCnt integer;           -- létrehozott változók száma
      lookChar varchar2(1);     -- lookahead karakter
      lClass varchar2(10);      -- lookahead karakter osztálya
      extraC integer;           -- lookahead felhasználás miatti extra léptetés
    BEGIN
      /*lementjük, amit kaptunk*/
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
        /* lookahead-et CSAK operátor felismerésre használjuk => csak akkor van értelme megképezni, ha cClass = INZ 
           megtartani pedig csak akkor van értelme, ha lClass = INZ is teljesül
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
        /* extra consume alapesetben 0, ezen legfeljebb a meghívott genSymbol tud változtatni */
        extraC := 0;
        /* akkor most automata állapot (actState) és olvasott karakter (actChar) függvényében meghatározzuk a teendõket */
        ----BaE_UTIL.logStr('CIKLUS: actIdx=' || actIdx || ', actChar=' || actChar || ', cClass=' || cClass || ', lookChar=' || lookChar || ', lClass=' || lClass);
        --dbms_output.put_line('CIKLUS: actIdx=' || actIdx || ', actChar=' || actChar || ', cClass=' || cClass || ', lookChar=' || lookChar || ', lClass=' || lClass);
        /* Aktuális karakter feldolgozása  -- START */
        if(actState = 'S') then
          if(cClass = 'b') then
            null; -- nop
          elsif(cClass = 'm') then -- INZ, aholis figyelnünk kell a lookahead-re is
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
            lexErrStr := lexErrStr || 'S állapotban nem várt karakter: ' || actChar;
          end if;
        /* 'S' vége */
        elsif(actState = 'F') then
          if(cClass = 'b') then
            genSymbol(actState, collector, absCnt, lexErrStr, lookChar, extraC); -- F lezárás
            collector := '';
            actState := 'S';
          elsif(cClass = 'm') then -- INZ, így kettõt generálunk
            genSymbol(actState, collector, absCnt, lexErrStr, lookChar, extraC); -- F lezárás és generálás
            collector := actChar;
            actState := 'INZ';
            genSymbol(actState, collector, absCnt, lexErrStr, lookChar, extraC); -- INZ generálás
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
            genSymbol(actState, collector, absCnt, lexErrStr, lookChar, extraC); -- F lezárás és generálás
            collector := '';
            actState := 'V';
          else -- Hiba
            lexErrStr := lexErrStr || 'F állapotban nem várt karakter: ' || actChar;
          end if;
        /* 'F' vége */
        elsif(actState = 'K') then
          if(cClass = 'b') then
            genSymbol(actState, collector, absCnt, lexErrStr, lookChar, extraC); -- K lezárás
            collector := '';
            actState := 'S';
          elsif(cClass = 'm') then -- INZ, így kettõt generálunk
            genSymbol(actState, collector, absCnt, lexErrStr, lookChar, extraC); -- K lezárás és generálás
            collector := actChar;
            actState := 'INZ';
            genSymbol(actState, collector, absCnt, lexErrStr, lookChar, extraC); -- INZ generálás
            collector := '';
            actState := 'S';
          elsif(cClass = 'd') then
            collector := collector || actChar;
          elsif(cClass = 'p') then
            collector := collector || actChar;
          elsif(cClass = 'OB') then
            genSymbol(actState, collector, absCnt, lexErrStr, lookChar, extraC); -- K lezárás és generálás
            collector := '';
            actState := 'V';
          else -- Hiba
            lexErrStr := lexErrStr || 'K állapotban nem várt karakter: ' || actChar;
          end if;
        /* 'K' vége */
        elsif(actState = 'V') then
          if(cClass = 'OB') then -- Hiba
            lexErrStr := lexErrStr || 'V állapotban nem várt karakter: ' || actChar;
          elsif(cClass = 'CB') then
            genSymbol(actState, collector, absCnt, lexErrStr, lookChar, extraC); -- V lezárás és generálás
            absCnt := absCnt + 1;
            collector := '';
            actState := 'S';
          else
            collector := collector || actChar;
          end if;
        /* 'V' vége */
        else -- ilyen nem lehet, de ki tudja...
          lexErrStr := lexErrStr || 'Ismeretlen automata állapot: [' || actState || ']';
        end if;
        /* Aktuális karakter feldolgozása  -- END */
        
        /* új karakterre lépünk:
             - alapesetben +1
             - de ha volt extra consume igény (lookahead felhasználás miatt), akkor még annyival */
        actIdx := actIdx + 1 + extraC;
      end loop;
      
      /* szuper, mert nincs több karakter. nem kizárt viszont, hogy van valami a gyûjtõben 
          -> ebben az esetben azt is gyorsan generálni kellene... */
      if(collector is not null) then 
        genSymbol(actState, collector, absCnt, lexErrStr, lookChar, extraC);
      end if;
      
      /* ha volt hiba, azt logoljuk, valamint NULL-ra állítjuk a képletet is */
      if(lexErrStr is not null) then
        formula_part := null;
        --BaE_UTIL.logStr('LEXER.processFormulaID ERROR :: ' || trim(lexErrStr) );
        --dbms_output.put_line('LEXER.processFormulaID ERROR :: ' || trim(lexErrStr) );
      end if;
    END processFormulaID;
    
    MEMBER PROCEDURE genSymbol(actState IN VARCHAR2, collector IN VARCHAR2, absCnt IN NUMBER, lexErrStr IN OUT VARCHAR2
                                ,lookS IN VARCHAR2, extraConsume OUT integer) IS
        newSymb SYMBOL;    -- létrehozandó szimbólum
        tmpNum number;                -- ellenõrzés: valóban szám az a konstans?
      BEGIN
        /* OUT változót 0-nak inicializáljuk */
        extraConsume := 0;
        /*actState-nek megfelelõ szimbólumot generálunk collector karaktereibõl*/
        if(actState = 'INZ' or actState = 'F') then  -- infix mûvelet, nyitó/csukó jel vagy Fvjel: megnézzük a szimbólumtáblában
          /* Mohó kiértékelés: lehetõ leghosszabb stringgel illesztünk: elõször lookahead-del, ha lehet */
          if(lookS is not null) then
            newSymb := symbTable.getSymbol(collector || lookS);
            if(newSymb is not null) then -- ezek szerint sikeresen felhasználtuk a lookahead-et 2 karakteres operátorhoz
              extraConsume := 1;
              ----BaE_UTIL.logStr('genSymbol: lookahead felhasználva');
            else -- lookahead-nek nem sok hasznát vettük, mert két különbözõ operátor következett egymás után
              newSymb := symbTable.getSymbol(collector);
              ----BaE_UTIL.logStr('genSymbol: volt lookahead , de nem volt jó');
            end if;
          else
            newSymb := symbTable.getSymbol(collector);
            ----BaE_UTIL.logStr('genSymbol: nem volt lookahead');
          end if;
        
          /* Akár felhasználtuk a lookahead-et, akár nem, megnézzük, mit kaptunk végül */
          if(newSymb is not null) then
            formula_part.symbSeries.extend;
            formula_part.symbSeries(formula_part.symbSeries.LAST) := newSymb;
          else
            lexErrStr := lexErrStr || 'genSymbol() Ismeretlen szimbólum: actState=[' || actState || ']  ;  collector=' || collector;
          end if;
        /* INZ és Fv vége */
        elsif(actState = 'K') then -- konstanst kellene generálni, már ha lehet
          begin
            tmpNum := to_number(collector);
            formula_part.symbSeries.extend;
            formula_part.symbSeries(formula_part.symbSeries.LAST) := SYMBOL(collector,'K',0,null,0,null);
          exception
            when VALUE_ERROR then -- akkor ez mégsem volt jó ötlet, mert nem szám áll a konstans helyén
              lexErrStr := lexErrStr || 'genSymbol() Helytelen számformátum: actState=[' || actState || ']  ;  collector=' || collector;
          end;
        /* K vége */
        elsif(actState = 'V') then -- Változó
          newSymb := SYMBOL('a' || absCnt,'V',0,null,0,null);
          formula_part.symbSeries.extend;
          formula_part.symbSeries(formula_part.symbSeries.LAST) := newSymb;
          /* egyúttal a gyûjtõben lévõ Mutató azonosítót hozzárendeljük ehhez a szimbólumhoz */
          formulaID_to_aSymb.extend;
          formulaID_to_aSymb(formulaID_to_aSymb.LAST) := FORMULA_SYMB(collector , newSymb);
        /* V vége */
        else
          lexErrStr := lexErrStr || 'genSymbol() Ismeretlen automata állapot: [' || actState || ']';
        end if;
      --EXCEPTION
        --WHEN OTHERS THEN
        --  lexErrStr := lexErrStr || 'genSymbol() Ismeretlen hiba: actState=[' || actState || ']  ;  collector=' || collector || '  ;  FORMULA=' || formula_part.toString();
      END genSymbol;
      
    MEMBER FUNCTION enumSymbRepl RETURN VARCHAR2 IS
        idx INTEGER;  -- ciklusváltozó
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
