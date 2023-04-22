--zad 34
DECLARE 
    funkcja_k Kocury.funkcja%TYPE;
BEGIN
    SELECT funkcja INTO funkcja_k FROM Kocury
    WHERE funkcja = UPPER('&nazwa_funkcji');
    DBMS_OUTPUT.PUT_LINE('Znaleziono kocura, ktory pelni funkcje: ' || funkcja_k);
EXCEPTION
    WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('Nie znaleziono zadnego kocura o podanej funkcji');
    WHEN TOO_MANY_ROWS THEN DBMS_OUTPUT.PUT_LINE('Znaleziono kocury, ktore pelnia funkcje: ' || funkcja_k);
END;

--zad 35
DECLARE
    imie_k Kocury.imie%TYPE;
    przydzial_k NUMBER;
    miesiac_dol_k NUMBER;
    znaleziony NUMBER := 0;
BEGIN
    SELECT imie, (przydzial_myszy + NVL(myszy_extra, 0) * 12), EXTRACT(MONTH FROM w_stadku_od)
    INTO imie_k, przydzial_k, miesiac_dol_k
    FROM Kocury
    WHERE pseudo = UPPER('&podaj_pseudonim');
    IF przydzial_k > 700 THEN DBMS_OUTPUT.PUT_LINE('calkowity roczny przydzial myszy >700'); znaleziony := 1;  END IF;
    IF imie_k LIKE '%A%' THEN DBMS_OUTPUT.PUT_LINE('imie zawiera litere A'); znaleziony := 1; END IF;
    IF miesiac_dol_k = 5 THEN DBMS_OUTPUT.PUT_LINE('maj jest miesiacem przystapienia do stada'); znaleziony := 1; END IF;
    IF znaleziony = 0 THEN DBMS_OUTPUT.PUT_LINE('ten kot nie spelnia zadnego z kryteriow'); END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('nie ma takiego kota');
END;
    
--zad 36
DECLARE 
    CURSOR kolejka IS
        SELECT pseudo, NVL(przydzial_myszy,0) przydzial, Funkcje.max_myszy maks
        FROM Kocury JOIN Funkcje ON Kocury.funkcja = Funkcje.funkcja
        ORDER BY 2
        FOR UPDATE OF przydzial_myszy;
    zmiany NUMBER := 0;
    suma NUMBER := 0;
    kot kolejka%ROWTYPE;
BEGIN
    SELECT SUM(NVL(przydzial_myszy,0)) INTO suma
    FROM Kocury;
    
    WHILE suma <= 1050
        LOOP
            OPEN kolejka;
            LOOP
                FETCH kolejka INTO kot;
                EXIT WHEN kolejka%NOTFOUND;
                IF ROUND(kot.przydzial * 1.1) <= kot.maks THEN
                    UPDATE Kocury
                    SET przydzial_myszy = ROUND(przydzial_myszy * 1.1)
                    WHERE CURRENT OF kolejka;
                    suma := suma + ROUND(kot.przydzial * 0.1);
                    zmiany := zmiany + 1;
                ELSIF kot.przydzial <> kot.maks THEN
                    UPDATE Kocury
                    SET przydzial_myszy = kot.maks
                    WHERE CURRENT OF kolejka;
                    suma := suma + kot.maks - kot.przydzial;
                    zmiany := zmiany + 1;
                END IF;
            END LOOP;
            CLOSE kolejka;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('Calk. przydzial w stadku - ' || TO_CHAR(suma) || ' L zmian - ' || TO_CHAR(zmiany));
END;

SELECT imie, przydzial_myszy "Myszki po podwyzce"
FROM Kocury
ORDER BY 2 DESC;

ROLLBACK;

--zad 37
DECLARE 
    CURSOR koty_sorted IS
        SELECT pseudo, NVL(przydzial_myszy,0) +  NVL(myszy_extra, 0) przydzial
        FROM Kocury
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
        DBMS_OUTPUT.PUT_LINE(TO_CHAR(i) ||'    '|| RPAD(kot.pseudo, 7) || '    ' || TO_CHAR(kot.przydzial));
    END LOOP;
