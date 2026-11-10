-- As consultas abaixo apenas leem os dados.
-- Resultados esperados: 5.571 municípios; 5.334 com taxa; 5.330 com taxa e renda.

SELECT
    COUNT(*) AS municipios,
    COUNT(taxa_analfabetismo) AS com_taxa,
    COUNT(CASE WHEN taxa_analfabetismo IS NOT NULL AND renda_media IS NOT NULL
          THEN 1 END) AS com_taxa_e_renda
FROM vw_mapa_idosos;

-- Verifique a cobertura por UF, inclusive os municípios sem dados.
SELECT
    uf,
    COUNT(*) AS municipios,
    COUNT(taxa_analfabetismo) AS com_taxa,
    COUNT(*) - COUNT(taxa_analfabetismo) AS sem_taxa
FROM vw_mapa_idosos
GROUP BY uf
ORDER BY uf;

-- Esta cidade da malha de 2025 não consta no Censo 2022.
SELECT id_municipio, municipio, taxa_analfabetismo, renda_media
FROM vw_mapa_idosos
WHERE id_municipio = 5101837;

-- Nenhuma taxa deve ficar fora do intervalo de 0% a 100%.
SELECT COUNT(*) AS taxas_invalidas
FROM vw_mapa_idosos
WHERE taxa_analfabetismo < 0 OR taxa_analfabetismo > 100;

-- Devem existir 27 taxas estaduais validas, inclusive em UFs com municipios sem taxa.
SELECT COUNT(*) AS ufs,
       COUNT(taxa_analfabetismo) AS ufs_com_taxa,
       COUNT(CASE WHEN total_alfabetizacao <= 0 OR taxa_analfabetismo < 0
                       OR taxa_analfabetismo > 100 THEN 1 END) AS taxas_invalidas
FROM vw_taxa_uf;

-- Compare o total oficial da UF com a soma dos municipios disponiveis.
-- A diferenca e esperada quando faltam municipios no CSV municipal.
SELECT u.uf, u.total_alfabetizacao AS total_oficial_uf,
       SUM(m.total_alfabetizacao) AS total_municipios_disponiveis,
       u.taxa_analfabetismo AS taxa_oficial_uf,
       ROUND(100 * SUM(m.nao_alfabetizados) / SUM(m.total_alfabetizacao), 2)
           AS taxa_municipios_disponiveis
FROM vw_taxa_uf u
JOIN vw_mapa_idosos m ON m.id_uf = u.id_uf
GROUP BY u.uf, u.total_alfabetizacao, u.taxa_analfabetismo
ORDER BY u.uf;

-- A PNAD deste projeto possui 76.492 registros, dos quais parte informa renda.
SELECT SUM(total_amostra) AS registros_pnad,
       SUM(amostra_com_renda) AS registros_com_renda
FROM tab_pnad_resumo;

-- Exemplo: municípios de São Paulo com taxa calculável.
SELECT municipio, taxa_analfabetismo, renda_media,
       percentual_baixa_escolaridade
FROM vw_mapa_idosos
WHERE id_uf = 35 AND taxa_analfabetismo IS NOT NULL
ORDER BY taxa_analfabetismo DESC, municipio
FETCH FIRST 20 ROWS ONLY;

-- Exemplo: renda média da amostra nacional por escolaridade.
SELECT escolaridade, total_amostra, amostra_com_renda, renda_media
FROM vw_pnad_escolaridade
ORDER BY nivel_instrucao;

-- Relação descritiva entre renda e analfabetismo nos municípios com ambos.
-- CORR varia de -1 a +1; associação não demonstra causa.
SELECT COUNT(*) AS municipios_com_ambos,
       ROUND(CORR(taxa_analfabetismo, renda_media), 3) AS correlacao
FROM vw_mapa_idosos
WHERE taxa_analfabetismo IS NOT NULL AND renda_media IS NOT NULL;

-- Comparação auxiliar: taxa baseada somente nos municipios disponiveis.
-- Para a cor da UF, use a taxa oficial de vw_taxa_uf acima.
SELECT uf,
       ROUND(100 * SUM(nao_alfabetizados) / SUM(total_alfabetizacao), 2)
           AS taxa_dos_municipios_disponiveis,
       COUNT(taxa_analfabetismo) AS municipios_incluidos
FROM vw_mapa_idosos
GROUP BY uf
ORDER BY uf;
