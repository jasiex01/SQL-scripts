--zad47
--obiekt kocury i tabela 
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

CREATE OR REPLACE TYPE BODY KocuryO
AS
    MEMBER FUNCTION caly_przydzial RETURN NUMBER IS
    BEGIN
        RETURN NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0);
    END;
    MAP MEMBER FUNCTION info RETURN VARCHAR2 IS
    BEGIN
        RETURN imie || ', ' || plec ||', pseudo:' || pseudo || ' funkcja: '|| funkcja ||', zjada:'|| SELF.caly_przydzial();
    END;
END;

DROP TYPE BODY KocuryO;
ROLLBACK;

CREATE TABLE KocuryT OF KocuryO (
  imie CONSTRAINT kocuryo_imie_nn NOT NULL,
  plec CONSTRAINT kocuryo_plec_ch CHECK(plec IN ('M', 'D')),
  pseudo CONSTRAINT kocuryo_pseudo_pk PRIMARY KEY,
  funkcja CONSTRAINT ko_f_fk REFERENCES Funkcje(funkcja),
  szef SCOPE IS KocuryT,
  w_stadku_od DEFAULT SYSDATE,
  nr_bandy CONSTRAINT ko_nr_fk REFERENCES Bandy(nr_bandy)
);

DROP TABLE KocuryT;
ROLLBACK;

--typ i tabela plebs
CREATE OR REPLACE TYPE PlebsO AS OBJECT
(
    pseudo   VARCHAR2(15),
    kot       REF KocuryO,
    MEMBER FUNCTION get_details RETURN VARCHAR2
);


CREATE OR REPLACE TYPE BODY PlebsO
AS
    MEMBER FUNCTION get_details RETURN VARCHAR2
        IS
        details VARCHAR2(400);
    BEGIN
        SELECT 'IMIE: ' || DEREF(kot).imie || ' PSEUDO ' || DEREF(kot).pseudo INTO details FROM dual;
        RETURN details;
    END;
END;

CREATE TABLE PlebsT OF PlebsO(
    kot SCOPE IS KocuryT CONSTRAINT plebso_kot_nn NOT NULL,
    CONSTRAINT plebso_fk FOREIGN KEY (pseudo) REFERENCES KocuryT(pseudo),
    CONSTRAINT plebso_pk PRIMARY KEY (pseudo));

--typ i tabela elita

CREATE OR REPLACE TYPE ElitaO AS OBJECT
(
    pseudo VARCHAR2(15),
    kot      REF KocuryO,
    slugus   REF PlebsO,
    MEMBER FUNCTION get_sluga RETURN REF PlebsO
);

CREATE OR REPLACE TYPE BODY ElitaO AS
  MEMBER FUNCTION get_sluga RETURN REF PlebsO IS
    BEGIN
      RETURN slugus;
    END;
END;

CREATE TABLE ElitaT OF ElitaO(
    pseudo CONSTRAINT elitao_pseudo_pk PRIMARY KEY,
    kot SCOPE IS KocuryT CONSTRAINT elitao_kot_nn NOT NULL,
    slugus SCOPE IS PlebsT
);

--typ i tabela konta
CREATE OR REPLACE TYPE KontoO AS OBJECT
(
    nr_myszy NUMBER(5),
    data_wprowadzenia DATE,
    data_usuniecia DATE,
    kot REF ElitaO,
    MEMBER PROCEDURE wyprowadz_mysz(dat DATE),
    MAP MEMBER FUNCTION GET_INFO RETURN VARCHAR2
);

CREATE OR REPLACE TYPE BODY KontoO AS
MAP MEMBER FUNCTION GET_INFO RETURN VARCHAR2 IS
    wl ElitaO;
    kocur KocuryO;
    BEGIN
        SELECT DEREF(kot) INTO wl FROM DUAL;
        SELECT DEREF(wl.kot) INTO kocur FROM DUAL;
        RETURN TO_CHAR(data_wprowadzenia) || ' ' || kocur.PSEUDO || TO_CHAR(data_usuniecia);
    END;
    MEMBER PROCEDURE wyprowadz_mysz(dat DATE) IS
    BEGIN
      data_usuniecia := dat;
    END;