END;

--zad 38
DECLARE
    liczba_przelozonych     NUMBER := 5;
    max_liczba_przelozonych NUMBER;
    pseudo_k        Kocury.pseudo%TYPE;
    imie_k           Kocury.pseudo%TYPE;
    pseudo_szefa         Kocury.szef%TYPE;
    CURSOR podwladni IS SELECT pseudo, imie, szef
                        FROM Kocury
                        WHERE Funkcja IN ('MILUSIA', 'KOT');
BEGIN
    SELECT MAX(LEVEL) - 1
    INTO max_liczba_przelozonych
    FROM Kocury
    CONNECT BY PRIOR szef = pseudo
    START WITH funkcja IN ('KOT', 'MILUSIA');
    liczba_przelozonych := LEAST(max_liczba_przelozonych, liczba_przelozonych);

    DBMS_OUTPUT.PUT(RPAD('IMIE ', 15));
    FOR COUNTER IN 1..liczba_przelozonych
        LOOP
            DBMS_OUTPUT.PUT(RPAD('|  SZEF ' || COUNTER, 15));
        END LOOP;
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 15 * (liczba_przelozonych + 1), '-'));

    FOR kot IN podwladni
        LOOP
            DBMS_OUTPUT.PUT(RPAD(kot.imie, 15));
            pseudo_szefa := kot.szef;
            FOR COUNTER IN 1..liczba_przelozonych
                LOOP
                    IF pseudo_szefa IS NULL THEN
                        DBMS_OUTPUT.PUT(RPAD('|  ', 15));
                    ELSE
                        BEGIN
                            SELECT imie, pseudo, szef
                            INTO imie_k, pseudo_k, pseudo_szefa
                            FROM Kocury
                            WHERE pseudo = pseudo_szefa;
                            DBMS_OUTPUT.PUT(RPAD('|  ' || imie_k, 15));
                        END;
                    END IF;
                END LOOP;
            DBMS_OUTPUT.PUT_LINE('');
        END LOOP;
END;

--zad 39
DECLARE
    nr_ban NUMBER:= '&nr_bandy';
    naz_ban BANDY.NAZWA%TYPE := '&nazwa_bandy';
    ter BANDY.TEREN%TYPE := '&teren_bandy';
    liczba_znalezionych NUMBER;
    juz_istnieje_exc EXCEPTION;
    zly_numer_bandy_exc EXCEPTION;
    wiadomosc_exc VARCHAR2(30) := '';
BEGIN
    IF nr_ban <= 0 THEN RAISE zly_numer_bandy_exc;
    END IF;
    
    SELECT COUNT(*) INTO liczba_znalezionych
    FROM Bandy
    WHERE nr_bandy = nr_ban;
    IF liczba_znalezionych > 0 
        THEN wiadomosc_exc := wiadomosc_exc || ' ' || nr_ban || ',';
    END IF;
    
    SELECT COUNT(*) INTO liczba_znalezionych
    FROM Bandy
    WHERE nazwa = UPPER(naz_ban);
    IF liczba_znalezionych > 0 
        THEN wiadomosc_exc := wiadomosc_exc || ' ' || naz_ban || ',';
    END IF;
    
    SELECT COUNT(*) INTO liczba_znalezionych
    FROM Bandy
    WHERE teren = UPPER(ter);
    IF liczba_znalezionych > 0 
        THEN wiadomosc_exc := wiadomosc_exc || ' ' || ter || ',';
    END IF;
    
    IF LENGTH(wiadomosc_exc) > 0 THEN
        RAISE juz_istnieje_exc;
    END IF;
    
    INSERT INTO Bandy(nr_bandy, nazwa, teren) VALUES (nr_ban, naz_ban, ter);
    
EXCEPTION
    WHEN zly_numer_bandy_exc THEN
        DBMS_OUTPUT.PUT_LINE('Nr bandy musi byc liczba dodatnia');
    WHEN juz_istnieje_exc THEN
        DBMS_OUTPUT.PUT_LINE(TRIM(TRAILING ',' FROM wiadomosc_exc) || ': juz istnieje');
