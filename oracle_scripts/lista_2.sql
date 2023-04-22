--zad 17
SELECT pseudo "POLUJE W POLU", przydzial_myszy "PRZYDZIAL MYSZY", nazwa "BANDA"
FROM Kocury JOIN Bandy ON Kocury.nr_bandy = Bandy.nr_bandy
WHERE (teren = 'CALOSC'
      OR teren = 'POLE')
      AND przydzial_myszy > 50;
      
--zad 18
SELECT k1.imie, k1.w_stadku_od "POLUJE OD"
FROM Kocury k1 JOIN Kocury k2 ON k2.imie = 'JACEK'
WHERE k1.w_stadku_od < k2.w_stadku_od
ORDER BY k1.w_stadku_od DESC;

--zad 19 a
SELECT k1.imie "Imie", k1.funkcja "Funkcja", NVL(k2.imie,' ') "Szef 1", NVL(k3.imie,' ') "Szef 2", NVL(k4.imie,' ') "Szef 3"
  FROM Kocury k1 LEFT JOIN
    (Kocury k2 LEFT JOIN
      (Kocury k3 LEFT JOIN Kocury k4
          ON k3.szef = k4.pseudo)
        ON k2.szef = k3.pseudo)
      ON k1.szef = k2.pseudo
WHERE k1.funkcja = 'KOT' OR k1.funkcja = 'MILUSIA';

--zad 19 b
SELECT *
FROM
(
  SELECT CONNECT_BY_ROOT imie "Imie", imie, CONNECT_BY_ROOT funkcja "Funkcja", LEVEL "L"
  FROM Kocury
  CONNECT BY PRIOR szef = pseudo
  START WITH funkcja IN ('KOT', 'MILUSIA')
) PIVOT (
   MAX(imie) FOR L IN (2 "Szef 1", 3 "Szef 2", 4 "Szef 3")
);

--zad 19 c
SELECT imie,' | ', funkcja, RTRIM(REVERSE(RTRIM(SYS_CONNECT_BY_PATH(REVERSE(imie), ' | '), imie)), '| ') "IMIONA KOLEJNYCH SZEFÓW"
FROM Kocury
WHERE funkcja = 'KOT' OR funkcja = 'MILUSIA'
CONNECT BY PRIOR pseudo = szef
START WITH szef IS NULL;

--zad 20
SELECT k.imie "Imie kotki", b.nazwa "Nazwa bandy", w.imie_wroga, w.stopien_wrogosci "Ocena wroga", wk.data_incydentu "Data inc."
FROM
    Wrogowie w JOIN
      Wrogowie_kocurow wk JOIN
      (Kocury k JOIN BANDY b
        ON k.nr_bandy = b.nr_bandy)
      ON wk.pseudo = k.pseudo
    ON w.imie_wroga = wk.imie_wroga
WHERE k.plec = 'D' AND wk.data_incydentu > TO_DATE('2007-01-01');

--zad 21
SELECT b.nazwa "Nazwa bandy", COUNT(q.pseudo) "Koty z wrogami"
FROM Bandy b JOIN
  (SELECT DISTINCT k.pseudo, k.nr_bandy
    FROM (Kocury k JOIN Wrogowie_kocurow wk
         ON k.pseudo = wk.pseudo)
  )q ON q.nr_bandy= b.nr_bandy
GROUP BY b.nazwa;

--zad 22
SELECT k.funkcja, k.pseudo "Pseudonim kota", COUNT(k.pseudo) "Liczba wrogow"
FROM Kocury k JOIN Wrogowie_kocurow wk
    ON k.pseudo = wk.pseudo
GROUP BY k.funkcja, k.pseudo
HAVING COUNT(k.pseudo) > 1;

--zad 23
SELECT imie, 12 * (przydzial_myszy + NVL(myszy_extra, 0)) "DAWKA ROCZNA", 'ponizej 864' "DAWKA"
FROM Kocury
WHERE myszy_extra IS NOT NULL AND 12 * (przydzial_myszy + NVL(myszy_extra, 0)) < 864

UNION ALL

