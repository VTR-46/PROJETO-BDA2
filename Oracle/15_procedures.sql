-- Erros: -20003 ausente; -20004 duplicidade; -20005 versão;
-- -20006 dados obrigatórios; -20007 abrangência histórica.
-- Nenhuma procedure confirma a transação do chamador.

-- Insere ou atualiza metadados de programa pelo código, preservando sua abrangência histórica.
CREATE OR REPLACE PROCEDURE pr_salvar_programa(
    p_codigo VARCHAR2, p_nome VARCHAR2, p_orgao VARCHAR2, p_publico VARCHAR2,
    p_abrangencia VARCHAR2, p_id_uf NUMBER, p_fonte_url VARCHAR2,
    p_consultado_em DATE, p_id_programa OUT NUMBER
) AUTHID DEFINER IS
    v_abrangencia tab_programa.abrangencia%TYPE;
    v_uf NUMBER;
    v_ofertas NUMBER;
BEGIN
    SAVEPOINT sp_salvar_programa;
    IF TRIM(p_codigo) IS NULL OR TRIM(p_nome) IS NULL OR TRIM(p_orgao) IS NULL
       OR TRIM(p_publico) IS NULL OR p_consultado_em IS NULL
       OR p_consultado_em > SYSDATE
       OR p_fonte_url IS NULL OR NOT REGEXP_LIKE(p_fonte_url, '^https://[^[:space:]]+$')
       OR p_abrangencia IS NULL OR p_abrangencia NOT IN ('NACIONAL','ESTADUAL')
       OR (p_abrangencia = 'NACIONAL' AND p_id_uf IS NOT NULL)
       OR (p_abrangencia = 'ESTADUAL' AND p_id_uf IS NULL) THEN
        RAISE_APPLICATION_ERROR(-20006, 'Programa: metadados, fonte ou abrangência inválidos.');
    END IF;
    BEGIN
        SELECT id_programa,abrangencia,id_uf INTO p_id_programa,v_abrangencia,v_uf
        FROM tab_programa WHERE codigo = TRIM(p_codigo) FOR UPDATE;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        INSERT INTO tab_programa(codigo,nome,orgao,publico,abrangencia,id_uf,fonte_url,consultado_em)
        VALUES(TRIM(p_codigo),TRIM(p_nome),TRIM(p_orgao),TRIM(p_publico),p_abrangencia,p_id_uf,p_fonte_url,p_consultado_em)
        RETURNING id_programa INTO p_id_programa;
        RETURN;
    END;
    IF v_abrangencia <> p_abrangencia OR NVL(v_uf,-1) <> NVL(p_id_uf,-1) THEN
        SELECT COUNT(*) INTO v_ofertas FROM tab_municipio_programa WHERE id_programa = p_id_programa;
        IF v_ofertas > 0 THEN
            RAISE_APPLICATION_ERROR(-20007, 'Programa com ofertas: abrangência e UF não podem mudar.');
        END IF;
    END IF;
    UPDATE tab_programa SET nome=TRIM(p_nome),orgao=TRIM(p_orgao),publico=TRIM(p_publico),
        abrangencia=p_abrangencia,id_uf=p_id_uf,fonte_url=p_fonte_url,consultado_em=p_consultado_em
    WHERE id_programa=p_id_programa;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK TO sp_salvar_programa;
        RAISE_APPLICATION_ERROR(-20004, 'Programa cadastrado concorrentemente; consulte e tente novamente.');
    WHEN OTHERS THEN ROLLBACK TO sp_salvar_programa; RAISE;
END;
/

-- Inserção: versão esperada NULL. Retificação: versão lida + justificativa.
-- Registra uma oferta anual ou a retifica com controle otimista de versão e justificativa.
CREATE OR REPLACE PROCEDURE pr_registrar_oferta(
    p_id_municipio NUMBER, p_id_programa NUMBER, p_ano NUMBER, p_turmas NUMBER,
    p_total NUMBER, p_idosos NUMBER, p_fonte_url VARCHAR2, p_publicado_em DATE,
    p_consultado_em DATE, p_versao_esperada NUMBER, p_justificativa VARCHAR2,
    p_nova_versao OUT NUMBER
) AUTHID DEFINER IS
    v_id NUMBER;
    v_versao NUMBER;
