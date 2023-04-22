ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

CREATE TABLE FUNKCJE(
    funkcja VARCHAR2(10) CONSTRAINT fu_fu_pk PRIMARY KEY,
    min_myszy NUMBER(3) CONSTRAINT fu_min_ch CHECK(min_myszy>5),
    max_myszy NUMBER(3) CONSTRAINT fu_max_ch CHECK(200 > max_myszy),
    CHECK(max_myszy >= min_myszy)
);

CREATE TABLE WROGOWIE(
    imie_wroga VARCHAR2(15) CONSTRAINT wr_im_pk PRIMARY KEY,
    stopien_wrogosci NUMBER(2) CONSTRAINT wr_st_ch CHECK (stopien_wrogosci BETWEEN 1 and 10),
    gatunek VARCHAR(15),
    lapowka VARCHAR(20)
);

CREATE TABLE KOCURY(
    imie VARCHAR2(15) CONSTRAINT ko_im_nn NOT NULL,
    plec VARCHAR2(1) CONSTRAINT ko_pl_ch CHECK(plec IN ('M', 'D')),
    pseudo VARCHAR2(15) CONSTRAINT ko_ps_pk PRIMARY KEY,
    funkcja VARCHAR2(10) CONSTRAINT ko_fu_fk REFERENCES FUNKCJE(funkcja),
    szef VARCHAR2(15),
    w_stadku_od DATE DEFAULT SYSDATE,
    przydzial_myszy NUMBER(3),
    myszy_extra NUMBER(3),
    nr_bandy NUMBER(2)
);

CREATE TABLE BANDY(
    nr_bandy NUMBER(2) CONSTRAINT ba_nr_pk PRIMARY KEY,
    nazwa VARCHAR2(20) CONSTRAINT ba_na_nn NOT NULL,
    teren VARCHAR2(15) CONSTRAINT ba_te_un UNIQUE,
    szef_bandy VARCHAR2(15) CONSTRAINT ba_sz_un UNIQUE CONSTRAINT ba_sz_fk REFERENCES KOCURY(pseudo)
);

CREATE TABLE WROGOWIE_KOCUROW(
    pseudo VARCHAR2(15) CONSTRAINT wk_ps_fk REFERENCES KOCURY(pseudo),
    imie_wroga VARCHAR2(15) CONSTRAINT wk_im_fk REFERENCES WROGOWIE(imie_wroga),
    data_incydentu DATE NOT NULL,
    opis_incydentu VARCHAR2(50),
    PRIMARY KEY(pseudo, imie_wroga)
);

INSERT ALL
    INTO FUNKCJE (funkcja,min_myszy,max_myszy) VALUES ('SZEFUNIO',90,110)
    INTO FUNKCJE (funkcja,min_myszy,max_myszy) VALUES ('BANDZIOR',70,90)
    INTO FUNKCJE (funkcja,min_myszy,max_myszy) VALUES ('LOWCZY',60,70)
    INTO FUNKCJE (funkcja,min_myszy,max_myszy) VALUES ('LAPACZ',50,60)
    INTO FUNKCJE (funkcja,min_myszy,max_myszy) VALUES ('KOT',40,50)
    INTO FUNKCJE (funkcja,min_myszy,max_myszy) VALUES ('MILUSIA',20,30)
    INTO FUNKCJE (funkcja,min_myszy,max_myszy) VALUES ('DZIELCZY',45,55)
    INTO FUNKCJE (funkcja,min_myszy,max_myszy) VALUES ('HONOROWA',6,25)
    
    INTO WROGOWIE (imie_wroga,stopien_wrogosci,gatunek,lapowka) VALUES('KAZIO',10,'CZLOWIEK','FLASZKA')
    INTO WROGOWIE (imie_wroga,stopien_wrogosci,gatunek,lapowka) VALUES('GLUPIA ZOSKA',1,'CZLOWIEK','KORALIK')
    INTO WROGOWIE (imie_wroga,stopien_wrogosci,gatunek,lapowka) VALUES('SWAWOLNY DYZIO',7,'CZLOWIEK','GUMA DO ZUCIA')
    INTO WROGOWIE (imie_wroga,stopien_wrogosci,gatunek,lapowka) VALUES('BUREK',4,'PIES','KOSC')
    INTO WROGOWIE (imie_wroga,stopien_wrogosci,gatunek,lapowka) VALUES('DZIKI BILL',10,'PIES',NULL)
    INTO WROGOWIE (imie_wroga,stopien_wrogosci,gatunek,lapowka) VALUES('REKSIO',2,'PIES','KOSC')
    INTO WROGOWIE (imie_wroga,stopien_wrogosci,gatunek,lapowka) VALUES('BETHOVEN',1,'PIES','PEDIGRIPALL')
    INTO WROGOWIE (imie_wroga,stopien_wrogosci,gatunek,lapowka) VALUES('CHYTRUSEK',5,'LIS','KURCZAK')
    INTO WROGOWIE (imie_wroga,stopien_wrogosci,gatunek,lapowka) VALUES('SMUKLA',1,'SOSNA',NULL)
    INTO WROGOWIE (imie_wroga,stopien_wrogosci,gatunek,lapowka) VALUES('BAZYLI',3,'KOGUT','KURA DO STADA')
