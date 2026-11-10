CREATE TABLE TAB_PNAD_IDOSOS ( 
IDADE NUMBER(38),
NIVEL_INSTRUCAO NUMBER(38),
RENDA_MENSAL NUMBER(26));

SELECT * FROM TAB_PNAD_IDOSOS;  --teste

SELECT 
    CASE nivel_instrucao
        WHEN 1 THEN 'Sem instrução'
        WHEN 2 THEN 'Fundamental incompleto'
        WHEN 3 THEN 'Fundamental completo'
        WHEN 4 THEN 'Médio incompleto'
        WHEN 5 THEN 'Médio completo'
        WHEN 6 THEN 'Superior incompleto'
        WHEN 7 THEN 'Superior completo'
        ELSE 'Não identificado'
    END AS descricao_escolaridade,
    ROUND(AVG(renda_mensal), 2) AS media_renda_reais,
    COUNT(*) AS volume_amostra
FROM 
    tab_pnad_idosos
WHERE 
    renda_mensal IS NOT NULL
GROUP BY 
    nivel_instrucao
ORDER BY 
    nivel_instrucao;