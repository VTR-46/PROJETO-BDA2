-- Falha também em erros de compilação (CREATE OR REPLACE pode não lançar erro).
DECLARE
    n NUMBER;
BEGIN
    SELECT COUNT(*) INTO n FROM user_objects
    WHERE object_name IN ('FN_PERCENTUAL','FN_VALIDAR_INDICADORES','PR_SALVAR_PROGRAMA',
        'PR_REGISTRAR_OFERTA','PR_ATUALIZAR_INDICADORES','TRG_INDICADOR_AUDITORIA','TRG_OFERTA_VALIDACAO')
        AND status='VALID';
    IF n <> 7 THEN RAISE_APPLICATION_ERROR(-20010, 'Objetos PL/SQL ausentes/inválidos. Consulte USER_ERRORS.'); END IF;
    SELECT COUNT(*) INTO n FROM user_errors WHERE name IN (
        'FN_PERCENTUAL','FN_VALIDAR_INDICADORES','PR_SALVAR_PROGRAMA','PR_REGISTRAR_OFERTA',
        'PR_ATUALIZAR_INDICADORES','TRG_INDICADOR_AUDITORIA','TRG_OFERTA_VALIDACAO',
        'VW_MAPA_IDOSOS','VW_TAXA_UF','VW_PNAD_ESCOLARIDADE','VW_CATALOGO_MUNICIPIOS',
        'VW_COBERTURA_UF','VW_PROGRAMAS_MUNICIPIO');
    IF n > 0 THEN RAISE_APPLICATION_ERROR(-20010, 'Erros de compilação. Consulte USER_ERRORS.'); END IF;
END;
/
SELECT object_type,object_name,status FROM user_objects
WHERE object_type IN ('FUNCTION','PROCEDURE','TRIGGER') ORDER BY object_type,object_name;
SELECT codigo,municipio,ano_referencia,qtd_turmas,participantes_60mais
FROM vw_programas_municipio ORDER BY codigo,municipio,ano_referencia;
