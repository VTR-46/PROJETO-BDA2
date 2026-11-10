-- PNAD nacional: 76.492 registros, 7 niveis de instrucao; media calculada somente sobre rendas informadas.
-- A amostra não tem pesos nos arquivos do projeto e não possui município.
-- Arquivo UTF-8. Execute com F5 no SQL Developer como MAPA_IDOSOS.
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

MERGE INTO tab_pnad_resumo d USING (SELECT 1 nivel_instrucao, 11924 total_amostra, 1304 amostra_com_renda, 1231.44 renda_media FROM dual) s
ON (d.nivel_instrucao = s.nivel_instrucao)
WHEN MATCHED THEN UPDATE SET d.total_amostra = s.total_amostra, d.amostra_com_renda = s.amostra_com_renda, d.renda_media = s.renda_media
WHEN NOT MATCHED THEN INSERT (nivel_instrucao, total_amostra, amostra_com_renda, renda_media) VALUES (s.nivel_instrucao, s.total_amostra, s.amostra_com_renda, s.renda_media);
MERGE INTO tab_pnad_resumo d USING (SELECT 2 nivel_instrucao, 34977 total_amostra, 7382 amostra_com_renda, 2031.91 renda_media FROM dual) s
ON (d.nivel_instrucao = s.nivel_instrucao)
WHEN MATCHED THEN UPDATE SET d.total_amostra = s.total_amostra, d.amostra_com_renda = s.amostra_com_renda, d.renda_media = s.renda_media
WHEN NOT MATCHED THEN INSERT (nivel_instrucao, total_amostra, amostra_com_renda, renda_media) VALUES (s.nivel_instrucao, s.total_amostra, s.amostra_com_renda, s.renda_media);
MERGE INTO tab_pnad_resumo d USING (SELECT 3 nivel_instrucao, 5657 total_amostra, 1596 amostra_com_renda, 2698.87 renda_media FROM dual) s
ON (d.nivel_instrucao = s.nivel_instrucao)
WHEN MATCHED THEN UPDATE SET d.total_amostra = s.total_amostra, d.amostra_com_renda = s.amostra_com_renda, d.renda_media = s.renda_media
WHEN NOT MATCHED THEN INSERT (nivel_instrucao, total_amostra, amostra_com_renda, renda_media) VALUES (s.nivel_instrucao, s.total_amostra, s.amostra_com_renda, s.renda_media);
MERGE INTO tab_pnad_resumo d USING (SELECT 4 nivel_instrucao, 1493 total_amostra, 453 amostra_com_renda, 2732.17 renda_media FROM dual) s
ON (d.nivel_instrucao = s.nivel_instrucao)
WHEN MATCHED THEN UPDATE SET d.total_amostra = s.total_amostra, d.amostra_com_renda = s.amostra_com_renda, d.renda_media = s.renda_media
WHEN NOT MATCHED THEN INSERT (nivel_instrucao, total_amostra, amostra_com_renda, renda_media) VALUES (s.nivel_instrucao, s.total_amostra, s.amostra_com_renda, s.renda_media);
MERGE INTO tab_pnad_resumo d USING (SELECT 5 nivel_instrucao, 12050 total_amostra, 3780 amostra_com_renda, 3497.69 renda_media FROM dual) s
ON (d.nivel_instrucao = s.nivel_instrucao)
WHEN MATCHED THEN UPDATE SET d.total_amostra = s.total_amostra, d.amostra_com_renda = s.amostra_com_renda, d.renda_media = s.renda_media
WHEN NOT MATCHED THEN INSERT (nivel_instrucao, total_amostra, amostra_com_renda, renda_media) VALUES (s.nivel_instrucao, s.total_amostra, s.amostra_com_renda, s.renda_media);
MERGE INTO tab_pnad_resumo d USING (SELECT 6 nivel_instrucao, 1062 total_amostra, 384 amostra_com_renda, 4826.74 renda_media FROM dual) s
ON (d.nivel_instrucao = s.nivel_instrucao)
WHEN MATCHED THEN UPDATE SET d.total_amostra = s.total_amostra, d.amostra_com_renda = s.amostra_com_renda, d.renda_media = s.renda_media
WHEN NOT MATCHED THEN INSERT (nivel_instrucao, total_amostra, amostra_com_renda, renda_media) VALUES (s.nivel_instrucao, s.total_amostra, s.amostra_com_renda, s.renda_media);
MERGE INTO tab_pnad_resumo d USING (SELECT 7 nivel_instrucao, 9329 total_amostra, 3347 amostra_com_renda, 8946.54 renda_media FROM dual) s
ON (d.nivel_instrucao = s.nivel_instrucao)
WHEN MATCHED THEN UPDATE SET d.total_amostra = s.total_amostra, d.amostra_com_renda = s.amostra_com_renda, d.renda_media = s.renda_media
WHEN NOT MATCHED THEN INSERT (nivel_instrucao, total_amostra, amostra_com_renda, renda_media) VALUES (s.nivel_instrucao, s.total_amostra, s.amostra_com_renda, s.renda_media);

COMMIT;