END;

--zad 40 i 44
CREATE OR REPLACE PACKAGE pakiet IS
    FUNCTION ObliczPodatek(pseudonim Kocury.pseudo%TYPE) RETURN NUMBER;
    PROCEDURE DodajBande(nr_ban Bandy.nr_bandy%TYPE, naz_ban Bandy.nazwa%TYPE, ter BANDY.TEREN%TYPE);
END pakiet;
/
CREATE OR REPLACE PACKAGE BODY pakiet IS
    FUNCTION ObliczPodatek(pseudonim Kocury.pseudo%TYPE) RETURN NUMBER
        IS
        wysokosc_podatku NUMBER := 0;
        ile NUMBER := 0;
        BEGIN
            SELECT CEIL(0.05 * (NVL(przydzial_myszy,0) + NVL(myszy_extra,0)))
            INTO wysokosc_podatku
            FROM Kocury
            WHERE pseudo = pseudonim;
            
            SELECT COUNT(pseudo) 
            INTO ile 
            FROM Kocury
            WHERE szef = pseudonim;
            
            IF ile = 0 THEN
                wysokosc_podatku := wysokosc_podatku + 2;
            END IF;
            
            SELECT COUNT(pseudo) INTO ile FROM Wrogowie_kocurow WHERE pseudo = pseudonim;
            if ile = 0 THEN
                wysokosc_podatku := wysokosc_podatku + 1;
            END IF;
            SELECT NVL(myszy_extra,0) INTO ile FROM Kocury WHERE pseudo = pseudonim;
            IF ile = 0 THEN
                wysokosc_podatku := wysokosc_podatku - 1;
            END IF;
        RETURN wysokosc_podatku;
        END;

    PROCEDURE DodajBande(nr_ban BANDY.NR_BANDY%TYPE,
                                    naz_ban BANDY.NAZWA%TYPE,
                                    ter BANDY.TEREN%TYPE)
        IS
            liczba_znalezionych NUMBER;
            juz_istnieje_exc EXCEPTION;
            zly_numer_bandy_exc EXCEPTION;
            wiadomosc_exc    VARCHAR2(30) := '';
        BEGIN
            IF nr_ban < 0 THEN 
                RAISE zly_numer_bandy_exc;
            END IF;
        
            SELECT COUNT(*) 
            INTO liczba_znalezionych
            FROM Bandy
            WHERE nr_bandy = nr_ban;
            
            IF liczba_znalezionych <> 0 
                THEN wiadomosc_exc := wiadomosc_exc || ' ' || nr_ban || ',';
            END IF;
        
            SELECT COUNT(*) INTO liczba_znalezionych
            FROM Bandy
            WHERE nazwa = naz_ban;
            IF liczba_znalezionych <> 0 
                THEN wiadomosc_exc := wiadomosc_exc || ' ' || naz_ban || ',';
            END IF;
            
            SELECT COUNT(*) INTO liczba_znalezionych
            FROM Bandy
            WHERE teren = ter;
            IF liczba_znalezionych <> 0 
                THEN wiadomosc_exc := wiadomosc_exc || ' ' || ter || ',';
            END IF;
            
            IF LENGTH(wiadomosc_exc) > 0 THEN
                RAISE juz_istnieje_exc;
            END IF;
        
            INSERT INTO BANDY(NR_BANDY, NAZWA, TEREN) VALUES (nr_ban, naz_ban, ter);
        EXCEPTION
            WHEN zly_numer_bandy_exc THEN
                DBMS_OUTPUT.PUT_LINE('Nr bandy musi byc liczba dodatnia');
            WHEN juz_istnieje_exc THEN
                DBMS_OUTPUT.PUT_LINE(TRIM(TRAILING ',' FROM wiadomosc_exc) || ': juz istnieje');
    END;
    
END pakiet;
/

