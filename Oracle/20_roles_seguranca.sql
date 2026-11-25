-- PASSO 2 DE 2 (como MAPA_IDOSOS, o dono). Execute após 20a_roles_admin.sql
-- e depois de todos os objetos existirem (01 a 19).
-- Faz três coisas:
--   1) cria a visão materializada MV_RESUMO_UF;
--   2) revoga os SELECT diretos em tabelas do usuário da aplicação;
--   3) concede às ROLES somente o mínimo necessário (views, MV e procedures).
-- As procedures usam AUTHID DEFINER: quem recebe EXECUTE roda com os direitos do
-- dono e NÃO precisa de acesso às tabelas. As views também rodam com os direitos
-- do dono. Por isso analista e operador nunca tocam as tabelas diretamente.
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
BEGIN
 IF SYS_CONTEXT('USERENV','SESSION_USER') <> 'MAPA_IDOSOS' THEN
  RAISE_APPLICATION_ERROR(-20020,'Execute como MAPA_IDOSOS.');
 END IF;
END;
/

-- 1) Visão materializada: consolida por região/UF a taxa de analfabetismo
--    municipal. Atualização sob demanda (dados do Censo mudam raramente).
--    Atualizar: EXEC DBMS_MVIEW.REFRESH('MV_RESUMO_UF', 'C');
DECLARE
 n NUMBER;
 v_query LONG;
 v_expected VARCHAR2(32767) := q'~SELECT r.id_regiao,
       r.nome AS regiao,
       u.id_uf,
       u.nome AS uf,
       COUNT(m.id_municipio)                                   AS municipios,
       COUNT(CASE WHEN i.total_alfabetizacao > 0 AND i.nao_alfabetizados IS NOT NULL THEN 1 END) AS municipios_com_taxa,
       COUNT(i.renda_media) AS municipios_com_renda,
       SUM(i.total_alfabetizacao)                              AS total_alfabetizacao,
       SUM(i.nao_alfabetizados)                                AS nao_alfabetizados,
       fn_percentual(SUM(i.nao_alfabetizados),
                     SUM(i.total_alfabetizacao))               AS taxa_analfabetismo_municipal,
       ROUND(AVG(i.renda_media), 2)                            AS renda_media_municipal
FROM tab_regiao r
JOIN tab_uf u        ON u.id_regiao = r.id_regiao
JOIN tab_municipio m ON m.id_uf = u.id_uf
LEFT JOIN tab_indicador_municipio i ON i.id_municipio = m.id_municipio
GROUP BY r.id_regiao, r.nome, u.id_uf, u.nome~';
BEGIN
 SELECT COUNT(*) INTO n FROM user_mviews WHERE mview_name='MV_RESUMO_UF';
 IF n=0 THEN
  EXECUTE IMMEDIATE 'CREATE MATERIALIZED VIEW mv_resumo_uf BUILD IMMEDIATE REFRESH COMPLETE ON DEMAND AS ' || v_expected;
 ELSE
  SELECT query INTO v_query FROM user_mviews WHERE mview_name='MV_RESUMO_UF';
  IF REGEXP_REPLACE(UPPER(v_query),'[[:space:]]','') <>
     REGEXP_REPLACE(UPPER(v_expected),'[[:space:]]','') THEN
   RAISE_APPLICATION_ERROR(-20021,'Definicao da MV divergente. Planeje migracao explicita; nao houve DROP automatico.');
  END IF;
 END IF;
 SELECT COUNT(*) INTO n FROM user_indexes WHERE index_name='IDX_MV_RESUMO_UF_REGIAO' AND table_name='MV_RESUMO_UF';
 IF n=0 THEN EXECUTE IMMEDIATE 'CREATE INDEX idx_mv_resumo_uf_regiao ON mv_resumo_uf(id_regiao)'; END IF;
END;
/

-- 3a) ROLE_ANALISTA: apenas leitura de views e da MV (nenhuma tabela, nenhuma procedure).
GRANT SELECT ON vw_mapa_idosos          TO ROLE_ANALISTA;
GRANT SELECT ON vw_taxa_uf              TO ROLE_ANALISTA;
GRANT SELECT ON vw_pnad_escolaridade    TO ROLE_ANALISTA;
GRANT SELECT ON vw_catalogo_municipios  TO ROLE_ANALISTA;
GRANT SELECT ON vw_cobertura_uf         TO ROLE_ANALISTA;
GRANT SELECT ON vw_programas_municipio  TO ROLE_ANALISTA;
GRANT SELECT ON mv_resumo_uf            TO ROLE_ANALISTA;