BEGIN
    SAVEPOINT sp_registrar_oferta;
    IF TRIM(p_justificativa) IS NULL OR p_publicado_em IS NULL OR p_consultado_em IS NULL
       OR p_publicado_em > p_consultado_em OR p_consultado_em > SYSDATE
       OR p_fonte_url IS NULL OR NOT REGEXP_LIKE(p_fonte_url, '^https://[^[:space:]]+$') THEN
        RAISE_APPLICATION_ERROR(-20006, 'Oferta: informe justificativa, fonte HTTPS e datas válidas.');
    END IF;
    -- Mesma ordem de bloqueio do cadastro: programa antes da oferta.
    SELECT id_programa INTO v_id FROM tab_programa WHERE id_programa=p_id_programa FOR UPDATE;
    SELECT id_municipio INTO v_id FROM tab_municipio WHERE id_municipio=p_id_municipio;
    BEGIN
        SELECT versao INTO v_versao FROM tab_municipio_programa
        WHERE id_municipio=p_id_municipio AND id_programa=p_id_programa AND ano_referencia=p_ano FOR UPDATE;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        IF p_versao_esperada IS NOT NULL THEN RAISE_APPLICATION_ERROR(-20005, 'Oferta não existe para a versão informada.'); END IF;
        INSERT INTO tab_municipio_programa(id_municipio,id_programa,ano_referencia,qtd_turmas,
            participantes_total,participantes_60mais,fonte_url,publicado_em,consultado_em,justificativa)
        VALUES(p_id_municipio,p_id_programa,p_ano,p_turmas,p_total,p_idosos,p_fonte_url,p_publicado_em,p_consultado_em,p_justificativa)
        RETURNING versao INTO p_nova_versao;
        RETURN;
    END;
    IF p_versao_esperada IS NULL OR p_versao_esperada <> v_versao THEN
        RAISE_APPLICATION_ERROR(-20005, 'Oferta alterada: releia a versão antes de retificar.');
    END IF;
    UPDATE tab_municipio_programa SET qtd_turmas=p_turmas,participantes_total=p_total,
        participantes_60mais=p_idosos,fonte_url=p_fonte_url,publicado_em=p_publicado_em,
        consultado_em=p_consultado_em,justificativa=TRIM(p_justificativa)
    WHERE id_municipio=p_id_municipio AND id_programa=p_id_programa AND ano_referencia=p_ano
    RETURNING versao INTO p_nova_versao;
EXCEPTION
    WHEN NO_DATA_FOUND THEN ROLLBACK TO sp_registrar_oferta; RAISE_APPLICATION_ERROR(-20003, 'Programa ou município inexistente.');
    WHEN DUP_VAL_ON_INDEX THEN ROLLBACK TO sp_registrar_oferta; RAISE_APPLICATION_ERROR(-20004, 'Oferta duplicada.');
    WHEN OTHERS THEN ROLLBACK TO sp_registrar_oferta; RAISE;
END;
/

-- Substituição integral de um indicador existente; NULL continua sendo ausência.
-- Substitui indicadores municipais existentes após validação e conferência da versão lida.
CREATE OR REPLACE PROCEDURE pr_atualizar_indicadores(
    p_id_municipio NUMBER, p_total_a NUMBER, p_nao_a NUMBER, p_total_e NUMBER,
    p_baixa_e NUMBER, p_renda NUMBER, p_versao_esperada NUMBER, p_nova_versao OUT NUMBER
) AUTHID DEFINER IS
    v_versao NUMBER;
    v_valido NUMBER;
BEGIN
    SAVEPOINT sp_atualizar_indicadores;
    v_valido := fn_validar_indicadores(p_total_a,p_nao_a,p_total_e,p_baixa_e,p_renda);
    SELECT versao INTO v_versao FROM tab_indicador_municipio WHERE id_municipio=p_id_municipio FOR UPDATE;
    IF p_versao_esperada IS NULL OR p_versao_esperada <> v_versao THEN
        RAISE_APPLICATION_ERROR(-20005, 'Indicador alterado: releia a versão antes de atualizar.');
    END IF;
    UPDATE tab_indicador_municipio SET total_alfabetizacao=p_total_a,nao_alfabetizados=p_nao_a,
        total_escolaridade=p_total_e,baixa_escolaridade=p_baixa_e,renda_media=p_renda
    WHERE id_municipio=p_id_municipio RETURNING versao INTO p_nova_versao;
EXCEPTION
    WHEN NO_DATA_FOUND THEN ROLLBACK TO sp_atualizar_indicadores; RAISE_APPLICATION_ERROR(-20003, 'Indicador municipal inexistente.');
    WHEN OTHERS THEN ROLLBACK TO sp_atualizar_indicadores; RAISE;
END;
/