EXECUTE pakiet.DodajBande(1, 'PUSZYSCI', 'POLE');
EXECUTE pakiet.DodajBande(2, 'CZARNI RYCERZE', 'POLE');
EXECUTE pakiet.DodajBande(1, 'SZEFOSTWO', 'NOWE');
EXECUTE pakiet.DodajBande(10, 'NOWI', 'NOWE');
SELECT * FROM bandy;

ROLLBACK;
BEGIN
        FOR kot IN (SELECT pseudo FROM Kocury)
        LOOP
            DBMS_OUTPUT.PUT_LINE(RPAD(kot.pseudo, 8) || ' podatek rowny ' || pakiet.ObliczPodatek(kot.pseudo));
        END LOOP;
END;

--zad 41
CREATE OR REPLACE TRIGGER NrBandySetter
    BEFORE INSERT 
    ON Bandy
    FOR EACH ROW
DECLARE
    ostatni_nr Bandy.nr_bandy%TYPE;
BEGIN
    SELECT MAX(nr_bandy)
    INTO ostatni_nr
    FROM BANDY;
    :NEW.nr_bandy := ostatni_nr + 1;
END;

--zad 42
--wyzwalacze i pakiet
CREATE OR REPLACE PACKAGE wirus IS
    kara NUMBER := 0;
    nagroda NUMBER := 0;
    przydzial_tygrysa Kocury.przydzial_myszy%TYPE;
END;
/
CREATE OR REPLACE TRIGGER wirus_sczytaj_tygrysa
    BEFORE UPDATE OF przydzial_myszy
    ON KOCURY
DECLARE
BEGIN
    SELECT przydzial_myszy INTO wirus.przydzial_tygrysa FROM KOCURY WHERE pseudo = 'TYGRYS';
END;
/
CREATE OR REPLACE TRIGGER wirus_dodaj_milusiom
    BEFORE UPDATE OF przydzial_myszy
    ON Kocury
    FOR EACH ROW
DECLARE
BEGIN
    IF :NEW.funkcja = 'MILUSIA' THEN
        IF :NEW.przydzial_myszy <= :OLD.przydzial_myszy THEN
            DBMS_OUTPUT.PUT_LINE('brak zmiany');
            :NEW.przydzial_myszy := :OLD.przydzial_myszy;
        ELSIF :NEW.przydzial_myszy - :OLD.przydzial_myszy < 0.1 * wirus.przydzial_tygrysa THEN
            DBMS_OUTPUT.PUT_LINE('podwyzka mniejsza niz 10% Tygrysa');
            :NEW.przydzial_myszy := :NEW.przydzial_myszy + ROUND(0.1 * wirus.przydzial_tygrysa);
            :NEW.myszy_extra := NVL(:NEW.myszy_extra, 0) + 5;
            wirus.kara := wirus.kara + ROUND(0.1 * wirus.przydzial_tygrysa);
        ELSE
            wirus.nagroda := wirus.nagroda + 5;
        END IF;
    END IF;
END;
/
CREATE OR REPLACE TRIGGER wirus_zmien_tygrysowi
    AFTER UPDATE OF przydzial_myszy
    ON Kocury
DECLARE
    przydzial Kocury.przydzial_myszy%TYPE;
    ekstra    Kocury.myszy_extra%TYPE;
BEGIN
    SELECT przydzial_myszy, myszy_extra
    INTO przydzial, ekstra
    FROM KOCURY
    WHERE pseudo = 'TYGRYS';
    
    przydzial := przydzial - wirus.kara;
    ekstra := ekstra + wirus.nagroda;
    
    IF wirus.kara <> 0 OR wirus.nagroda <> 0 THEN
        wirus.kara := 0;
        wirus.nagroda := 0;
        UPDATE Kocury
        SET przydzial_myszy = przydzial,
            myszy_extra = ekstra
        WHERE pseudo = 'TYGRYS';
    END IF;
END;

UPDATE KOCURY
SET PRZYDZIAL_MYSZY = 50
WHERE PSEUDO = 'PUSZYSTA';

