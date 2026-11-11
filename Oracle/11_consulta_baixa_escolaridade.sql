-- IDOSOS SEM INSTRUCAO OU COM FUNDAMENTAL INCOMPLETO (60 anos ou mais)
-- Execute com F5 no SQL Developer, conectado como MAPA_IDOSOS ou MAPA_IDOSOS_RO.
-- Troque 3550308 pelo codigo IBGE do municipio desejado.
-- Exemplo: 3550308 = Sao Paulo (SP).

SELECT
    municipio,
    uf,
    baixa_escolaridade AS idosos_com_baixa_escolaridade,
    total_escolaridade AS total_de_idosos,
    percentual_baixa_escolaridade AS baixa_escolaridade_percentual
FROM mapa_idosos.vw_mapa_idosos
WHERE id_municipio = 3550308;

-- Calculo da taxa: 100 x baixa_escolaridade / total_escolaridade.
-- NULL significa "Sem dados" na pagina.
