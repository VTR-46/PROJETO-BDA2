-- Totais estaduais do Censo 2022: seis idades (60 a 64 e 65+), sexo Total, raca Total.
-- Fonte: CSV/censo_alfabetizacao_tratado.csv. Cada MERGE pode ser repetido.

-- UF 11: 46091 nao alfabetizados entre 196046 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 11 id_uf, 196046 total_alfabetizacao, 46091 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 12: 29181 nao alfabetizados entre 78416 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 12 id_uf, 78416 total_alfabetizacao, 29181 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 13: 80032 nao alfabetizados entre 356982 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 13 id_uf, 356982 total_alfabetizacao, 80032 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 14: 11822 nao alfabetizados entre 50460 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 14 id_uf, 50460 total_alfabetizacao, 11822 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 15: 223574 nao alfabetizados entre 876332 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 15 id_uf, 876332 total_alfabetizacao, 223574 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 16: 14797 nao alfabetizados entre 61916 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 16 id_uf, 61916 total_alfabetizacao, 14797 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 17: 57295 nao alfabetizados entre 188921 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 17 id_uf, 188921 total_alfabetizacao, 57295 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 21: 341532 nao alfabetizados entre 821961 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 21 id_uf, 821961 total_alfabetizacao, 341532 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 22: 213127 nao alfabetizados entre 493899 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 22 id_uf, 493899 total_alfabetizacao, 213127 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 23: 468435 nao alfabetizados entre 1290533 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 23 id_uf, 1290533 total_alfabetizacao, 468435 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 24: 168127 nao alfabetizados entre 497891 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 24 id_uf, 497891 total_alfabetizacao, 168127 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 25: 229183 nao alfabetizados entre 615328 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 25 id_uf, 615328 total_alfabetizacao, 229183 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 26: 429704 nao alfabetizados entre 1332159 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 26 id_uf, 1332159 total_alfabetizacao, 429704 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 27: 172349 nao alfabetizados entre 409221 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 27 id_uf, 409221 total_alfabetizacao, 172349 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 28: 104195 nao alfabetizados entre 294609 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 28 id_uf, 294609 total_alfabetizacao, 104195 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 29: 710795 nao alfabetizados entre 2159279 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 29 id_uf, 2159279 total_alfabetizacao, 710795 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 31: 598107 nao alfabetizados entre 3659936 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 31 id_uf, 3659936 total_alfabetizacao, 598107 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 32: 104867 nao alfabetizados entre 631398 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 32 id_uf, 631398 total_alfabetizacao, 104867 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 33: 233071 nao alfabetizados entre 3025629 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 33 id_uf, 3025629 total_alfabetizacao, 233071 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 35: 630614 nao alfabetizados entre 7650568 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 35 id_uf, 7650568 total_alfabetizacao, 630614 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 41: 248328 nao alfabetizados entre 1893120 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 41 id_uf, 1893120 total_alfabetizacao, 248328 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 42: 89433 nao alfabetizados entre 1184393 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 42 id_uf, 1184393 total_alfabetizacao, 89433 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 43: 164490 nao alfabetizados entre 2193416 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 43 id_uf, 2193416 total_alfabetizacao, 164490 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 50: 63624 nao alfabetizados entre 391091 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 50 id_uf, 391091 total_alfabetizacao, 63624 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 51: 87634 nao alfabetizados entre 430479 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 51 id_uf, 430479 total_alfabetizacao, 87634 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 52: 172651 nao alfabetizados entre 964417 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 52 id_uf, 964417 total_alfabetizacao, 172651 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

-- UF 53: 30742 nao alfabetizados entre 365090 idosos.
MERGE INTO tab_indicador_uf t
USING (SELECT 53 id_uf, 365090 total_alfabetizacao, 30742 nao_alfabetizados FROM dual) s
ON (t.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET
    t.total_alfabetizacao = s.total_alfabetizacao,
    t.nao_alfabetizados = s.nao_alfabetizados
WHEN NOT MATCHED THEN INSERT (id_uf, total_alfabetizacao, nao_alfabetizados)
    VALUES (s.id_uf, s.total_alfabetizacao, s.nao_alfabetizados);

COMMIT;