SELECT imie, 12 * (przydzial_myszy + NVL(myszy_extra, 0)), '864'
FROM Kocury
WHERE myszy_extra IS NOT NULL AND 12 * (przydzial_myszy + NVL(myszy_extra, 0)) = 864

UNION ALL

SELECT imie, 12 * (przydzial_myszy + NVL(myszy_extra, 0)), 'powyzej 864'
FROM Kocury
WHERE myszy_extra IS NOT NULL
      AND 12 * (przydzial_myszy + NVL(myszy_extra, 0)) > 864
ORDER BY 2 DESC;

--zad 24 1 sposob
SELECT b.nr_bandy, b.nazwa, b.teren
FROM Bandy b LEFT JOIN Kocury k
  ON b.nr_bandy = k.nr_bandy
WHERE k.imie IS NULL;

--2 sposob
SELECT nr_bandy, nazwa, teren
FROM Bandy

MINUS

SELECT DISTINCT k.nr_bandy, b.nazwa, b.teren
FROM Bandy b JOIN Kocury k
    ON b.nr_bandy = k.nr_bandy;
    
--zad 25
SELECT imie, funkcja, przydzial_myszy
FROM Kocury
WHERE przydzial_myszy >= ALL (SELECT 3 * przydzial_myszy
                                FROM Kocury k JOIN Bandy b
                                    ON k.nr_bandy= b.nr_bandy
                                WHERE k.funkcja = 'MILUSIA' AND b.teren IN ('SAD', 'CALOSC'));
                                       
--zad 26
SELECT k2.funkcja, k2.AVG
FROM
  (SELECT MIN(AVG) "MINAVG", MAX(AVG) "MAXAVG"
  FROM (
    SELECT funkcja, CEIL(AVG(przydzial_myszy + NVL(myszy_extra, 0))) "AVG"
    FROM Kocury
    WHERE funkcja != 'SZEFUNIO'
    GROUP BY funkcja
  )) k1

  JOIN

  (SELECT funkcja, CEIL(AVG(przydzial_myszy + NVL(myszy_extra, 0))) "AVG"
  FROM Kocury
  WHERE funkcja != 'SZEFUNIO'
  GROUP BY funkcja) k2

  ON k1.MINAVG = k2.AVG OR k1.MAXAVG = k2.AVG
ORDER BY k2.AVG;

--zad 27 a
SELECT pseudo, przydzial_myszy + NVL(myszy_extra, 0) "ZJADA"
FROM Kocury k
WHERE (SELECT COUNT (DISTINCT przydzial_myszy + NVL(myszy_extra, 0)) FROM Kocury --ile kotow ma wiekszy przydzial
      WHERE przydzial_myszy + NVL(myszy_extra, 0) > k.przydzial_myszy + NVL(k.myszy_extra, 0)) < 6
ORDER BY ZJADA DESC;

--zad 27 b
SELECT pseudo, przydzial_myszy + NVL(myszy_extra, 0) "ZJADA"
FROM Kocury
WHERE przydzial_myszy + NVL(myszy_extra, 0) IN (
  SELECT *
  FROM (
    SELECT DISTINCT przydzial_myszy + NVL(myszy_extra, 0)
    FROM Kocury
    ORDER BY 1 DESC
  ) WHERE ROWNUM <= 6)
ORDER BY ZJADA DESC;
  
--zad 27 c
SELECT k1.pseudo, MAX(k1.przydzial_myszy + NVL(k1.myszy_extra, 0)) "ZJADA"
FROM Kocury k1 LEFT JOIN Kocury k2 --bez left join tracimy kota o najwiekszym przydziale myszy
    ON k1.przydzial_myszy + NVL(k1.myszy_extra, 0) < k2.przydzial_myszy + NVL(k2.myszy_extra, 0)
GROUP BY k1.pseudo
HAVING COUNT (DISTINCT k2.przydzial_myszy + NVL(k2.myszy_extra,0)) < 12
ORDER BY ZJADA DESC;

--zad 27 d
SELECT  pseudo, ZJADA
FROM(
  SELECT  pseudo, NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0) "ZJADA",
    DENSE_RANK() OVER (
      ORDER BY przydzial_myszy + NVL(myszy_extra, 0) DESC
    ) RANK
  FROM Kocury)
