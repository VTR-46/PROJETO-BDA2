-- Execute no banco existente antes de carregar os totais estaduais.
-- A consulta ao catalogo torna esta migracao repetivel.
DECLARE
    tabelas NUMBER;
BEGIN
    SELECT COUNT(*) INTO tabelas FROM user_tables WHERE table_name = 'TAB_INDICADOR_UF';
    IF tabelas = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE TABLE tab_indicador_uf (
                id_uf NUMBER(10) NOT NULL,
                total_alfabetizacao NUMBER(12) NOT NULL,
                nao_alfabetizados NUMBER(12) NOT NULL,
                CONSTRAINT pk_indicador_uf PRIMARY KEY (id_uf),
                CONSTRAINT fk_indicador_uf FOREIGN KEY (id_uf) REFERENCES tab_uf (id_uf),
                CONSTRAINT ck_indicador_uf CHECK (
                    total_alfabetizacao > 0
                    AND nao_alfabetizados BETWEEN 0 AND total_alfabetizacao
                )
            )';
    END IF;
END;
/