SELECT * FROM Dual;

INSERT ALL
    INTO KOCURY (imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES ('JACEK','M','PLACEK','LOWCZY','LYSY','2008-12-01',67,NULL,2)
    INTO KOCURY (imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES ('BARI','M','RURA','LAPACZ','LYSY','2009-09-01',56,NULL,2)
    INTO KOCURY (imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES ('MICKA','D','LOLA','MILUSIA','TYGRYS','2009-10-14',25,47,1)
    INTO KOCURY (imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES ('LUCEK','M','ZERO','KOT','KURKA','2010-03-01',43,NULL,3)
    INTO KOCURY (imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES ('SONIA','D','PUSZYSTA','MILUSIA','ZOMBI','2010-11-18',20,35,3)
    INTO KOCURY (imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES ('LATKA','D','UCHO','KOT','RAFA','2011-01-01',40,NULL,4)
    INTO KOCURY (imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES ('DUDEK','M','MALY','KOT','RAFA','2011-05-15',40,NULL,4)
    INTO KOCURY (imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES ('MRUCZEK','M','TYGRYS','SZEFUNIO',NULL,'2002-01-01',103,33,1)
    INTO KOCURY (imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES ('CHYTRY','M','BOLEK','DZIELCZY','TYGRYS','2002-05-05',50,NULL,1)
    INTO KOCURY (imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES ('KOREK','M','ZOMBI','BANDZIOR','TYGRYS','2004-03-16',75,13,3)
    INTO KOCURY (imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES ('BOLEK','M','LYSY','BANDZIOR','TYGRYS','2006-08-15',72,21,2)
    INTO KOCURY (imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES ('ZUZIA','D','SZYBKA','LOWCZY','LYSY','2006-07-21',65,NULL,2)
    INTO KOCURY (imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES ('RUDA','D','MALA','MILUSIA','TYGRYS','2006-09-17',22,42,1)
    INTO KOCURY (imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES ('PUCEK','M','RAFA','LOWCZY','TYGRYS','2006-10-15',65,NULL,4)
    INTO KOCURY (imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES ('PUNIA','D','KURKA','LOWCZY','ZOMBI','2008-01-01',61,NULL,3)
    INTO KOCURY (imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES ('BELA','D','LASKA','MILUSIA','LYSY','2008-02-01',24,28,2)
    INTO KOCURY (imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES ('KSAWERY','M','MAN','LAPACZ','RAFA','2008-07-12',51,NULL,4)
    INTO KOCURY (imie,plec,pseudo,funkcja,szef,w_stadku_od,przydzial_myszy,myszy_extra,nr_bandy) VALUES ('MELA','D','DAMA','LAPACZ','RAFA','2008-11-01',51,NULL,4)
SELECT * FROM Dual;

INSERT ALL
    INTO BANDY (nr_bandy,nazwa,teren,szef_bandy) VALUES (1,'SZEFOSTWO','CALOSC','TYGRYS')
    INTO BANDY (nr_bandy,nazwa,teren,szef_bandy) VALUES (2,'CZARNI RYCERZE','POLE','LYSY')
    INTO BANDY (nr_bandy,nazwa,teren,szef_bandy) VALUES (3,'BIALI LOWCY','SAD','ZOMBI')
    INTO BANDY (nr_bandy,nazwa,teren,szef_bandy) VALUES (4,'LACIACI MYSLIWI','GORKA','RAFA')
    INTO BANDY (nr_bandy,nazwa,teren,szef_bandy) VALUES (5,'ROCKERSI','ZAGRODA',NULL)
    
    INTO WROGOWIE_KOCUROW (pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES ('TYGRYS','KAZIO','2004-10-13','USILOWAL NABIC NA WIDLY')
    INTO WROGOWIE_KOCUROW (pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES ('ZOMBI','SWAWOLNY DYZIO','2005-03-07','WYBIL OKO Z PROCY')
    INTO WROGOWIE_KOCUROW (pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES ('BOLEK','KAZIO','2005-03-29','POSZCZUL BURKIEM')
    INTO WROGOWIE_KOCUROW (pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES ('SZYBKA','GLUPIA ZOSKA','2006-09-12','UZYLA KOTA JAKO SCIERKI')
    INTO WROGOWIE_KOCUROW (pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES ('MALA','CHYTRUSEK','2007-03-07','ZALECAL SIE')
    INTO WROGOWIE_KOCUROW (pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES ('TYGRYS','DZIKI BILL','2007-06-12','USILOWAL POZBAWIC ZYCIA')
    INTO WROGOWIE_KOCUROW (pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES ('BOLEK','DZIKI BILL','2007-11-10','ODGRYZL UCHO')
    INTO WROGOWIE_KOCUROW (pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES ('LASKA','DZIKI BILL','2008-12-12','POGRYZL ZE LEDWO SIE WYLIZALA')
    INTO WROGOWIE_KOCUROW (pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES ('LASKA','KAZIO','2009-01-07','ZLAPAL ZA OGON I ZROBIL WIATRAK')
    INTO WROGOWIE_KOCUROW (pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES ('DAMA','KAZIO','2009-02-07','CHCIAL OBEDRZEC ZE SKORY')
    INTO WROGOWIE_KOCUROW (pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES ('MAN','REKSIO','2009-04-14','WYJATKOWO NIEGRZECZNIE OBSZCZEKAL')
    INTO WROGOWIE_KOCUROW (pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES ('LYSY','BETHOVEN','2009-05-11','NIE PODZIELIL SIE SWOJA KASZA')
    INTO WROGOWIE_KOCUROW (pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES ('RURA','DZIKI BILL','2009-09-03','ODGRYZL OGON')
    INTO WROGOWIE_KOCUROW (pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES ('PLACEK','BAZYLI','2010-07-12','DZIOBIAC UNIEMOZLIWIL PODEBRANIE KURCZAKA')
    INTO WROGOWIE_KOCUROW (pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES ('PUSZYSTA','SMUKLA','2010-11-19','OBRZUCILA SZYSZKAMI')
    INTO WROGOWIE_KOCUROW (pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES ('KURKA','BUREK','2010-12-14','POGONIL')
    INTO WROGOWIE_KOCUROW (pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES ('MALY','CHYTRUSEK','2011-07-13','PODEBRAL PODEBRANE JAJKA')
    INTO WROGOWIE_KOCUROW (pseudo,imie_wroga,data_incydentu,opis_incydentu) VALUES ('UCHO','SWAWOLNY DYZIO','2011-07-14','OBRZUCIL KAMIENIAMI')
SELECT * FROM Dual;

ALTER TABLE KOCURY ADD CONSTRAINT ko_nr_fk FOREIGN KEY (nr_bandy) REFERENCES BANDY(nr_bandy);
ALTER TABLE KOCURY ADD CONSTRAINT ko_sz_fk FOREIGN KEY (pseudo) REFERENCES KOCURY(pseudo);






--lista2 zad 18
SELECT K2.imie, K2.w_stadku_od "POLUJE OD"
FROM KocuryT K1
         JOIN KocuryT K2
              ON K1.imie = 'JACEK'
WHERE K1.w_stadku_od > K2.w_stadku_od
ORDER BY K2.w_stadku_od DESC;

--lista2 zad 19a
SELECT K.imie "Imie",
       K.funkcja "Funkcja",
       K.szef.imie "Szef 1",
       K.szef.szef.imie "Szef 2",
       K.szef.szef.szef.imie "Szef 3"
FROM KocuryT K
WHERE K.funkcja IN ('KOT', 'MILUSIA');

--lista2 zad19b
SELECT *
FROM (SELECT CONNECT_BY_ROOT K.imie "Imie", DEREF(K.szef).imie szef, CONNECT_BY_ROOT K.funkcja "Funkcja", LEVEL AS "LEV"
      FROM KocuryT K
      CONNECT BY PRIOR DEREF(szef).pseudo = pseudo
      START WITH funkcja IN ('KOT','MILUSIA'))
PIVOT (
    MIN(szef)
    FOR LEV
    IN (2 "Szef 1", 3 "Szef 2", 4 "Szef 3")
    );

--lista2 zad 19c
SELECT imie, funkcja, MAX(szefowie) "Imiona kolejnych szefow"
FROM (SELECT CONNECT_BY_ROOT (imie)                          imie,
             CONNECT_BY_ROOT (funkcja)                       funkcja,
             REPLACE(SYS_CONNECT_BY_PATH(imie, ' | '), ' | ' || CONNECT_BY_ROOT IMIE || ' ' , '') szefowie
      FROM KocuryT
      CONNECT BY prior DEREF(szef).pseudo = pseudo
      START WITH funkcja in ('KOT', 'MILUSIA'))
GROUP BY imie, funkcja;

--lista2 zad 22 --natural join laczy tabele wspolna kolumna ale zostawia tylko jedną, drugą pomija
SELECT MIN(funkcja) "Funkcja", pseudo, COUNT(pseudo) "Liczba wrogow"
FROM KocuryT
         NATURAL JOIN INCYDENTYT
GROUP BY pseudo
HAVING COUNT(pseudo) > 1;

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

--lista 3 zad 34
DECLARE
    funkcja_kocura KocuryT.funkcja%TYPE;
BEGIN
    SELECT FUNKCJA INTO funkcja_kocura
    FROM KocuryT
    WHERE FUNKCJA = UPPER('MILUSIA');
--     DBMS_OUTPUT.PUT_LINE('Znaleziono kota o funkcji: ' || funkcja_kocura);
EXCEPTION
    WHEN TOO_MANY_ROWS
        THEN DBMS_OUTPUT.PUT_LINE('znaleziono '|| funkcja_kocura);
    WHEN NO_DATA_FOUND
        THEN DBMS_OUTPUT.PUT_LINE('NIE znaleziono' || funkcja_kocura);
END;

--lista 3 zad37
DECLARE
    CURSOR topC IS
        SELECT K.pseudo, K.caly_przydzial() "zjada"
        FROM KocuryT K
        ORDER BY "zjada" DESC;
    top topC%ROWTYPE;
BEGIN
    OPEN topC;
    DBMS_OUTPUT.PUT_LINE('Nr   Pseudonim   Zjada');
    DBMS_OUTPUT.PUT_LINE('----------------------');
    FOR i IN 1..5
    LOOP
        FETCH topC INTO top;
        EXIT WHEN topC%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(TO_CHAR(i) ||'    '|| RPAD(top.pseudo, 8) || '    ' || LPAD(TO_CHAR(top."zjada"), 5));
    END LOOP;
END;

--lista3 zad35
DECLARE
    imie_kocura KOCURYT.imie%TYPE;
    pzydzial_kocura NUMBER;
    miesiac_kocura NUMBER;
    znaleziony BOOLEAN DEFAULT FALSE;
BEGIN
    SELECT imie, (NVL(przydzial_myszy, 0) + NVL(myszy_extra,0))*12, EXTRACT(MONTH FROM w_stadku_od)
    INTO imie_kocura, pzydzial_kocura, miesiac_kocura
    FROM KOCURY
    WHERE PSEUDO = UPPER('Tygrys');
    IF pzydzial_kocura > 700
        THEN DBMS_OUTPUT.PUT_LINE('calkowity roczny przydzial myszy >700');
    ELSIF imie_kocura LIKE '%A%'
        THEN DBMS_OUTPUT.PUT_LINE('imiê zawiera litere A');
    ELSIF miesiac_kocura = 5
        THEN DBMS_OUTPUT.PUT_LINE('listopad jest miesiacem przystapienia do stada');
    ELSE DBMS_OUTPUT.PUT_LINE('nie odpowiada kryteriom');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND
        THEN DBMS_OUTPUT.PUT_LINE('BRAK TAKIEGO KOTA');
    WHEN OTHERS
        THEN DBMS_OUTPUT.PUT_LINE(sqlerrm);
END;

--inne
SELECT E.kot.pseudo, E.kot.caly_przydzial()
FROM KocuryT K JOIN ElitaT E  ON E.kot = REF(K);

SELECT REF(T). FROM PlebsT T WHERE T.kot.plec = 'M';

SELECT K.pseudo, data_wprowadzenia, data_usuniecia
FROM KocuryT K JOIN ElitaT E ON REF(K) = E.kot LEFT JOIN KontoT ON REF(E) = KontoT.kot;

-- JOIN na REF (dane kont i elity (bez pelnych danych slugusow))
SELECT * FROM konto_o w JOIN (kocury_o k JOIN elita_o e ON e.kot = REF(k)) ON w.kot = REF(e);