WHERE RANK <= 6;

--zad 28
--od dolu
SELECT TO_CHAR(YEAR), SUM "LICZBA WSTAPIEN"
FROM(
  SELECT YEAR, SUM, ABS(SUM-AVG) "DIFF"
  FROM(
      SELECT EXTRACT(YEAR FROM w_stadku_od) "YEAR", COUNT(EXTRACT(YEAR FROM w_stadku_od)) "SUM"
      FROM Kocury
      GROUP BY EXTRACT(YEAR FROM w_stadku_od)) 
      JOIN (
          SELECT AVG(COUNT(EXTRACT(YEAR FROM w_stadku_od))) "AVG"
          FROM Kocury
          GROUP BY EXTRACT(YEAR FROM w_stadku_od))
      ON SUM < AVG)
  WHERE DIFF < ALL(
  SELECT MAX(ABS(SUM-AVG)) "DIFF"
  FROM(
      SELECT EXTRACT(YEAR FROM w_stadku_od) "YEAR", COUNT(EXTRACT(YEAR FROM w_stadku_od)) "SUM"
      FROM Kocury
      GROUP BY EXTRACT(YEAR FROM w_stadku_od)
    ) JOIN (
      SELECT AVG(COUNT(EXTRACT(YEAR FROM w_stadku_od))) "AVG"
      FROM Kocury
      GROUP BY EXTRACT(YEAR FROM w_stadku_od)
    ) ON SUM < AVG)

UNION ALL
--srednia ilosc wstapien
SELECT 'Srednia', ROUND(AVG(COUNT(EXTRACT(YEAR FROM w_stadku_od))), 7)
FROM Kocury
GROUP BY EXTRACT(YEAR FROM w_stadku_od)

UNION ALL
--do gory
SELECT TO_CHAR(YEAR), SUM
FROM(
  SELECT YEAR, SUM, ABS(SUM-AVG) "DIFF"
  FROM(
      SELECT EXTRACT(YEAR FROM w_stadku_od) "YEAR", COUNT(EXTRACT(YEAR FROM w_stadku_od)) "SUM"
      FROM Kocury
      GROUP BY EXTRACT(YEAR FROM w_stadku_od)) 
      JOIN (
          SELECT AVG(COUNT(EXTRACT(YEAR FROM w_stadku_od))) "AVG"
          FROM Kocury
          GROUP BY EXTRACT(YEAR FROM w_stadku_od)) 
      ON SUM > AVG)
  WHERE DIFF < ALL(
  SELECT MAX(ABS(SUM-AVG)) "DIFF"
  FROM(
      SELECT EXTRACT(YEAR FROM w_stadku_od) "YEAR", COUNT(EXTRACT(YEAR FROM w_stadku_od)) "SUM"
      FROM Kocury
      GROUP BY EXTRACT(YEAR FROM w_stadku_od)) 
      JOIN (
          SELECT AVG(COUNT(EXTRACT(YEAR FROM w_stadku_od))) "AVG"
          FROM Kocury
          GROUP BY EXTRACT(YEAR FROM w_stadku_od)) 
      ON SUM > AVG);

--zad 29 a
SELECT k1.imie, MIN(k1.przydzial_myszy + NVL(k1.myszy_extra, 0)) "ZJADA", k1.nr_bandy, AVG(k2.przydzial_myszy + NVL(k2.myszy_extra, 0)) "SREDNIA BANDY"
FROM Kocury k1 JOIN Kocury k2 ON k1.nr_bandy= k2.nr_bandy
WHERE k1.PLEC = 'M'
GROUP BY k1.imie, k1.nr_bandy
HAVING MIN(k1.przydzial_myszy + NVL(k1.myszy_extra, 0)) < AVG(k2.przydzial_myszy + NVL(k2.myszy_extra, 0));