END;

CREATE TABLE KontoT OF KontoO (
    nr_myszy CONSTRAINT kontao_n_pk PRIMARY KEY,
    kot SCOPE IS ElitaT CONSTRAINT ko_w_nn NOT NULL,
    data_wprowadzenia CONSTRAINT ko_dw_nn NOT NULL,
    CONSTRAINT ko_dw_du_ch CHECK(data_wprowadzenia <= data_usuniecia)
);

--typ i tabela incydenty
CREATE OR REPLACE TYPE IncydentO AS OBJECT
(
    pseudo VARCHAR2(15),
    kot REF KocuryO,
    imie_wroga VARCHAR2(15),
    data_incydentu DATE,
    opis_incydentu VARCHAR2(100),
    MEMBER FUNCTION czy_aktualny RETURN BOOLEAN,
    MEMBER FUNCTION czy_ma_opis RETURN BOOLEAN
);

CREATE OR REPLACE TYPE BODY IncydentO
AS
    MEMBER FUNCTION czy_ma_opis RETURN BOOLEAN
    IS
    BEGIN
        RETURN opis_incydentu IS NOT NULL;
    END;

    MEMBER FUNCTION czy_aktualny RETURN BOOLEAN
    IS
    BEGIN
        RETURN data_incydentu >= '2010-01-01';
    END;
END;

CREATE TABLE IncydentyT OF IncydentO (
    CONSTRAINT incydento_pk PRIMARY KEY(pseudo, imie_wroga),
    kot SCOPE IS KocuryT CONSTRAINT incydentyo_kot_nn NOT NULL,
    pseudo CONSTRAINT incydentyo_pseudo_fk REFERENCES KocuryT(pseudo),
    imie_wroga CONSTRAINT incydento_imie_wroga_fk REFERENCES Wrogowie(imie_wroga),
    data_incydentu CONSTRAINT incydentyo_data_nn NOT NULL
);

--triggery wprowadzania danych
CREATE OR REPLACE TRIGGER elita_trg
    BEFORE INSERT OR UPDATE
    ON ElitaT
    FOR EACH ROW
DECLARE
    countElita INTEGER;
BEGIN
    SELECT COUNT(PSEUDO) INTO countElita FROM PlebsT P WHERE P.kot = :NEW.kot;
    IF countElita > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Kot należy już do plebsu.');
    END IF;

    SELECT COUNT(PSEUDO) INTO countElita FROM ElitaT E WHERE E.kot = :NEW.kot;
    IF countElita > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Kot należy już do elity.');
    END IF;
END;

CREATE OR REPLACE TRIGGER plebs_trg
    BEFORE INSERT OR UPDATE
    ON PlebsT
    FOR EACH ROW
DECLARE
    countPlebs NUMBER;
BEGIN
    SELECT COUNT(PSEUDO) INTO countPlebs FROM PlebsT P WHERE P.kot = :NEW.kot;
    IF countPlebs > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Kot należy już do plebsu.');
    END IF;

    SELECT COUNT(PSEUDO) INTO countPlebs FROM ElitaT E WHERE E.kot = :NEW.kot;
    IF countPlebs > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Kot należy już do elity.');
    END IF;
END;

DROP TRIGGER elita_trg;
DROP TRIGGER plebs_trg;

--wypelnianie tabel

--tabela KocuryT
DECLARE
    CURSOR koty IS SELECT * FROM KOCURY
        CONNECT BY PRIOR PSEUDO=SZEF
        START WITH SZEF IS NULL;
    sql_string VARCHAR2(1000);