UPDATE Kocury
SET przydzial_myszy = przydzial_myszy + 1
WHERE funkcja = 'MILUSIA';

UPDATE Kocury
SET przydzial_myszy = przydzial_myszy + 20
WHERE funkcja = 'MILUSIA';

SELECT *
FROM KOCURY
WHERE PSEUDO IN ('PUSZYSTA', 'TYGRYS');

ROLLBACK;

DROP TRIGGER wirus_sczytaj_tygrysa;
DROP TRIGGER wirus_dodaj_milusiom;
DROP TRIGGER wirus_zmien_tygrysowi;
DROP PACKAGE wirus;

--compound trigger
CREATE OR REPLACE TRIGGER wirus_compound
    FOR UPDATE OF przydzial_myszy
    ON Kocury
    COMPOUND TRIGGER
    przydzial_tygrysa Kocury.przydzial_myszy%TYPE;
    ekstra Kocury.myszy_extra%TYPE;
    kara NUMBER:=0;
    nagroda NUMBER:=0;
    
BEFORE STATEMENT IS
BEGIN
    SELECT przydzial_myszy INTO przydzial_tygrysa
    FROM KOCURY
    WHERE pseudo = 'TYGRYS';
END BEFORE STATEMENT;

BEFORE EACH ROW IS
BEGIN
    IF :NEW.funkcja = 'MILUSIA' THEN
        IF :NEW.przydzial_myszy <= :OLD.przydzial_myszy THEN
            DBMS_OUTPUT.PUT_LINE('brak zmiany');
            :NEW.przydzial_myszy := :OLD.przydzial_myszy;
        ELSIF :NEW.przydzial_myszy - :OLD.przydzial_myszy < 0.1 * przydzial_tygrysa THEN
            DBMS_OUTPUT.PUT_LINE('podwyzka mniejsza niz 10% Tygrysa');
            :NEW.przydzial_myszy := :NEW.przydzial_myszy + ROUND(0.1 * przydzial_tygrysa);
            :NEW.myszy_extra := NVL(:NEW.myszy_extra, 0) + 5;
            kara := kara + ROUND(0.1 * przydzial_tygrysa);
        ELSE
            nagroda := nagroda + 5;
        END IF;
    END IF;
END BEFORE EACH ROW;

AFTER STATEMENT IS
BEGIN
    SELECT myszy_extra INTO ekstra
    FROM Kocury
    WHERE pseudo = 'TYGRYS';
    przydzial_tygrysa := przydzial_tygrysa - kara;
    ekstra := ekstra + nagroda;
    IF kara <> 0 OR nagroda <> 0 THEN
        DBMS_OUTPUT.PUT_LINE('Nowy przydzial Tygrysa: ' || przydzial_tygrysa);
        DBMS_OUTPUT.PUT_LINE('Nowe myszy ekstra Tygrysa: ' || ekstra);
        kara := 0;
        nagroda := 0;
        UPDATE Kocury
        SET przydzial_myszy = przydzial_tygrysa,
            myszy_extra = ekstra
        WHERE pseudo = 'TYGRYS';
    END IF;
END AFTER STATEMENT;
END;

UPDATE Kocury
SET przydzial_myszy = 25
WHERE PSEUDO = 'PUSZYSTA';

UPDATE Kocury
SET przydzial_myszy = przydzial_myszy + 1
WHERE funkcja = 'MILUSIA';

UPDATE Kocury
SET przydzial_myszy = przydzial_myszy + 20
WHERE funkcja = 'MILUSIA';

SELECT *
FROM Kocury
WHERE pseudo IN ('PUSZYSTA', 'TYGRYS');

ROLLBACK;
DROP TRIGGER wirus_compound;

