-- ENCONTRAR O CODIGO IBGE DE UM MUNICIPIO
-- Execute com F5 no SQL Developer, como MAPA_IDOSOS ou MAPA_IDOSOS_RO.
-- Troque Campinas pelo nome (ou parte do nome) que deseja procurar.
-- O estado ajuda a distinguir municipios com nomes iguais.

SELECT
    m.id_municipio AS codigo_ibge,
    m.nome AS municipio,
    u.nome AS estado
FROM mapa_idosos.tab_municipio m
JOIN mapa_idosos.tab_uf u ON u.id_uf = m.id_uf
WHERE UPPER(m.nome) LIKE UPPER('%Campinas%')
ORDER BY u.nome, m.nome;

-- Copie CODIGO_IBGE para o WHERE id_municipio = ... dos scripts 09, 10 e 11.
-- Se o nome tiver acento, digite-o como aparece no cadastro.
