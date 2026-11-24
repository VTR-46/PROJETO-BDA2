-- IMPORTANTE: execute depois de 13_estrutura_programas.sql e 14_funcoes.sql,
-- como MAPA_IDOSOS. Este arquivo depende de FN_PERCENTUAL e das tabelas novas.
-- A view PNAD também depende dos catálogos criados por 13a_catalogos_pnad.sql.
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
    fn_percentual(i.nao_alfabetizados,i.total_alfabetizacao) AS taxa_analfabetismo,
    i.total_escolaridade,
    i.baixa_escolaridade,
    fn_percentual(i.baixa_escolaridade,i.total_escolaridade) AS percentual_baixa_escolaridade,
    i.renda_media
FROM tab_municipio m
JOIN tab_uf u ON u.id_uf = m.id_uf
JOIN tab_regiao r ON r.id_regiao = u.id_regiao
LEFT JOIN tab_indicador_municipio i ON i.id_municipio = m.id_municipio;

CREATE OR REPLACE VIEW vw_taxa_uf AS
SELECT u.id_uf, u.nome AS uf,
       i.total_alfabetizacao, i.nao_alfabetizados,
       fn_percentual(i.nao_alfabetizados,i.total_alfabetizacao) AS taxa_analfabetismo
FROM tab_uf u
LEFT JOIN tab_indicador_uf i ON i.id_uf = u.id_uf;

CREATE OR REPLACE VIEW vw_pnad_escolaridade AS
SELECT
    p.nivel_instrucao,
    n.nome AS escolaridade,
    p.total_amostra,
    p.amostra_com_renda,
    p.renda_media,
    f.descricao AS fonte,
    f.ano_referencia AS ano_fonte,
    f.url AS fonte_url
FROM tab_pnad_resumo p
JOIN tab_nivel_instrucao n ON n.nivel_instrucao=p.nivel_instrucao
JOIN tab_fonte_dado f ON f.id_fonte=p.id_fonte;

-- Interfaces de leitura da API; nenhuma escrita é concedida ao usuário web.
CREATE OR REPLACE VIEW vw_catalogo_municipios AS
SELECT id_municipio,nome,id_uf FROM tab_municipio;

CREATE OR REPLACE VIEW vw_cobertura_uf AS
SELECT u.id_uf,u.nome,COUNT(m.id_municipio) AS municipios,
       COUNT(CASE WHEN i.total_alfabetizacao IS NOT NULL THEN 1 END) AS com_taxa,
       iu.total_alfabetizacao,iu.nao_alfabetizados
FROM tab_uf u JOIN tab_municipio m ON m.id_uf=u.id_uf
LEFT JOIN tab_indicador_municipio i ON i.id_municipio=m.id_municipio
LEFT JOIN tab_indicador_uf iu ON iu.id_uf=u.id_uf
GROUP BY u.id_uf,u.nome,iu.total_alfabetizacao,iu.nao_alfabetizados;

-- Oferta publicada não é adesão formal nem evidência de impacto causal.
CREATE OR REPLACE VIEW vw_programas_municipio AS
SELECT p.codigo,p.nome AS programa,p.orgao,o.id_municipio,m.municipio,m.uf,
       o.ano_referencia,o.qtd_turmas,o.participantes_total,o.participantes_60mais,
       o.fonte_url,o.publicado_em,o.consultado_em,o.justificativa,o.versao,
       2022 AS ano_alfabetizacao,m.taxa_analfabetismo,m.percentual_baixa_escolaridade,m.renda_media
FROM tab_municipio_programa o JOIN tab_programa p ON p.id_programa=o.id_programa
JOIN vw_mapa_idosos m ON m.id_municipio=o.id_municipio;