--zad43 
DECLARE 
    CURSOR funkcje IS SELECT funkcja, SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) suma_dla_funkcji
                        FROM KOCURY
                        GROUP BY funkcja
                        ORDER BY funkcja;
    CURSOR iloscKotow IS SELECT COUNT(*) ilosc, SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) sumaMyszy
                        FROM Kocury, Bandy WHERE Kocury.nr_bandy = Bandy.nr_bandy
                        GROUP BY Bandy.nazwa, Kocury.plec
                        ORDER BY Bandy.nazwa, plec;
    CURSOR funkcjezBand IS SELECT SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) sumaMyszy,
                                Kocury.funkcja funkcja,
                                Bandy.nazwa naz,
                                Kocury.plec pl
                            FROM Kocury, Bandy WHERE Kocury.nr_bandy = Bandy.nr_bandy
                            GROUP BY Bandy.nazwa, Kocury.plec, Kocury.funkcja
                            ORDER BY Bandy.nazwa, Kocury.plec, Kocury.funkcja;
    CURSOR bandy_c IS SELECT DISTINCT nazwa, Bandy.nr_bandy FROM Bandy JOIN Kocury ON Bandy.nr_bandy = Kocury.nr_bandy ORDER BY nazwa;
    CURSOR plec_c IS SELECT plec FROM Kocury GROUP BY plec ORDER BY plec;
    ilosc NUMBER;
    suma NUMBER;
    il iloscKotow%ROWTYPE;
    poszegolne_funkcje funkcjezBand%ROWTYPE;
BEGIN
    DBMS_OUTPUT.put('NAZWA BANDY       PLEC    ILE ');
    FOR fun IN funkcje
        LOOP
            DBMS_OUTPUT.put(RPAD(fun.funkcja, 10));
        END LOOP;
    DBMS_OUTPUT.put_line('    SUMA');
    DBMS_OUTPUT.put('---------------- ------ ----');
    FOR fun IN funkcje
        LOOP
            DBMS_OUTPUT.put(' ---------');
        END LOOP;
    
    DBMS_OUTPUT.put_line(' --------');
    
    OPEN funkcjezBand;
    OPEN iloscKotow;
    FETCH funkcjezBand INTO poszegolne_funkcje;
    FOR banda IN bandy_c
        LOOP
            FOR ple IN plec_c
                LOOP 
                    DBMS_OUTPUT.put(CASE WHEN ple.plec = 'M' THEN RPAD(' ', 18) ELSE RPAD(banda.nazwa, 18) END);
                    DBMS_OUTPUT.put(CASE WHEN ple.plec = 'M' THEN 'Kocor' ELSE 'Kotka' END);
                    
                    FETCH iloscKotow INTO il;
                    DBMS_OUTPUT.put(LPAD(il.ilosc, 4));
                    FOR fun IN funkcje
                        LOOP
                            IF fun.funkcja = poszegolne_funkcje.funkcja AND banda.nazwa = poszegolne_funkcje.naz AND ple.plec = poszegolne_funkcje.pl
                            THEN 
                                DBMS_OUTPUT.put(LPAD(NVL(poszegolne_funkcje.sumaMyszy, 0), 10));
                                FETCH funkcjezBand INTO poszegolne_funkcje;
                            ELSE
                                DBMS_OUTPUT.put(LPAD(NVL(0, 0), 10));
                            END IF;
                        END LOOP;
                    DBMS_OUTPUT.put(LPAD(NVL(il.sumaMyszy, 0), 10));
                    DBMS_OUTPUT.new_line();
                END LOOP;
        END LOOP;
    CLOSE iloscKotow;
    CLOSE funkcjezBand;
    DBMS_OUTPUT.put('Z---------------- ------ ----');
    FOR fun IN funkcje
        LOOP
            DBMS_OUTPUT.put(' ---------');
        END LOOP;
    DBMS_OUTPUT.put_line(' --------');
    DBMS_OUTPUT.put('Zjada razem                ');
    FOR fun IN funkcje
        LOOP            
            DBMS_OUTPUT.put(LPAD(NVL(fun.suma_dla_funkcji, 0), 10));
        END LOOP;
    SELECT SUM(nvl(PRZYDZIAL_MYSZY, 0) + nvl(MYSZY_EXTRA, 0)) INTO suma FROM Kocury;
    DBMS_OUTPUT.put(LPAD(suma, 10));
    DBMS_OUTPUT.new_line();