--zad 29 b
SELECT imie, przydzial_myszy + NVL(myszy_extra, 0) "ZJADA", k1.nr_bandy, AVG "SREDNIA BANDY"
FROM Kocury k1 JOIN (SELECT nr_bandy, AVG(przydzial_myszy + NVL(myszy_extra, 0)) "AVG" FROM Kocury GROUP BY nr_bandy) k2
    ON k1.nr_bandy= k2.nr_bandy AND przydzial_myszy + NVL(myszy_extra, 0) < AVG
WHERE PLEC = 'M';

--zad 29 c
SELECT imie, przydzial_myszy + NVL(myszy_extra, 0) "ZJADA", nr_bandy,
  (SELECT AVG(przydzial_myszy + NVL(myszy_extra, 0)) "AVG" FROM Kocury k2 WHERE k1.nr_bandy = k2.nr_bandy) "SREDNIA BANDY"
FROM Kocury k1
WHERE PLEC = 'M' AND przydzial_myszy + NVL(myszy_extra, 0) < (SELECT AVG(przydzial_myszy + NVL(myszy_extra, 0)) "AVG" FROM Kocury k2 WHERE k1.nr_bandy= k2.nr_bandy);

--zad 30
SELECT imie, TO_CHAR(w_stadku_od, 'YYYY-MM-DD') || ' <--- NAJSTARSZY STAZEM W BANDZIE ' || nazwa "WSTAPIL DO STADKA"
FROM (
  SELECT imie, w_stadku_od, nazwa, MIN(w_stadku_od) OVER (PARTITION BY k.nr_bandy) NAJMLODSZY
  FROM Kocury k JOIN Bandy b ON k.nr_bandy= b.nr_bandy)
WHERE w_stadku_od = NAJMLODSZY

UNION ALL

SELECT imie, TO_CHAR(w_stadku_od, 'YYYY-MM-DD') || ' <--- NAJMLODSZY STAZEM W BANDZIE ' || nazwa "WSTAPIL DO STADKA"
FROM (
  SELECT imie, w_stadku_od, nazwa, MAX(w_stadku_od) OVER (PARTITION BY k.nr_bandy) NAJSTARSZY
  FROM Kocury k JOIN Bandy b ON k.nr_bandy = b.nr_bandy)
WHERE w_stadku_od = NAJSTARSZY

UNION ALL

SELECT imie, TO_CHAR(w_stadku_od, 'YYYY-MM-DD')
FROM (
  SELECT imie, w_stadku_od, nazwa,
    MIN(w_stadku_od) OVER (PARTITION BY k.nr_bandy) NAJMLODSZY,
    MAX(w_stadku_od) OVER (PARTITION BY k.nr_bandy) NAJSTARSZY
  FROM Kocury k JOIN Bandy b ON k.nr_bandy= b.nr_bandy)
WHERE W_STADKU_OD != NAJMLODSZY AND W_STADKU_OD != NAJSTARSZY
ORDER BY IMIE;

--zad 31
CREATE OR REPLACE VIEW Dane(nazwa_bandy, sre_spoz, max_spoz, min_spoz, koty, koty_z_dod)
AS
SELECT nazwa, AVG(przydzial_myszy), MAX(przydzial_myszy), MIN(przydzial_myszy), COUNT(pseudo), COUNT(myszy_extra)
FROM Kocury k JOIN Bandy b ON k.nr_bandy= b.nr_bandy
GROUP BY b.nazwa;

SELECT *
FROM Dane;

ACCEPT pseudonim CHAR PROMPT "Podaj pseudonim kota";

SELECT pseudo "PSEUDONIM", imie, funkcja, przydzial_myszy "ZJADA", 'OD ' || min_spoz || ' DO ' || max_spoz "GRANICE SPOZYCIA", TO_CHAR(w_stadku_od, 'YYYY-MM-DD') "LOWI OD"
FROM (Kocury k JOIN Bandy b ON k.nr_bandy = b.nr_bandy JOIN Dane d ON b.nazwa = d.nazwa_bandy)
WHERE pseudo = UPPER('&pseudonim');

