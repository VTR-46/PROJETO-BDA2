-- 5 regioes e 27 UFs. MERGE permite atualizar sem duplicar.
-- Arquivo UTF-8. Execute com F5 no SQL Developer como MAPA_IDOSOS.
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

MERGE INTO tab_regiao d USING (SELECT 1 id_regiao, 'Norte' nome FROM dual) s
ON (d.id_regiao = s.id_regiao)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome
WHEN NOT MATCHED THEN INSERT (id_regiao, nome) VALUES (s.id_regiao, s.nome);
MERGE INTO tab_regiao d USING (SELECT 2 id_regiao, 'Nordeste' nome FROM dual) s
ON (d.id_regiao = s.id_regiao)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome
WHEN NOT MATCHED THEN INSERT (id_regiao, nome) VALUES (s.id_regiao, s.nome);
MERGE INTO tab_regiao d USING (SELECT 3 id_regiao, 'Sudeste' nome FROM dual) s
ON (d.id_regiao = s.id_regiao)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome
WHEN NOT MATCHED THEN INSERT (id_regiao, nome) VALUES (s.id_regiao, s.nome);
MERGE INTO tab_regiao d USING (SELECT 4 id_regiao, 'Sul' nome FROM dual) s
ON (d.id_regiao = s.id_regiao)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome
WHEN NOT MATCHED THEN INSERT (id_regiao, nome) VALUES (s.id_regiao, s.nome);
MERGE INTO tab_regiao d USING (SELECT 5 id_regiao, 'Centro-Oeste' nome FROM dual) s
ON (d.id_regiao = s.id_regiao)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome
WHEN NOT MATCHED THEN INSERT (id_regiao, nome) VALUES (s.id_regiao, s.nome);

-- UF usa o codigo de dois digitos do IBGE; o primeiro digito indica a regiao.
MERGE INTO tab_uf d USING (SELECT 11 id_uf, 'Rondônia' nome, 1 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 12 id_uf, 'Acre' nome, 1 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 13 id_uf, 'Amazonas' nome, 1 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 14 id_uf, 'Roraima' nome, 1 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 15 id_uf, 'Pará' nome, 1 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 16 id_uf, 'Amapá' nome, 1 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 17 id_uf, 'Tocantins' nome, 1 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 21 id_uf, 'Maranhão' nome, 2 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 22 id_uf, 'Piauí' nome, 2 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 23 id_uf, 'Ceará' nome, 2 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 24 id_uf, 'Rio Grande do Norte' nome, 2 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 25 id_uf, 'Paraíba' nome, 2 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 26 id_uf, 'Pernambuco' nome, 2 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 27 id_uf, 'Alagoas' nome, 2 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 28 id_uf, 'Sergipe' nome, 2 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 29 id_uf, 'Bahia' nome, 2 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 31 id_uf, 'Minas Gerais' nome, 3 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 32 id_uf, 'Espírito Santo' nome, 3 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 33 id_uf, 'Rio de Janeiro' nome, 3 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 35 id_uf, 'São Paulo' nome, 3 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 41 id_uf, 'Paraná' nome, 4 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 42 id_uf, 'Santa Catarina' nome, 4 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 43 id_uf, 'Rio Grande do Sul' nome, 4 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 50 id_uf, 'Mato Grosso do Sul' nome, 5 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 51 id_uf, 'Mato Grosso' nome, 5 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 52 id_uf, 'Goiás' nome, 5 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);
MERGE INTO tab_uf d USING (SELECT 53 id_uf, 'Distrito Federal' nome, 5 id_regiao FROM dual) s
ON (d.id_uf = s.id_uf)
WHEN MATCHED THEN UPDATE SET d.nome = s.nome, d.id_regiao = s.id_regiao
WHEN NOT MATCHED THEN INSERT (id_uf, nome, id_regiao) VALUES (s.id_uf, s.nome, s.id_regiao);

COMMIT;
