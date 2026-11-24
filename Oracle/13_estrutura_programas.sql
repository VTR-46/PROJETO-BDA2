-- Incremental e repetível. Execute como dono, antes dos objetos PL/SQL.
DECLARE
    n NUMBER;
BEGIN
    SELECT COUNT(*) INTO n FROM user_tab_columns
    WHERE table_name = 'TAB_INDICADOR_MUNICIPIO' AND column_name = 'VERSAO';
    IF n = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE tab_indicador_municipio ADD
            (versao NUMBER DEFAULT 1 NOT NULL CHECK (versao >= 1 AND versao = TRUNC(versao)))';
    END IF;
    SELECT COUNT(*) INTO n FROM user_tables WHERE table_name = 'TAB_PROGRAMA';
    IF n = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE tab_programa (
            id_programa NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            codigo VARCHAR2(40) NOT NULL UNIQUE,
            nome VARCHAR2(200) NOT NULL,
            orgao VARCHAR2(200) NOT NULL,
            publico VARCHAR2(500) NOT NULL,
            abrangencia VARCHAR2(10) NOT NULL,
            id_uf NUMBER REFERENCES tab_uf(id_uf),
            fonte_url VARCHAR2(2000) NOT NULL,
            consultado_em DATE NOT NULL,
            CONSTRAINT ck_programa_abrangencia CHECK (
                (abrangencia = ''NACIONAL'' AND id_uf IS NULL) OR
                (abrangencia = ''ESTADUAL'' AND id_uf IS NOT NULL)),
            CONSTRAINT ck_programa_url CHECK (REGEXP_LIKE(fonte_url, ''^https://[^[:space:]]+$''))
        )';
        EXECUTE IMMEDIATE 'CREATE INDEX idx_programa_uf ON tab_programa(id_uf)';
    END IF;
    SELECT COUNT(*) INTO n FROM user_tables WHERE table_name = 'TAB_MUNICIPIO_PROGRAMA';
    IF n = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE tab_municipio_programa (
            id_municipio NUMBER NOT NULL REFERENCES tab_municipio(id_municipio),
            id_programa NUMBER NOT NULL REFERENCES tab_programa(id_programa),
            ano_referencia NUMBER NOT NULL CHECK (ano_referencia BETWEEN 1900 AND 9999
                AND ano_referencia = TRUNC(ano_referencia)),
            qtd_turmas NUMBER CHECK (qtd_turmas >= 0 AND qtd_turmas = TRUNC(qtd_turmas)),
            participantes_total NUMBER CHECK (participantes_total >= 0 AND participantes_total = TRUNC(participantes_total)),
            participantes_60mais NUMBER CHECK (participantes_60mais >= 0 AND participantes_60mais = TRUNC(participantes_60mais)),
            fonte_url VARCHAR2(2000) NOT NULL,
            publicado_em DATE NOT NULL,
            consultado_em DATE NOT NULL,
            justificativa VARCHAR2(1000) NOT NULL,
            versao NUMBER DEFAULT 1 NOT NULL CHECK (versao >= 1 AND versao = TRUNC(versao)),
            CONSTRAINT pk_municipio_programa PRIMARY KEY (id_municipio,id_programa,ano_referencia),
            CONSTRAINT ck_oferta_participantes CHECK (participantes_60mais <= participantes_total),
            CONSTRAINT ck_oferta_datas CHECK (publicado_em <= consultado_em),
            CONSTRAINT ck_oferta_url CHECK (REGEXP_LIKE(fonte_url, ''^https://[^[:space:]]+$''))
        )';
        EXECUTE IMMEDIATE 'CREATE INDEX idx_mun_programa_programa ON tab_municipio_programa(id_programa)';
    END IF;
    SELECT COUNT(*) INTO n FROM user_tables WHERE table_name = 'TAB_AUDITORIA_INDICADOR';
    IF n = 0 THEN
        -- Sem FK: excluir um indicador/município não deve apagar sua história.
        EXECUTE IMMEDIATE 'CREATE TABLE tab_auditoria_indicador (
            id_auditoria NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            id_municipio NUMBER NOT NULL,
            operacao VARCHAR2(6) NOT NULL CHECK (operacao IN (''INSERT'',''UPDATE'',''DELETE'')),
            usuario VARCHAR2(128) NOT NULL,
            alterado_em TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP NOT NULL,
            anterior CLOB CHECK (anterior IS JSON),
            novo CLOB CHECK (novo IS JSON)
        )';
        EXECUTE IMMEDIATE 'CREATE INDEX idx_auditoria_municipio ON tab_auditoria_indicador(id_municipio)';
    END IF;
END;
/
