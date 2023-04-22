CREATE TABLE Plebs (
  idn INTEGER CONSTRAINT plebs_pk PRIMARY KEY,
  kot VARCHAR2(10) CONSTRAINT plebks_fk REFERENCES Kocury(pseudo)
);
CREATE TABLE Elita (
  idn INTEGER CONSTRAINT elita_pk PRIMARY KEY,
  kot VARCHAR2(10) CONSTRAINT elita_fk REFERENCES Kocury(pseudo),
  sluga NUMBER CONSTRAINT elita_sluga_fk REFERENCES Plebs(idn)
);

CREATE TABLE Konto (
  idn INTEGER CONSTRAINT konto_pk PRIMARY KEY,
  dataWprowadzenia DATE,
  dataUsuniecia DATE,
  kot NUMBER CONSTRAINT konto_fk REFERENCES Elita(idn)
);
--ten sam co w 47
CREATE OR REPLACE TYPE KocuryO AS OBJECT
(
    imie            VARCHAR2(15),
    plec            VARCHAR2(1),
    pseudo          VARCHAR2(15),
    funkcja         VARCHAR2(10),
    w_stadku_od     DATE,
    przydzial_myszy NUMBER(3),
    myszy_extra     NUMBER(3),
    nr_bandy        NUMBER(2),
    szef            REF KocuryO,
    MEMBER FUNCTION caly_przydzial RETURN NUMBER,
    MAP MEMBER FUNCTION info RETURN VARCHAR2
);

CREATE OR REPLACE TYPE Plebs48 AS OBJECT
(
  idn INTEGER,
  kot REF KocuryO,
  MEMBER FUNCTION dane_o_kocie RETURN VARCHAR2
);

CREATE OR REPLACE TYPE BODY Plebs48 AS
  MEMBER FUNCTION dane_o_kocie RETURN VARCHAR2 IS
      text VARCHAR2(500);
    BEGIN
      SELECT 'IMIE: ' || DEREF(kot).imie || ' PSEUDO ' || DEREF(kot).pseudo INTO text FROM dual;
      RETURN text;
    END;
END;

CREATE OR REPLACE TYPE Elita48 AS OBJECT
(
  idn INTEGER,
  kot REF KocuryO,
  sluga REF Plebs48,
  MEMBER FUNCTION pobierz_sluge RETURN REF Plebs48
);

CREATE OR REPLACE TYPE BODY Elita48 AS
  MEMBER FUNCTION pobierz_sluge RETURN REF Plebs48 IS
    BEGIN
      RETURN sluga;
    END;
END;

CREATE OR REPLACE TYPE Konto48 AS OBJECT
(
  idn INTEGER,
  dataWprowadzenia DATE,
  dataUsuniecia DATE,
  kot REF Elita48,
  MEMBER PROCEDURE wyprowadz_mysz(dat DATE)
);

CREATE OR REPLACE TYPE BODY Konto48 AS
  MEMBER PROCEDURE wyprowadz_mysz(dat DATE) IS
    BEGIN
      datausuniecia := dat;
    END;
END;


CREATE OR REPLACE VIEW Kocury_S OF KocuryO
WITH OBJECT IDENTIFIER (pseudo) AS
SELECT KocuryO(imie, plec, pseudo, funkcja,  w_stadku_od, przydzial_myszy, myszy_extra, nr_bandy, NULL)
FROM kocury;

CREATE OR REPLACE VIEW Kocury_O OF KocuryO
WITH OBJECT IDENTIFIER (pseudo) AS
SELECT KocuryO(imie, plec, pseudo, funkcja,  w_stadku_od, przydzial_myszy, myszy_extra, nr_bandy, MAKE_REF(kocury_S, szef))
FROM kocury;

CREATE OR REPLACE VIEW Plebs_O OF Plebs48
WITH OBJECT IDENTIFIER (idn) AS
SELECT idn, MAKE_REF(Kocury_O, kot) kot
FROM plebs;

CREATE OR REPLACE VIEW Elita_O OF Elita48
WITH OBJECT IDENTIFIER (idn) AS
SELECT idn, MAKE_REF(Kocury_O, kot) kot, MAKE_REF(Plebs_O, sluga) sluga
FROM elita;

CREATE OR REPLACE VIEW Konto_O OF konto48
WITH OBJECT IDENTIFIER (idn) AS
SELECT idn, datawprowadzenia, konto.datausuniecia, MAKE_REF(Elita_O, kot) kot
FROM konto;
--wypelnianie danych - podobnie do 47
DECLARE
CURSOR koty IS SELECT  pseudo
                    FROM (SELECT K.pseudo pseudo FROM Kocury_O K ORDER BY K.caly_przydzial() ASC)
                    WHERE ROWNUM<= (SELECT COUNT(*) FROM Kocury_O)/2;
dyn_sql VARCHAR2(1000);
idn INTEGER := 0;
BEGIN
    FOR plebs IN koty
    LOOP
      idn := idn + 1;
      dyn_sql:='DECLARE
            kot REF KocuryO;
        BEGIN
            SELECT REF(K) INTO kot FROM Kocury_O K WHERE K.pseudo='''|| plebs.pseudo||''';
            INSERT INTO Plebs_O VALUES
                    (Plebs48('''|| idn ||''',' || 'kot' || '));
            END;';
       EXECUTE IMMEDIATE  dyn_sql;
    END LOOP;