--zad 32
CREATE OR REPLACE VIEW Najstarsi(pseudo, plec, przydzial_myszy, myszy_extra, nr_bandy)
AS
SELECT pseudo, plec, przydzial_myszy, myszy_extra, nr_bandy
FROM Kocury
WHERE pseudo IN(
  SELECT pseudo
  FROM Kocury JOIN Bandy ON Kocury.nr_bandy = Bandy.nr_bandy
  WHERE nazwa = 'CZARNI RYCERZE'
  ORDER BY w_stadku_od
  FETCH NEXT 3 ROWS ONLY)
OR pseudo IN(
  SELECT pseudo
  FROM Kocury JOIN Bandy ON Kocury.nr_bandy= Bandy.nr_bandy
  WHERE nazwa = 'LACIACI MYSLIWI'
  ORDER BY w_stadku_od
  FETCH NEXT 3 ROWS ONLY);

SELECT pseudo, plec, przydzial_myszy "Myszy przed podw.", NVL(myszy_extra, 0) "Ekstra przed podw."
FROM Najstarsi;

UPDATE Najstarsi
SET przydzial_myszy = przydzial_myszy + DECODE(plec, 'D', 0.1 * (SELECT MIN(przydzial_myszy) FROM Kocury), 10),
    myszy_extra = NVL(myszy_extra, 0) + 0.15 * (SELECT AVG(NVl(myszy_extra, 0)) FROM Kocury WHERE Najstarsi.nr_bandy = nr_bandy);

SELECT pseudo, plec, przydzial_myszy "Myszy po podw.", NVL(myszy_extra, 0) "Ekstra po podw."
FROM Najstarsi;

ROLLBACK;

--zad 33 a v2
SELECT DECODE(plec, 'Kotka', ' ', nazwa)nazwa, plec, ile, szefunio, bandzior, lowczy, lapacz, kot, milusia, dzielczy, suma
FROM (SELECT nazwa,
             DECODE(plec, 'D', 'Kotka', 'Kocur') plec,
             TO_CHAR(COUNT(pseudo)) ile,
             TO_CHAR(SUM(DECODE(funkcja,'SZEFUNIO', przydzial_myszy+NVL(myszy_extra,0),0))) szefunio,
             TO_CHAR(SUM(DECODE(funkcja, 'BANDZIOR', przydzial_myszy+NVL(myszy_extra,0),0))) bandzior,
             TO_CHAR(SUM(DECODE(funkcja, 'LOWCZY', przydzial_myszy+NVL(myszy_extra,0),0))) lowczy,
             TO_CHAR(SUM(DECODE(funkcja, 'LAPACZ', przydzial_myszy+NVL(myszy_extra,0),0))) lapacz,
             TO_CHAR(SUM(DECODE(funkcja, 'KOT', przydzial_myszy+NVL(myszy_extra,0),0))) kot,
             TO_CHAR(SUM(DECODE(funkcja, 'MILUSIA', przydzial_myszy+NVL(myszy_extra,0),0))) milusia,
             TO_CHAR(SUM(DECODE(funkcja, 'DZIELCZY', przydzial_myszy+NVL(myszy_extra,0),0))) dzielczy,
             TO_CHAR(SUM(przydzial_myszy+NVL(myszy_extra,0))) suma
FROM Kocury JOIN Bandy ON Kocury.nr_bandy= Bandy.nr_bandy
GROUP BY nazwa, plec
UNION
SELECT 'Z----------------', '--------', '----------', '-----------', '-----------', '----------', '----------', '----------', '----------', '----------', '----------'
FROM DUAL
UNION
SELECT 'ZJADA RAZEM' nazwa, ' ' plec, ' ' ile,
             TO_CHAR(SUM(DECODE(funkcja, 'SZEFUNIO', przydzial_myszy+NVL(myszy_extra,0),0))) szefunio,
             TO_CHAR(SUM(DECODE(funkcja, 'BANDZIOR', przydzial_myszy+NVL(myszy_extra,0),0))) bandzior,
             TO_CHAR(SUM(DECODE(funkcja, 'LOWCZY', przydzial_myszy+NVL(myszy_extra,0),0))) lowczy,
             TO_CHAR(SUM(DECODE(funkcja, 'LAPACZ', przydzial_myszy+NVL(myszy_extra,0),0))) lapacz,
             TO_CHAR(SUM(DECODE(funkcja, 'KOT', przydzial_myszy+NVL(myszy_extra,0),0))) kot,
             TO_CHAR(SUM(DECODE(funkcja, 'MILUSIA', przydzial_myszy+NVL(myszy_extra,0),0))) milusia,
             TO_CHAR(SUM(DECODE(funkcja, 'DZIELCZY', przydzial_myszy+NVL(myszy_extra,0),0))) dzielczy,
             TO_CHAR(SUM(przydzial_myszy+NVL(myszy_extra,0))) suma
FROM Kocury JOIN BANDY ON Kocury.nr_bandy= Bandy.nr_bandy
ORDER BY 1,2);
--zad 33 b
SELECT *
FROM
(
  SELECT TO_CHAR(DECODE(plec, 'D', nazwa, ' ')) "NAZWA BANDY",
    TO_CHAR(DECODE(plec, 'D', 'Kotka', 'Kocor')),
    TO_CHAR(ile) "ILE",
    TO_CHAR(NVL(szefunio, 0)) "SZEFUNIO",
    TO_CHAR(NVL(bandzior,0)) "BANDZIOR",
    TO_CHAR(NVL(lowczy,0)) "LOWCZY",
    TO_CHAR(NVL(lapacz,0)) "LAPACZ",
    TO_CHAR(NVL(kot,0)) "KOT",
    TO_CHAR(NVL(milusia,0)) "MILUSIA",
    TO_CHAR(NVL(dzielczy,0)) "DZIELCZY",
    TO_CHAR(NVL(suma,0)) "SUMA"
  FROM
  (
    SELECT nazwa, plec, funkcja, przydzial_myszy + NVL(myszy_extra, 0) liczba
    FROM Kocury JOIN Bandy ON Kocury.nr_bandy= Bandy.nr_bandy
  ) PIVOT (
      SUM(liczba) FOR funkcja IN (
      'SZEFUNIO' szefunio, 'BANDZIOR' bandzior, 'LOWCZY' lowczy, 'LAPACZ' lapacz,
      'KOT' kot, 'MILUSIA' milusia, 'DZIELCZY' dzielczy
    )
  ) JOIN (
    SELECT nazwa "N", plec "P", COUNT(pseudo) ile, SUM(przydzial_myszy + NVL(myszy_extra, 0)) suma
    FROM Kocury K JOIN Bandy B ON K.nr_bandy= B.nr_bandy
    GROUP BY nazwa, plec
    ORDER BY nazwa, plec
  ) ON N = nazwa AND P = plec
)