BEGIN
    FOR kot in koty
    LOOP
        sql_string:='DECLARE
            szef REF KocuryO;
            counter NUMBER(2);
        BEGIN
            szef:=NULL;
            SELECT COUNT(*) INTO counter FROM KocuryT T WHERE T.pseudo='''|| kot.szef||''';
            IF (counter>0) THEN
                SELECT REF(T) INTO szef FROM KocuryT T WHERE T.pseudo='''|| kot.szef||''';
            END IF;
            INSERT INTO KocuryT VALUES
                    (KocuryO(''' || kot.imie || ''', ''' || kot.plec || ''', ''' || kot.pseudo || ''', ''' || kot.funkcja
                    || ''','''||kot.w_stadku_od || ''', ''' || kot.przydzial_myszy ||''', ''' || kot.myszy_extra ||
                        ''',''' || kot.nr_bandy ||''',' || 'szef' || '));
        END;';
        DBMS_OUTPUT.PUT_LINE(sql_string);
        EXECUTE IMMEDIATE sql_string;
        END LOOP;
END;

SELECT * FROM KocuryT;
COMMIT;

--tabela IncydentyT
DECLARE
CURSOR zdarzenia IS SELECT * FROM Wrogowie_kocurow;
dyn_sql VARCHAR2(1000);
BEGIN
    FOR zdarzenie IN zdarzenia
    LOOP
      dyn_sql:='DECLARE
            kot REF KocuryO;
        BEGIN
            SELECT REF(K) INTO kot FROM KocuryT K WHERE K.pseudo='''|| zdarzenie.pseudo||''';
            INSERT INTO IncydentyT VALUES
                    (IncydentO(''' || zdarzenie.pseudo || ''',  kot , ''' || zdarzenie.imie_wroga || ''', ''' || zdarzenie.data_incydentu
                    || ''',''' || zdarzenie.opis_incydentu|| '''));
            END;';
       DBMS_OUTPUT.PUT_LINE(dyn_sql);
       EXECUTE IMMEDIATE  dyn_sql;
    END LOOP;
END;

SELECT * FROM IncydentyT;
COMMIT;

--tabela PlebsT
DECLARE
CURSOR koty IS SELECT  pseudo
                    FROM (SELECT K.pseudo pseudo FROM KocuryT K ORDER BY K.caly_przydzial() ASC)
                    WHERE ROWNUM<= (SELECT COUNT(*) FROM KocuryT)/2;
dyn_sql VARCHAR2(1000);
BEGIN
    FOR plebs IN koty
    LOOP
      dyn_sql:='DECLARE
            kot REF KocuryO;
        BEGIN
            SELECT REF(K) INTO kot FROM KocuryT K WHERE K.pseudo='''|| plebs.pseudo||''';
            INSERT INTO PlebsT VALUES
                    (PlebsO('''|| plebs.pseudo ||''',' || 'kot' || '));
            END;';
       EXECUTE IMMEDIATE  dyn_sql;
    END LOOP;
END;

SELECT P.pseudo, P.kot.info() FROM PlebsT P;
COMMIT;

--tabela ElitaT
DECLARE
CURSOR koty IS SELECT PSEUDO FROM (SELECT K.pseudo pseudo FROM KocuryT K ORDER BY K.caly_przydzial() DESC)
    WHERE ROWNUM <= (SELECT COUNT(*) FROM KocuryT)/2;
