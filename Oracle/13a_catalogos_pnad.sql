-- Catálogos usados pelo resumo e pelo gráfico da PNAD.
-- F5 como dono do esquema, após criar TAB_PNAD_RESUMO e antes de 06_visoes.sql.
-- Repetível: preserva registros e metadados cadastrados. DDL confirma transações no Oracle.
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

DECLARE
    n NUMBER;
BEGIN
    SELECT COUNT(*) INTO n FROM user_tables WHERE table_name='TAB_NIVEL_INSTRUCAO';
    IF n=0 THEN
        -- Descreve os sete códigos de escolaridade presentes nos arquivos da PNAD.
        EXECUTE IMMEDIATE 'CREATE TABLE tab_nivel_instrucao (
            nivel_instrucao NUMBER(2) CONSTRAINT pk_nivel_instrucao PRIMARY KEY,
            nome VARCHAR2(100) NOT NULL
        )';
    END IF;
    SELECT COUNT(*) INTO n FROM user_tables WHERE table_name='TAB_FONTE_DADO';
    IF n=0 THEN
        -- Identifica o arquivo utilizado; ano e URL permanecem NULL se desconhecidos.
        EXECUTE IMMEDIATE 'CREATE TABLE tab_fonte_dado (
            id_fonte NUMBER(10) CONSTRAINT pk_fonte_dado PRIMARY KEY,
            codigo VARCHAR2(40) NOT NULL CONSTRAINT uk_fonte_dado_codigo UNIQUE,
            descricao VARCHAR2(300) NOT NULL,
            arquivo_origem VARCHAR2(200) NOT NULL,
            ano_referencia NUMBER(4),
            url VARCHAR2(2000)
        )';
    END IF;
END;
/

MERGE INTO tab_nivel_instrucao t USING (
    SELECT 1 codigo,'Sem instrução' nome FROM dual UNION ALL
    SELECT 2,'Fundamental incompleto' FROM dual UNION ALL
    SELECT 3,'Fundamental completo' FROM dual UNION ALL
    SELECT 4,'Médio incompleto' FROM dual UNION ALL
    SELECT 5,'Médio completo' FROM dual UNION ALL
    SELECT 6,'Superior incompleto' FROM dual UNION ALL
    SELECT 7,'Superior completo' FROM dual
) s ON (t.nivel_instrucao=s.codigo)
WHEN NOT MATCHED THEN INSERT (nivel_instrucao,nome) VALUES (s.codigo,s.nome);

MERGE INTO tab_fonte_dado t USING (SELECT 1 id_fonte FROM dual) s
ON (t.id_fonte=s.id_fonte)
WHEN NOT MATCHED THEN INSERT (id_fonte,codigo,descricao,arquivo_origem,ano_referencia,url)
VALUES (1,'PNAD_PROJETO','Amostra PNAD de idosos utilizada no projeto',
        'tab_pnad_idosos_INSERT.sql',NULL,NULL);

DECLARE
    n NUMBER;
BEGIN
    SELECT COUNT(*) INTO n FROM user_tab_columns
    WHERE table_name='TAB_PNAD_RESUMO' AND column_name='ID_FONTE';
    IF n=0 THEN
        -- DEFAULT mantém as cargas SQL/Python existentes compatíveis.
        EXECUTE IMMEDIATE 'ALTER TABLE tab_pnad_resumo ADD (id_fonte NUMBER(10) DEFAULT 1)';
    END IF;
END;
/
UPDATE tab_pnad_resumo SET id_fonte=1 WHERE id_fonte IS NULL;
ALTER TABLE tab_pnad_resumo MODIFY (id_fonte DEFAULT 1);

DECLARE
    n NUMBER;
BEGIN
    SELECT COUNT(*) INTO n FROM user_tab_columns
    WHERE table_name='TAB_PNAD_RESUMO' AND column_name='ID_FONTE' AND nullable='Y';
    IF n>0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE tab_pnad_resumo MODIFY (id_fonte NOT NULL)';
    END IF;
    SELECT COUNT(*) INTO n FROM user_constraints WHERE constraint_name='FK_PNAD_NIVEL';
    IF n=0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE tab_pnad_resumo ADD CONSTRAINT fk_pnad_nivel
            FOREIGN KEY (nivel_instrucao) REFERENCES tab_nivel_instrucao(nivel_instrucao)';
    END IF;
    SELECT COUNT(*) INTO n FROM user_constraints WHERE constraint_name='FK_PNAD_FONTE';
    IF n=0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE tab_pnad_resumo ADD CONSTRAINT fk_pnad_fonte
            FOREIGN KEY (id_fonte) REFERENCES tab_fonte_dado(id_fonte)';
    END IF;
END;
/
