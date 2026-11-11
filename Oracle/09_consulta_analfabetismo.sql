-- TAXA DE ANALFABETISMO DE IDOSOS (60 anos ou mais)
-- Execute com F5 no SQL Developer, conectado como MAPA_IDOSOS ou MAPA_IDOSOS_RO.
-- Troque 3550308 pelo codigo IBGE do municipio desejado.
-- Exemplo: 3550308 = Sao Paulo (SP).

SELECT
    municipio,
    uf,
    nao_alfabetizados,
    total_alfabetizacao,
    taxa_analfabetismo AS taxa_analfabetismo_percentual
FROM mapa_idosos.vw_mapa_idosos
WHERE id_municipio = 3550308;

-- Calculo da taxa: 100 x nao_alfabetizados / total_alfabetizacao.
-- Se faltar alguma contagem, a taxa sera NULL ("Sem dados" na pagina).