sql_string VARCHAR2(1000);
num NUMBER:=1;
BEGIN
    FOR elita in koty
    LOOP
        sql_string:='DECLARE
                        kot REF KocuryO;
                        sluga REF PlebsO;
                    BEGIN
                        SELECT REF(K) INTO kot FROM KocuryT K WHERE K.pseudo=''' || elita.pseudo || ''';' ||
                       'SELECT plebs INTO sluga FROM (SELECT REF(P) plebs, rownum num FROM PlebsT P) WHERE NUM=' || num ||';'||
                    'INSERT INTO ElitaT VALUES (ElitaO(''' || elita.pseudo ||''', kot, sluga)); END;';
        EXECUTE IMMEDIATE  sql_string;
        num:=num+1;
        END LOOP;
END;

SELECT E.kot.pseudo, E.slugus.pseudo, E.pseudo, E.kot.caly_przydzial() FROM ElitaT E;
COMMIT;

--tabela KontoT
CREATE SEQUENCE nr_myszy;

DECLARE
CURSOR koty IS SELECT pseudo FROM ElitaT;
sql_string VARCHAR2(1000);
BEGIN
    FOR elita IN koty
    LOOP
      sql_string:='DECLARE
            kot REF ElitaO;
            dataw DATE:=SYSDATE;
        BEGIN
            SELECT REF(E) INTO kot FROM ElitaT E WHERE E.pseudo='''|| elita.pseudo||''';
            INSERT INTO KontoT VALUES
                    (KontoO(nr_myszy.NEXTVAL, dataw, NULL, kot));
        END;';
       DBMS_OUTPUT.PUT_LINE(sql_string);
       EXECUTE IMMEDIATE  sql_string;
    END LOOP;
END;

SELECT * FROM KontoT;
COMMIT;

--przyklady zastosowan
--metody
SELECT DEREF(kot).info() FROM PLEBST;
SELECT DEREF(kot).info(), DEREF(slugus).get_details() FROM ELitaT;
SELECT data_usuniecia, data_wprowadzenia, DEREF(kot).pseudo, DEREF(kot).get_sluga().get_details() FROM KONTOT;
SELECT K.IMIE, K.PLEC, K.caly_przydzial() FROM KocuryT K WHERE K.caly_przydzial() > 90;
--podzapytanie

SELECT pseudo, plec FROM (SELECT K.pseudo pseudo, K.plec plec FROM KocuryT K WHERE K.PLEC = 'D');

SELECT K.info() FROM KocuryT K WHERE K.caly_przydzial() <= (
    SELECT AVG(K1.caly_przydzial())
    FROM KocuryT K1
    );

--grupowanie
SELECT K.funkcja, COUNT(K.pseudo) as koty_w_funkcji FROM KocuryT K GROUP BY K.funkcja;

SELECT DEREF(kot).pseudo "Kot", count(slugus) "Sługa"
FROM ElitaT E
GROUP BY DEREF(kot).pseudo;


--zadania z poprzednich list zrealizowane na tablicach obiektowych


--lista 2 zad 23
SELECT imie, 12 * K.caly_przydzial() "DAWKA ROCZNA", 'powyzej 864' "DAWKA"
FROM KocuryT K
WHERE 12 * K.caly_przydzial() > 864
  AND myszy_extra IS NOT NULL
UNION
SELECT imie, 12 * K.caly_przydzial() "DAWKA ROCZNA", '864' "DAWKA"
FROM KocuryT K
WHERE 12 * K.caly_przydzial() = 864
  AND myszy_extra IS NOT NULL
UNION
SELECT imie, 12 * K.caly_przydzial() "DAWKA ROCZNA", 'ponizej 864' "DAWKA"
FROM KocuryT K
WHERE 12 * K.caly_przydzial() < 864
  AND myszy_extra IS NOT NULL
ORDER BY 2 DESC;

--lista 2 zad 25 (bez warunku na bandy bo nie mam band obiektowo)
SELECT K.imie, K.funkcja, K.przydzial_myszy
FROM KocuryT K
WHERE K.przydzial_myszy >= ALL (SELECT 3 * przydzial_myszy
                                FROM KocuryT T
                                WHERE T.funkcja = 'MILUSIA');

--lista 3 zadanie 37
DECLARE 
    CURSOR koty_sorted IS
        SELECT K.pseudo, K.caly_przydzial() "przydzial"
        FROM KocuryT K
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
    FROM KocuryT K
    WHERE pseudo = UPPER('&podaj_pseudonim');
    IF przydzial_k > 700 THEN DBMS_OUTPUT.PUT_LINE('calkowity roczny przydzial myszy >700'); znaleziony := 1;  END IF;
    IF imie_k LIKE '%A%' THEN DBMS_OUTPUT.PUT_LINE('imie zawiera litere A'); znaleziony := 1; END IF;
    IF miesiac_dol_k = 5 THEN DBMS_OUTPUT.PUT_LINE('maj jest miesiacem przystapienia do stada'); znaleziony := 1; END IF;
    IF znaleziony = 0 THEN DBMS_OUTPUT.PUT_LINE('ten kot nie spelnia zadnego z kryteriow'); END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('nie ma takiego kota');
END;

--lista2 zad 19a
SELECT K.imie "Imie",
       K.funkcja "Funkcja",
       K.szef.imie "Szef 1",
       K.szef.szef.imie "Szef 2",
       K.szef.szef.szef.imie "Szef 3"
FROM KocuryT K
WHERE K.funkcja IN ('KOT', 'MILUSIA');


--zadanie 49
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

--stwórz tabelę myszy
BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE MYSZY(
    nr_myszy NUMBER(7) CONSTRAINT myszy_pk PRIMARY KEY,
    lowca VARCHAR2(15) CONSTRAINT m_lowca_fk REFERENCES Kocury(pseudo),
    zjadacz VARCHAR2(15) CONSTRAINT m_zjadacz_fk REFERENCES Kocury(pseudo),
    waga_myszy NUMBER(3) CONSTRAINT waga_myszy_ogr CHECK (waga_myszy BETWEEN 10 AND 85),
    data_zlowienia DATE CONSTRAINT dat_nn NOT NULL,
    data_wydania DATE,
    CONSTRAINT daty_popr CHECK (data_zlowienia <= data_wydania))';
END;

CREATE SEQUENCE myszy_seq;

--stworz ewidencje myszy od 2004-01-01
DECLARE
    data_start DATE := '2004-01-01';
    data_ostatniej_srody DATE := NEXT_DAY(LAST_DAY(data_start) - 7, 'ŚRODA');
    data_koncowa DATE := '2023-01-22';
    myszy_mies NUMBER(5);

    TYPE tp IS TABLE OF Kocury.pseudo%TYPE;
    tab_pseudo tp := tp();

    TYPE tm IS TABLE OF NUMBER(4);
    tab_myszy tm := tm();

    TYPE myszy_rek IS TABLE OF Myszy%ROWTYPE INDEX BY BINARY_INTEGER;
    myszki myszy_rek;
    nr_myszy BINARY_INTEGER := 0;
    indeks_zjadacza NUMBER(2);

BEGIN
    LOOP
        EXIT WHEN data_start >= data_koncowa;
            --zadbanie o dobrą date
            IF data_start < NEXT_DAY(LAST_DAY(data_start), 'ŚRODA') - 7 THEN
                data_ostatniej_srody := LEAST(NEXT_DAY(LAST_DAY(data_start), 'ŚRODA') - 7, data_koncowa);
            ELSE
                data_ostatniej_srody :=
                        LEAST(NEXT_DAY(LAST_DAY(ADD_MONTHS(data_start, 1)), 'ŚRODA') - 7, data_koncowa);
            END IF;

            --pobranie sumy przydzialu dla kotow ktore wtedy byly juz w stadku
            SELECT SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0))
            INTO myszy_mies
            FROM KOCURY
            WHERE W_STADKU_OD < data_ostatniej_srody;

            -- pobranie pseudonimow oraz przydzialu myszy do odp tabel
            SELECT pseudo,
                   NVL(PRZYDZIAL_MYSZY, 0) + NVL(MYSZY_EXTRA, 0)
                   BULK COLLECT INTO tab_pseudo, tab_myszy
            FROM KOCURY
            WHERE W_STADKU_OD < data_ostatniej_srody;

            indeks_zjadacza := 1;
            --ile przypada dla kazdego kotka
            myszy_mies := CEIL(myszy_mies / tab_pseudo.COUNT);

            FOR i IN 1..(myszy_mies * tab_pseudo.COUNT)
                LOOP
                    nr_myszy := nr_myszy + 1;
                    myszki(nr_myszy).NR_MYSZY := nr_myszy;
                    myszki(nr_myszy).LOWCA := tab_pseudo(MOD(i, tab_pseudo.COUNT) + 1);

                    IF data_ostatniej_srody != data_koncowa THEN
                        myszki(nr_myszy).DATA_WYDANIA := data_ostatniej_srody;

                        --przydzial myszy zgdonie z dołączeniem oraz z przydzialem mysz
                        IF tab_myszy(indeks_zjadacza) = 0 THEN
                            indeks_zjadacza := indeks_zjadacza + 1;
                        ELSE
                            tab_myszy(indeks_zjadacza) := tab_myszy(indeks_zjadacza) - 1;
                        END IF;

                        --nadwyzki losowo
                        IF indeks_zjadacza > tab_myszy.COUNT THEN
                            indeks_zjadacza := DBMS_RANDOM.VALUE(1, tab_myszy.COUNT);
                        END IF;
                        myszki(nr_myszy).zjadacz := tab_pseudo(indeks_zjadacza);
                    END IF;
                    myszki(nr_myszy).waga_myszy := DBMS_RANDOM.VALUE(15,45);
                    myszki(nr_myszy).data_zlowienia := data_start + MOD(nr_myszy, TRUNC(data_ostatniej_srody) - TRUNC(data_start));
                END LOOP;
                data_start := data_ostatniej_srody + 1;
                data_ostatniej_srody := NEXT_DAY(LAST_DAY(ADD_MONTHS(data_start, 1)) - 7, 'ŚRODA');
            IF data_ostatniej_srody > data_koncowa THEN
                data_ostatniej_srody := data_koncowa;
            END IF;
    END LOOP;

    FORALL i in 1..myszki.COUNT
        INSERT INTO Myszy(nr_myszy, lowca, zjadacz, waga_myszy, data_zlowienia, data_wydania)
        VALUES (myszy_seq.NEXTVAL, myszki(i).LOWCA, myszki(i).ZJADACZ, myszki(i).WAGA_MYSZY, myszki(i).DATA_ZLOWIENIA,
                myszki(i).DATA_WYDANIA);
END;

--tworzenie tabeli z myszami dla kazdego kota
BEGIN
   FOR kot in (SELECT pseudo FROM Kocury)
    LOOP
       EXECUTE IMMEDIATE 'CREATE TABLE Myszy_kota_' || kot.pseudo || '(' ||
           'nr_myszy NUMBER(7) CONSTRAINT myszy_kota_pk_' || kot.pseudo || ' PRIMARY KEY,' ||
           'waga_myszy NUMBER(3) CONSTRAINT waga_myszy_' || kot.pseudo || ' CHECK (waga_myszy BETWEEN 15 AND 45),' ||
           'data_zlowienia DATE CONSTRAINT data_zlowienia_nn_' || kot.pseudo ||' NOT NULL)' ;
       END LOOP;
END;

BEGIN
   FOR kot in (SELECT pseudo FROM Kocury)
    LOOP
       EXECUTE IMMEDIATE 'CREATE TABLE Myszy_kota_' || kot.pseudo || '(' ||
           'nr_myszy NUMBER(7) CONSTRAINT myszy_kota_pk_' || kot.pseudo || ' PRIMARY KEY,' ||
           'waga_myszy NUMBER(3) CONSTRAINT waga_myszy_' || kot.pseudo || ' CHECK (waga_myszy BETWEEN 10 AND 85),' ||
           'data_zlowienia DATE CONSTRAINT data_zlowienia_nn_' || kot.pseudo ||' NOT NULL)' ;
       END LOOP;
END;

--procedura przyjecia myszy na stan
CREATE OR REPLACE PROCEDURE przyjmij_na_stan(kotPseudo Kocury.pseudo%TYPE, data_zlowienia DATE)
AS
    TYPE tw IS TABLE OF NUMBER(3);
    tab_wagi tw := tw();
    TYPE tn IS TABLE OF NUMBER(7);
    tab_nr tn := tn();
    ile_kotow NUMBER(2);
    nie_ma_kota EXCEPTION;
    zla_data EXCEPTION;
    brak_myszy_o_dacie EXCEPTION;
BEGIN
    IF data_zlowienia > SYSDATE  OR data_zlowienia = NEXT_DAY(LAST_DAY(data_zlowienia)-7, 'ŚRODA')
        THEN RAISE zla_data;
    END IF;

    SELECT COUNT(K.pseudo) INTO ile_kotow FROM KOCURY K  WHERE K.pseudo = UPPER(kotPseudo);
    IF ile_kotow = 0 THEN RAISE nie_ma_kota; END IF;

    EXECUTE IMMEDIATE 'SELECT nr_myszy, waga_myszy FROM Myszy_kota_'|| kotPseudo || ' WHERE data_zlowienia= ''' || data_zlowienia || ''''
        BULK COLLECT INTO tab_nr, tab_wagi;
    IF tab_nr.COUNT = 0 THEN
        RAISE brak_myszy_o_dacie;
    end if;

    FORALL i in 1..tab_nr.COUNT
        INSERT INTO Myszy VALUES (tab_nr(i), UPPER(kotPseudo), NULL, tab_wagi(i),DATA_ZLOWIENIA, NULL);

    EXECUTE IMMEDIATE 'DELETE FROM Myszy_kota_' || kotPseudo || ' WHERE data_zlowienia= ''' || data_zlowienia || '''';
    EXCEPTION
        WHEN nie_ma_kota THEN DBMS_OUTPUT.PUT_LINE('BRAK KOTA O PSEUDONIMIE Myszy_kota_'|| UPPER(kotPseudo));
        WHEN zla_data THEN DBMS_OUTPUT.PUT_LINE('ZLA DATA');
        WHEN brak_myszy_o_dacie THEN DBMS_OUTPUT.PUT_LINE('BRAK MYSZY W ZLOWIONEJ DACIE');
END;


--procedura do wyplacania myszy
CREATE OR REPLACE PROCEDURE Wyplata
AS
    TYPE tp IS TABLE OF Kocury.pseudo%TYPE;
        tab_pseudo tp := tp();
    TYPE tm is TABLE OF NUMBER(4);
        tab_myszy tm := tm();
    TYPE tn IS TABLE OF NUMBER(7);
        tab_nr tn := tn();
    TYPE tz IS TABLE OF Kocury.pseudo%TYPE INDEX BY BINARY_INTEGER;
        tab_zjadaczy tz;
    TYPE tw IS TABLE OF Myszy%ROWTYPE;
        tab_wierszy tw;
    liczba_najedzonych NUMBER(2) := 0;
    indeks_zjadacza NUMBER(2) := 1;
    ile NUMBER(5);
    powtorna_wyplata EXCEPTION;
BEGIN
    --wedlug hierarchi
    SELECT pseudo, NVL(przydzial_myszy,0) + NVL(myszy_extra, 0)
        BULK COLLECT INTO tab_pseudo, tab_myszy
    FROM Kocury CONNECT BY PRIOR pseudo = szef
    START WITH SZEF IS NULL
    ORDER BY level;

    SELECT COUNT(NR_MYSZY)
        INTO ile
    FROM MYSZY
    WHERE DATA_WYDANIA = NEXT_DAY(LAST_DAY(TRUNC(SYSDATE))-7, 'ŚRODA');
    
    --jezeli sa myszy z aktulana data wyplaty to znaczy ze byla juz dokonana wyplata
    DBMS_OUTPUT.PUT_LINE('ile: '||ile);
    IF ile > 0 THEN
        RAISE powtorna_wyplata;
    end if;
    --wszystkie niezjedzone myszy
    SELECT *
        BULK COLLECT INTO tab_wierszy
    FROM Myszy
    WHERE DATA_WYDANIA IS NULL;
    --przydzial niezjedzonych myszy zgodnie z hierarchia
    FOR i IN 1..tab_wierszy.COUNT
        LOOP
            --jak kot jest najedzonu
            WHILE tab_myszy(indeks_zjadacza) = 0 AND liczba_najedzonych < tab_pseudo.COUNT
                LOOP
                    liczba_najedzonych := liczba_najedzonych + 1;
                    indeks_zjadacza := MOD(indeks_zjadacza + 1, tab_pseudo.COUNT) + 1;
                END LOOP;
            --jezeli wszyscy juz dostali to daj tygrysowi
            IF liczba_najedzonych = tab_pseudo.COUNT THEN
                tab_zjadaczy(i) := 'TYGRYS';
            --jezeli nie to daj kolejnemu w kolejce
            ELSE
                indeks_zjadacza := MOD(indeks_zjadacza + 1, tab_pseudo.COUNT) + 1;
                tab_zjadaczy(i) := tab_pseudo(indeks_zjadacza);
                tab_myszy(indeks_zjadacza) := tab_myszy(indeks_zjadacza) - 1;
            END IF;
            --jezeli data zlowienia jest po ostatniej srodzie miesiaca to wyplaca sie ja w kolejnym miesiacu
            IF NEXT_DAY(LAST_DAY(tab_wierszy(i).DATA_ZLOWIENIA)-7, 'ŚRODA') < tab_wierszy(i).DATA_ZLOWIENIA THEN
                tab_wierszy(i).DATA_WYDANIA := NEXT_DAY(LAST_DAY(ADD_MONTHS(tab_wierszy(i).DATA_ZLOWIENIA,1))-7, 'ŚRODA');
            ELSE
                tab_wierszy(i).DATA_WYDANIA := NEXT_DAY(LAST_DAY(tab_wierszy(i).DATA_ZLOWIENIA)-7, 'ŚRODA');
            END IF;
        END LOOP;
    FORALL i IN 1..tab_wierszy.COUNT
            UPDATE Myszy SET data_wydania=tab_wierszy(i).DATA_WYDANIA , zjadacz=tab_zjadaczy(i)
            WHERE nr_myszy=tab_wierszy(i).NR_MYSZY;
    EXCEPTION
            WHEN powtorna_wyplata THEN DBMS_OUTPUT.PUT_LINE('POWOTRNA WYPLATA');
END;

--testy
INSERT INTO Myszy_kota_DAMA VALUES(myszy_seq.nextval, 60, '2022-12-28');

INSERT INTO MYSZY_KOTA_TYGRYS VALUES(myszy_seq.nextval, 69, '2022-12-01');

INSERT INTO MYSZY_KOTA_TYGRYS VALUES(myszy_seq.nextval, 29, '2022-12-01');
INSERT INTO MYSZY_KOTA_TYGRYS VALUES(myszy_seq.nextval, 78, '2022-12-20');
INSERT INTO MYSZY_KOTA_TYGRYS VALUES(myszy_seq.nextval, 78, '2022-12-30');
INSERT INTO MYSZY_KOTA_TYGRYS VALUES(myszy_seq.nextval, 28, '2022-12-30');
BEGIN
    przyjmij_na_stan('Dama', '2022-12-28');
end;

BEGIN
    przyjmij_na_stan('TYGRYS', '2022-12-01');
end;

SELECT
TO_CHAR(NEXT_DAY(LAST_DAY(SYSDATE)-7, 'ŚRODA'))
FROM DUAL;

BEGIN
    Wyplata();
END;

SELECT * FROM MYSZY_KOTA_TYGRYS;
SELECT COUNT(*) FROM Myszy WHERE EXTRACT(YEAR FROM data_wydania)=2022 AND zjadacz!='TYGRYS';


--usuwanie
BEGIN
    FOR kot IN (SELECT pseudo FROM Kocury)
    LOOP
        EXECUTE IMMEDIATE 'DROP TABLE Myszy_kota_' || kot.pseudo;
        END LOOP;
END;

TRUNCATE TABLE Myszy;
DROP TABLE Myszy;
DROP SEQUENCE myszy_seq;

--do usuwania:
DROP TABLE KocuryT CASCADE CONSTRAINTS;
DROP TABLE PlebsT CASCADE CONSTRAINTS;
DROP TABLE ElitaT CASCADE CONSTRAINTS;
DROP TABLE KontoT CASCADE CONSTRAINTS;
DROP TABLE IncydentyT CASCADE CONSTRAINTS;
DROP TYPE BODY KocuryO ;
DROP TYPE KocuryO FORCE;
DROP TYPE BODY ElitaO;
DROP TYPE ElitaO FORCE;
DROP TYPE BODY PlebsO;
DROP TYPE PlebsO FORCE;
DROP TYPE BODY KontoO;
DROP TYPE KontoO FORCE;
DROP TYPE BODY IncydentO;
DROP TYPE IncydentO FORCE;

SET serveroutput ON;
DROP TYPE KocuryO;
ROLLBACK;