END;

--zad 45 
--tabela dodatki extra
CREATE TABLE Dodatki_extra(
    pseudo VARCHAR2(15) CONSTRAINT dodatki_pseudo_fk REFERENCES Kocury(pseudo),
    dod_extra NUMBER(3) DEFAULT 0    
);

SELECT * FROM Dodatki_extra;

DROP TABLE Dodatki_extra;
--zadanie
CREATE OR REPLACE TRIGGER kara_dla_milus
    BEFORE UPDATE OF przydzial_myszy
    ON Kocury
    FOR EACH ROW
DECLARE
    CURSOR milusie IS SELECT pseudo FROM Kocury WHERE funkcja = 'MILUSIA';
    ile NUMBER;
    polecenie VARCHAR2(200);
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    IF LOGIN_USER <> 'TYGRYS' AND :NEW.przydzial_myszy > :OLD.PRZYDZIAL_MYSZY AND :NEW.FUNKCJA = 'MILUSIA' THEN
    FOR milusia IN milusie
        LOOP
            BEGIN
                SELECT COUNT(*) INTO ile FROM Dodatki_extra WHERE pseudo = milusia.pseudo;
                IF ile > 0 THEN
                    polecenie:='UPDATE Dodatki_extra SET dod_extra = dod_extra - 10 WHERE :mil_ps = pseudo';
                ELSE 
                    polecenie:='INSERT INTO Dodatki_extra (pseudo, dod_extra) VALUES (:mil_ps, -10)';
                END IF;
                EXECUTE IMMEDIATE polecenie USING milusia.pseudo;
            END;
        END LOOP;
        COMMIT;
    END IF;
END;

--zad 46
--tabela
CREATE TABLE Proby_wykroczenia 
(
    kto VARCHAR2(15) NOT NULL, 
    kiedy DATE NOT NULL,
    jakiemu_kotu VARCHAR2(15) NOT NULL,
    jaka_operacja VARCHAR2(15) NOT NULL
);

DROP TABLE Proby_wykroczenia;
--zadanie
CREATE OR REPLACE TRIGGER monitor_wykroczen
    BEFORE INSERT OR UPDATE OF przydzial_myszy
    ON Kocury
    FOR EACH ROW
DECLARE
    min_mysz Funkcje.min_myszy%TYPE;
    max_mysz Funkcje.max_myszy%TYPE;
    poza_zakresem EXCEPTION;
    data_dodania DATE DEFAULT SYSDATE;
    typ_operacji VARCHAR2(20);
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    SELECT min_myszy, max_myszy INTO min_mysz, max_mysz FROM Funkcje WHERE Funkcja = :NEW.Funkcja;
    IF max_mysz < :NEW.przydzial_myszy OR min_mysz > :NEW.przydzial_myszy THEN
        IF INSERTING THEN 
            typ_operacji := 'INSERT';
        ELSIF UPDATING THEN
            typ_operacji := 'UPDATE';
        END IF;
        INSERT INTO Proby_wykroczenia(kto, kiedy, jakiemu_kotu, jaka_operacja) VALUES (ORA_LOGIN_USER, data_dodania, :NEW.pseudo, typ_operacji);
        COMMIT;
        RAISE poza;
    END IF;
EXCEPTION
    WHEN poza THEN
        DBMS_OUTPUT.PUT_LINE('przydzial myszy poza zakresem');
        :NEW.przydzial_myszy := :OLD.przydzial_myszy;
END;

--testy
UPDATE Kocury
SET przydzial_myszy = 100
WHERE imie = 'JACEK';

INSERT INTO Kocury VALUES ('MLODY','M','TOMEK','LAPACZ','TYGRYS','2001-12-12',80,NULL,3);

SELECT * FROM Kocury;
SELECT * FROM Proby_wykroczenia;

ROLLBACK;
TRUNCATE TABLE Proby_wykroczenia;

DROP TABLE Proby_wykroczenia;

DROP TRIGGER monitor_wykroczen;