-- 3b) ROLE_OPERACIONAL: consulta o necessário e altera dados SOMENTE via procedures,
--     que validam regras, controlam versão e disparam a auditoria. Sem DML direto.
GRANT SELECT ON vw_catalogo_municipios  TO ROLE_OPERACIONAL;
GRANT SELECT ON vw_mapa_idosos          TO ROLE_OPERACIONAL;
GRANT SELECT ON vw_programas_municipio  TO ROLE_OPERACIONAL;
GRANT EXECUTE ON pr_salvar_programa       TO ROLE_OPERACIONAL;
GRANT EXECUTE ON pr_registrar_oferta      TO ROLE_OPERACIONAL;
GRANT EXECUTE ON pr_atualizar_indicadores TO ROLE_OPERACIONAL;

-- 3c) ROLE_ADMIN_MAPA: leitura de tudo (inclui a tabela de auditoria) e EXECUTE em
--     todos os objetos PL/SQL. DDL e DML estrutural continuam exclusivos do dono.
BEGIN
    FOR o IN (SELECT column_value AS nome FROM TABLE(sys.odcivarchar2list(
        'TAB_REGIAO','TAB_UF','TAB_MUNICIPIO','TAB_INDICADOR_MUNICIPIO',
        'TAB_INDICADOR_UF','TAB_PNAD_RESUMO','TAB_NIVEL_INSTRUCAO','TAB_FONTE_DADO',
        'TAB_PROGRAMA','TAB_MUNICIPIO_PROGRAMA','TAB_AUDITORIA_INDICADOR',
        'VW_MAPA_IDOSOS','VW_TAXA_UF','VW_PNAD_ESCOLARIDADE','VW_CATALOGO_MUNICIPIOS',
        'VW_COBERTURA_UF','VW_PROGRAMAS_MUNICIPIO','MV_RESUMO_UF'))) LOOP
        EXECUTE IMMEDIATE 'GRANT SELECT ON ' || o.nome || ' TO ROLE_ADMIN_MAPA';
    END LOOP;
    FOR o IN (SELECT column_value AS nome FROM TABLE(sys.odcivarchar2list(
        'PR_SALVAR_PROGRAMA','PR_REGISTRAR_OFERTA','PR_ATUALIZAR_INDICADORES',
        'FN_PERCENTUAL','FN_VALIDAR_INDICADORES'))) LOOP
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON ' || o.nome || ' TO ROLE_ADMIN_MAPA';
    END LOOP;
END;
/

-- 2) Remove os acessos diretos às tabelas concedidos por 08_permissoes_leitura.sql.
--    NÃO execute mais o 08: ele recriaria esses acessos. Esta etapa o substitui.
BEGIN
    FOR t IN (SELECT column_value AS nome FROM TABLE(sys.odcivarchar2list(
        'TAB_REGIAO','TAB_UF','TAB_MUNICIPIO','TAB_INDICADOR_MUNICIPIO',
        'TAB_INDICADOR_UF','TAB_PNAD_RESUMO'))) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'REVOKE SELECT ON ' || t.nome || ' FROM MAPA_IDOSOS_RO';
        EXCEPTION WHEN OTHERS THEN
            IF SQLCODE <> -1927 THEN RAISE; END IF;   -- privilégio já ausente
        END;
    END LOOP;
    -- Revoga também as views que o RO recebia direto: agora vêm pela role.
    FOR v IN (SELECT column_value AS nome FROM TABLE(sys.odcivarchar2list(
        'VW_MAPA_IDOSOS','VW_TAXA_UF','VW_PNAD_ESCOLARIDADE',
        'VW_CATALOGO_MUNICIPIOS','VW_COBERTURA_UF','VW_PROGRAMAS_MUNICIPIO'))) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'REVOKE SELECT ON ' || v.nome || ' FROM MAPA_IDOSOS_RO';
        EXCEPTION WHEN OTHERS THEN
            IF SQLCODE <> -1927 THEN RAISE; END IF;
        END;
    END LOOP;
END;
/

