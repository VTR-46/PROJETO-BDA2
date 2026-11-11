-- RENDA NOMINAL MEDIA MENSAL DE IDOSOS (em reais)
-- Execute com F5 no SQL Developer, conectado como MAPA_IDOSOS ou MAPA_IDOSOS_RO.
-- Troque 3550308 pelo codigo IBGE do municipio desejado.
-- Exemplo: 3550308 = Sao Paulo (SP).

SELECT
    municipio,
    uf,
    renda_media AS renda_nominal_media_reais
FROM mapa_idosos.vw_mapa_idosos
WHERE id_municipio = 3550308;

-- A renda ja foi calculada na carga: media das faixas 60 a 64 e 65+ anos,
-- ponderada pela quantidade de idosos em cada faixa.
-- NULL significa "Sem dados" na pagina.