UNION ALL

SELECT 'Z--------------', '------', '--------', '---------', '---------', '--------', '--------', '--------', '--------', '--------', '--------' FROM DUAL

UNION ALL

SELECT  'ZJADA RAZEM',
        ' ',
        ' ',
        TO_CHAR(NVL(szefunio, 0)) szefunio,
        TO_CHAR(NVL(bandzior, 0)) bandzior,
        TO_CHAR(NVL(lowczy, 0)) lowczy,
        TO_CHAR(NVL(lapacz, 0)) lapacz,
        TO_CHAR(NVL(kot, 0)) kot,
        TO_CHAR(NVL(milusia, 0)) milusia,
        TO_CHAR(NVL(dzielczy, 0)) dzielczy,
        TO_CHAR(NVL(suma, 0)) suma
FROM
(
  SELECT      funkcja, przydzial_myszy + NVL(myszy_extra, 0) liczba
  FROM        Kocury JOIN Bandy ON Kocury.nr_bandy= Bandy.nr_bandy
) PIVOT (
    SUM(liczba) FOR funkcja IN (
    'SZEFUNIO' szefunio, 'BANDZIOR' bandzior, 'LOWCZY' lowczy, 'LAPACZ' lapacz,
    'KOT' kot, 'MILUSIA' milusia, 'DZIELCZY' dzielczy
  )
) CROSS JOIN (
  SELECT      SUM(przydzial_myszy + NVL(myszy_extra, 0)) suma
  FROM        Kocury
);