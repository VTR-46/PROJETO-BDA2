-- Retorna NULL para ausências/denominador zero; entradas inválidas: -20001.
-- Calcula parte/total em percentual; devolve NULL para dado ausente ou total zero.
CREATE OR REPLACE FUNCTION fn_percentual(p_parte NUMBER, p_total NUMBER)
RETURN NUMBER DETERMINISTIC AUTHID DEFINER IS
BEGIN
    IF p_parte < 0 OR p_total < 0 OR p_parte > p_total THEN
        RAISE_APPLICATION_ERROR(-20001, 'Percentual: contagens negativas ou parte maior que total.');
    END IF;
    IF p_parte IS NULL OR p_total IS NULL OR p_total = 0 THEN RETURN NULL; END IF;
    RETURN ROUND(100 * p_parte / p_total, 2);
END;
/

-- Mesma validação na procedure e no DML direto pelo trigger. Retorna 1 ou -20002.
-- Valida contagens, pares de valores ausentes e renda antes de gravar indicadores.
CREATE OR REPLACE FUNCTION fn_validar_indicadores(
    p_total_a NUMBER, p_nao_a NUMBER, p_total_e NUMBER, p_baixa_e NUMBER, p_renda NUMBER
) RETURN NUMBER DETERMINISTIC AUTHID DEFINER IS
BEGIN
    IF (p_total_a IS NULL AND p_nao_a IS NOT NULL)
       OR (p_total_a IS NOT NULL AND p_nao_a IS NULL)
       OR p_total_a <= 0 OR p_nao_a < 0 OR p_nao_a > p_total_a
       OR p_total_e <= 0 OR p_baixa_e < 0 OR p_baixa_e > p_total_e
       OR (p_total_e IS NULL AND p_baixa_e IS NOT NULL)
       OR p_total_a <> TRUNC(p_total_a) OR p_nao_a <> TRUNC(p_nao_a)
       OR p_total_e <> TRUNC(p_total_e) OR p_baixa_e <> TRUNC(p_baixa_e)
       OR p_renda < 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Indicadores inconsistentes: verifique contagens, ausências e renda.');
    END IF;
    RETURN 1;
END;
/
