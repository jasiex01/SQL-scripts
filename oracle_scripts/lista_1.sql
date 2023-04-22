--zad 1
SELECT imie_wroga Wrog,opis_incydentu Przewina
FROM WROGOWIE_KOCUROW
WHERE EXTRACT(year FROM data_incydentu)='2009';

--zad 2
SELECT imie,funkcja,w_stadku_od "Z NAMI OD"
FROM KOCURY
WHERE (w_stadku_od BETWEEN '2005-09-01' AND '2007-07-31') AND plec='D';

--zad 3
SELECT imie_wroga WROG, gatunek, stopien_wrogosci "STOPIEN WROGOSCI"
FROM WROGOWIE
WHERE lapowka IS NULL
ORDER BY stopien_wrogosci;

--zad 4
SELECT imie||' zwany '||pseudo||' (fun. '||funkcja||') lowi myszki w bandzie '||nr_bandy||' od '||w_stadku_od "WSZYSTKO O KOCURACH"
FROM KOCURY
WHERE plec='M'
ORDER BY w_stadku_od DESC, pseudo;

--zad 5
SELECT pseudo, REGEXP_REPLACE(REGEXP_REPLACE(pseudo,'A','#',1,1),'L','%',1,1) "Po wymianie A na # oraz L na %"
FROM KOCURY
WHERE pseudo LIKE '%L%' AND pseudo LIKE '%A%';

--zad 6
SELECT imie,w_stadku_od "W stadku",TRUNC(przydzial_myszy/1.1) "Zjadal",ADD_MONTHS(w_stadku_od,5) "Podwyzka",przydzial_myszy "Zjada"
FROM KOCURY
WHERE (CURRENT_DATE-w_stadku_od) / 365.242199 > 13 AND EXTRACT(month FROM w_stadku_od) BETWEEN 3 AND 9;

--zad 7
SELECT imie, przydzial_myszy*3 "MYSZY KWARTALNIE", NVL(myszy_extra,0)*3 "KWARTALNE DODATKI"
FROM KOCURY
WHERE przydzial_myszy >= 55 AND przydzial_myszy > 2 * NVL(myszy_extra,0);

--zad 8
SELECT imie, CASE
    WHEN (przydzial_myszy*12 + NVL(myszy_extra,0)*12) < 660 THEN 'Ponizej 660'
    WHEN (przydzial_myszy*12 + NVL(myszy_extra,0)*12) = 660 THEN 'Limit'
    ELSE TO_CHAR(przydzial_myszy*12 + NVL(myszy_extra,0)*12) 
    END "Zjada rocznie"
FROM KOCURY;

--zad 9 25.10
SELECT pseudo, w_stadku_od "W STADKU", CASE
                    WHEN EXTRACT(DAY FROM w_stadku_od) <= 15 AND NEXT_DAY( LAST_DAY('2022-10-25') - INTERVAL '7' DAY, 'WEDNESDAY') > '2022-10-25'
                    THEN NEXT_DAY( LAST_DAY('2022-10-25') - INTERVAL '7' DAY, 'WEDNESDAY')
                    ELSE  NEXT_DAY(LAST_DAY(ADD_MONTHS('2022-10-25',1)) - INTERVAL '7' DAY, 'WEDNESDAY')
                    END "WYPLATA"
FROM KOCURY;

--zad 9 27.10
SELECT pseudo, w_stadku_od "W STADKU", CASE
                    WHEN EXTRACT(DAY FROM w_stadku_od) <= 15 AND NEXT_DAY( LAST_DAY('2022-10-27') - INTERVAL '7' DAY, 'WEDNESDAY') > '2022-10-27'
                    THEN NEXT_DAY( LAST_DAY('2022-10-27') - INTERVAL '7' DAY, 'WEDNESDAY')
                    ELSE  NEXT_DAY(LAST_DAY(ADD_MONTHS('2022-10-27',1)) - INTERVAL '7' DAY, 'WEDNESDAY')
                    END "WYPLATA"
FROM KOCURY;

--zad 10 pseudo
SELECT pseudo||' - '||CASE
        WHEN COUNT(*) = 1 THEN 'Unikalny'
        ELSE  'nieunikalny'
        END "Unikalnosc atr. PSEUDO"
FROM KOCURY
GROUP BY pseudo;

--zad 10 szef
SELECT szef||' - '||CASE
        WHEN COUNT(*) = 1 THEN 'Unikalny'
        ELSE  'nieunikalny'
        END "Unikalnosc atr. SZEF"
FROM KOCURY
WHERE szef IS NOT NULL
GROUP BY szef;

--zad 11
SELECT pseudo, COUNT(*) "Liczba wrogow"
FROM WROGOWIE_KOCUROW
GROUP BY pseudo
HAVING COUNT(*)>=2;

--zad 12
SELECT 'Liczba kotow=',COUNT(*),'lowi jako',funkcja,'i zjada max',MAX(przydzial_myszy+NVL(myszy_extra,0)),'myszy miesiecznie'
FROM KOCURY
WHERE plec = 'D' AND funkcja != 'SZEFUNIO'
GROUP BY funkcja
HAVING AVG(przydzial_myszy+NVL(myszy_extra,0)) > 50;

--zad 13
SELECT nr_bandy "Nr bandy", plec, MIN(przydzial_myszy) "Minimalny przydzial"
FROM KOCURY
GROUP BY nr_bandy, plec;

--zad 14
SELECT level "Poziom", pseudo "Pseudonim", funkcja "Funkcja", nr_bandy "Nr bandy"
FROM KOCURY
WHERE plec = 'M'
CONNECT BY PRIOR pseudo=szef
START WITH funkcja='BANDZIOR';

--zad 15
SELECT RPAD('===>',(level-1)*4,'===>')||(level-1)||'            '||imie "Hierarchia",
       DECODE(szef,NULL,'Sam sobie panem', szef) "Pseudo szefa",funkcja "Funkcja"
FROM KOCURY
WHERE myszy_extra IS NOT NULL
CONNECT BY PRIOR pseudo=szef
START WITH szef IS NULL;

--zad 16
SELECT LPAD(pseudo,LENGTH(pseudo)+(level-1)*4) "Droga sluzbowa"
FROM KOCURY
CONNECT BY PRIOR szef=pseudo
START WITH plec='M' AND myszy_extra IS NULL AND (CURRENT_DATE-w_stadku_od) / 365.242199 > 13;