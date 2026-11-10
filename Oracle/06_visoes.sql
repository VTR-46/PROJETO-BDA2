-- Uma VIEW é uma consulta salva: ela calcula percentuais sem alterar dados.
-- NULL indica que a taxa não pode ser calculada com as células disponíveis.

CREATE OR REPLACE VIEW vw_mapa_idosos AS
SELECT
    m.id_municipio,
    m.nome AS municipio,
    u.id_uf,
    u.nome AS uf,
    r.nome AS regiao,
    i.total_alfabetizacao,
    i.nao_alfabetizados,
    CASE
        WHEN i.total_alfabetizacao > 0
        THEN ROUND(100 * i.nao_alfabetizados / i.total_alfabetizacao, 2)
    END AS taxa_analfabetismo,
    i.total_escolaridade,
    i.baixa_escolaridade,
    CASE
        WHEN i.total_escolaridade > 0
        THEN ROUND(100 * i.baixa_escolaridade / i.total_escolaridade, 2)
    END AS percentual_baixa_escolaridade,
    i.renda_media
FROM tab_municipio m
JOIN tab_uf u ON u.id_uf = m.id_uf
JOIN tab_regiao r ON r.id_regiao = u.id_regiao
LEFT JOIN tab_indicador_municipio i ON i.id_municipio = m.id_municipio;

CREATE OR REPLACE VIEW vw_taxa_uf AS
SELECT u.id_uf, u.nome AS uf,
       i.total_alfabetizacao, i.nao_alfabetizados,
       CASE WHEN i.total_alfabetizacao > 0
            THEN ROUND(100 * i.nao_alfabetizados / i.total_alfabetizacao, 2)
       END AS taxa_analfabetismo
FROM tab_uf u
LEFT JOIN tab_indicador_uf i ON i.id_uf = u.id_uf;

CREATE OR REPLACE VIEW vw_pnad_escolaridade AS
SELECT
    nivel_instrucao,
    CASE nivel_instrucao
        WHEN 1 THEN 'Sem instrução'
        WHEN 2 THEN 'Fundamental incompleto'
        WHEN 3 THEN 'Fundamental completo'
        WHEN 4 THEN 'Médio incompleto'
        WHEN 5 THEN 'Médio completo'
        WHEN 6 THEN 'Superior incompleto'
        WHEN 7 THEN 'Superior completo'
    END AS escolaridade,
    total_amostra,
    amostra_com_renda,
    renda_media
FROM tab_pnad_resumo;