END;

DECLARE
CURSOR koty IS SELECT PSEUDO FROM (SELECT K.pseudo pseudo FROM Kocury_O K ORDER BY K.caly_przydzial() DESC)
    WHERE ROWNUM <= (SELECT COUNT(*) FROM Kocury_O)/2;
sql_string VARCHAR2(1000);
num NUMBER:=1;
BEGIN
    FOR elita in koty
    LOOP
        sql_string:='DECLARE
                        kot REF KocuryO;
                        sluga REF Plebs48;
                    BEGIN
                        SELECT REF(K) INTO kot FROM Kocury_O K WHERE K.pseudo=''' || elita.pseudo || ''';' ||
                       'SELECT plebs INTO sluga FROM (SELECT rownum num, REF(P) plebs  FROM Plebs_O P) WHERE NUM=' || num ||';'||
                    'INSERT INTO Elita_O VALUES (Elita48(''' || num ||''', kot, sluga)); END;';
        EXECUTE IMMEDIATE  sql_string;
        num:=num+1;
        END LOOP;
END;

SELECT DEREF(kot), DEREF(sluga) FROM elita_o;

INSERT INTO konto_O
  SELECT konto48(ROWNUM, ADD_MONTHS(CURRENT_DATE, -TRUNC(DBMS_RANDOM.VALUE(0, 12))), NULL, REF(K))
  FROM Elita_O K;
COMMIT;

-- Podzapytanie (dane slugusow)
SELECT pseudo, plec FROM (SELECT K.pseudo pseudo, K.plec plec FROM Kocury_O K WHERE K.PLEC = 'D');


-- grupowanie
SELECT K.funkcja, COUNT(K.pseudo) as koty_w_funkcji FROM Kocury_O K GROUP BY K.funkcja;

SELECT DEREF(kot).pseudo "Kot", count(sluga) "Sługa"
FROM Elita_O E
GROUP BY DEREF(kot).pseudo;

--lista 2 zad 23
SELECT imie, 12 * K.caly_przydzial() "DAWKA ROCZNA", 'powyzej 864' "DAWKA"
FROM Kocury_O K
WHERE 12 * K.caly_przydzial() > 864
  AND myszy_extra IS NOT NULL
UNION
SELECT imie, 12 * K.caly_przydzial() "DAWKA ROCZNA", '864' "DAWKA"
FROM Kocury_O K
WHERE 12 * K.caly_przydzial() = 864
  AND myszy_extra IS NOT NULL
UNION
SELECT imie, 12 * K.caly_przydzial() "DAWKA ROCZNA", 'ponizej 864' "DAWKA"
FROM Kocury_O K
WHERE 12 * K.caly_przydzial() < 864
  AND myszy_extra IS NOT NULL
ORDER BY 2 DESC;


--lista 2 zad 25 (bez warunku na bandy bo nie mam widoku band)
SELECT K.imie, K.funkcja, K.przydzial_myszy
FROM Kocury_O K
WHERE K.przydzial_myszy >= ALL (SELECT 3 * przydzial_myszy
                                FROM Kocury_O T
                                WHERE T.funkcja = 'MILUSIA');

--lista 3 zadanie 37
DECLARE 
    CURSOR koty_sorted IS
        SELECT K.pseudo, K.caly_przydzial() "przydzial"
        FROM Kocury_O K
        ORDER BY 2 DESC;
    kot koty_sorted%ROWTYPE;
BEGIN
    OPEN koty_sorted;
    DBMS_OUTPUT.PUT_LINE('Nr   Pseudonim   Zjada');
    DBMS_OUTPUT.PUT_LINE('----------------------');
    FOR i IN 1..5
    LOOP
        FETCH koty_sorted INTO kot;
        EXIT WHEN koty_sorted%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(TO_CHAR(i) ||'    '|| RPAD(kot.pseudo, 7) || '    ' || TO_CHAR(kot."przydzial"));
    END LOOP;
END;

--lista 3 zadanie 35
DECLARE
    imie_k Kocury.imie%TYPE;
    przydzial_k NUMBER;
    miesiac_dol_k NUMBER;
    znaleziony NUMBER := 0;
BEGIN
    SELECT K.imie, (K.caly_przydzial() * 12), EXTRACT(MONTH FROM w_stadku_od)
    INTO imie_k, przydzial_k, miesiac_dol_k
    FROM Kocury_O K
    WHERE pseudo = UPPER('&podaj_pseudonim');
    IF przydzial_k > 700 THEN DBMS_OUTPUT.PUT_LINE('calkowity roczny przydzial myszy >700'); znaleziony := 1;  END IF;
    IF imie_k LIKE '%A%' THEN DBMS_OUTPUT.PUT_LINE('imie zawiera litere A'); znaleziony := 1; END IF;
    IF miesiac_dol_k = 5 THEN DBMS_OUTPUT.PUT_LINE('maj jest miesiacem przystapienia do stada'); znaleziony := 1; END IF;
    IF znaleziony = 0 THEN DBMS_OUTPUT.PUT_LINE('ten kot nie spelnia zadnego z kryteriow'); END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('nie ma takiego kota');
END;
