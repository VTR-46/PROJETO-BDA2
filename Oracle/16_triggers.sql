-- Auditoria transacional: falhar/reverter a alteração também reverte o log.

-- Valida indicadores em DML direto, incrementa versão e grava auditoria JSON.
CREATE OR REPLACE TRIGGER trg_indicador_auditoria
BEFORE INSERT OR UPDATE OR DELETE ON tab_indicador_municipio FOR EACH ROW
DECLARE
    v_valido NUMBER;
    v_anterior CLOB;
    v_novo CLOB;
    v_operacao VARCHAR2(6);
BEGIN
    IF INSERTING OR UPDATING THEN
        v_valido := fn_validar_indicadores(:NEW.total_alfabetizacao,:NEW.nao_alfabetizados,
            :NEW.total_escolaridade,:NEW.baixa_escolaridade,:NEW.renda_media);
    END IF;
    IF UPDATING THEN
        IF :NEW.id_municipio <> :OLD.id_municipio THEN
            RAISE_APPLICATION_ERROR(-20008, 'A identidade do indicador não pode mudar.');
        END IF;
        IF NVL(:NEW.total_alfabetizacao,-1)=NVL(:OLD.total_alfabetizacao,-1)
           AND NVL(:NEW.nao_alfabetizados,-1)=NVL(:OLD.nao_alfabetizados,-1)
           AND NVL(:NEW.total_escolaridade,-1)=NVL(:OLD.total_escolaridade,-1)
           AND NVL(:NEW.baixa_escolaridade,-1)=NVL(:OLD.baixa_escolaridade,-1)
           AND NVL(:NEW.renda_media,-1)=NVL(:OLD.renda_media,-1) THEN
            :NEW.versao := :OLD.versao;
            RETURN;
        END IF;
        :NEW.versao := :OLD.versao + 1;
    ELSIF INSERTING THEN :NEW.versao := 1;
    END IF;
    IF UPDATING OR DELETING THEN
        SELECT JSON_OBJECT('total_alfabetizacao' VALUE :OLD.total_alfabetizacao,
            'nao_alfabetizados' VALUE :OLD.nao_alfabetizados,
            'total_escolaridade' VALUE :OLD.total_escolaridade,
            'baixa_escolaridade' VALUE :OLD.baixa_escolaridade,
            'renda_media' VALUE :OLD.renda_media,'versao' VALUE :OLD.versao
            NULL ON NULL RETURNING CLOB) INTO v_anterior FROM dual;
    END IF;
    IF INSERTING OR UPDATING THEN
        SELECT JSON_OBJECT('total_alfabetizacao' VALUE :NEW.total_alfabetizacao,
            'nao_alfabetizados' VALUE :NEW.nao_alfabetizados,
            'total_escolaridade' VALUE :NEW.total_escolaridade,
            'baixa_escolaridade' VALUE :NEW.baixa_escolaridade,
            'renda_media' VALUE :NEW.renda_media,'versao' VALUE :NEW.versao
            NULL ON NULL RETURNING CLOB) INTO v_novo FROM dual;
    END IF;
    IF INSERTING THEN v_operacao := 'INSERT';
    ELSIF UPDATING THEN v_operacao := 'UPDATE';
    ELSE v_operacao := 'DELETE'; END IF;
    INSERT INTO tab_auditoria_indicador(id_municipio,operacao,usuario,anterior,novo)
    VALUES(COALESCE(:NEW.id_municipio,:OLD.id_municipio),v_operacao,
        SYS_CONTEXT('USERENV','SESSION_USER'),v_anterior,v_novo);
END;
/

-- Regra entre tabelas: uma oferta estadual deve estar na UF do programa.
-- Garante UF compatível, identidade anual imutável e versão coerente da oferta.
CREATE OR REPLACE TRIGGER trg_oferta_validacao
BEFORE INSERT OR UPDATE ON tab_municipio_programa FOR EACH ROW
DECLARE
    v_uf_programa NUMBER;
    v_uf_municipio NUMBER;
BEGIN
    IF UPDATING AND (:NEW.id_municipio <> :OLD.id_municipio
        OR :NEW.id_programa <> :OLD.id_programa OR :NEW.ano_referencia <> :OLD.ano_referencia) THEN
        RAISE_APPLICATION_ERROR(-20008, 'Município, programa e ano da oferta são imutáveis.');
    END IF;
    SELECT id_uf INTO v_uf_programa FROM tab_programa WHERE id_programa=:NEW.id_programa FOR UPDATE;
    SELECT id_uf INTO v_uf_municipio FROM tab_municipio WHERE id_municipio=:NEW.id_municipio;
    IF v_uf_programa IS NOT NULL AND v_uf_programa <> v_uf_municipio THEN
        RAISE_APPLICATION_ERROR(-20009, 'Município fora da UF de abrangência do programa.');
    END IF;
    IF TRIM(:NEW.justificativa) IS NULL OR :NEW.consultado_em > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20006, 'Informe justificativa e data de consulta válida.');
    END IF;
    IF INSERTING THEN :NEW.versao := 1;
    ELSIF NVL(:NEW.qtd_turmas,-1)=NVL(:OLD.qtd_turmas,-1)
        AND NVL(:NEW.participantes_total,-1)=NVL(:OLD.participantes_total,-1)
        AND NVL(:NEW.participantes_60mais,-1)=NVL(:OLD.participantes_60mais,-1)
        AND :NEW.fonte_url=:OLD.fonte_url AND :NEW.publicado_em=:OLD.publicado_em
        AND :NEW.consultado_em=:OLD.consultado_em AND :NEW.justificativa=:OLD.justificativa THEN
        :NEW.versao := :OLD.versao;
    ELSE :NEW.versao := :OLD.versao + 1;
    END IF;
EXCEPTION WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20003, 'Programa ou município inexistente.');
END;
/
