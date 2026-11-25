-- Execute este arquivo com F5 em cada conexao: dono, analista, operador e admin.
-- Cada ramo verifica o usuario. Nao ha DDL nem COMMIT; use conexao sem trabalho pendente.
SET DEFINE OFF
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
DECLARE
 usuario VARCHAR2(128) := SYS_CONTEXT('USERENV','SESSION_USER');
 perfil VARCHAR2(30);
 n NUMBER;
 renda NUMBER;
 nova_versao NUMBER;
 registro mapa_idosos.vw_mapa_idosos%ROWTYPE;
 PROCEDURE negar(sql_text VARCHAR2) IS
 BEGIN
  IF UPPER(SUBSTR(sql_text,1,6))='SELECT' THEN
   DECLARE c SYS_REFCURSOR; BEGIN OPEN c FOR sql_text; CLOSE c; END;
  ELSE EXECUTE IMMEDIATE sql_text; END IF;
  RAISE_APPLICATION_ERROR(-20023,'Acesso proibido foi permitido: ' || sql_text);
 EXCEPTION WHEN OTHERS THEN
  IF SQLCODE NOT IN (-942,-1031) AND NOT
     (SQLCODE=-6550 AND INSTR(SQLERRM,'PLS-00201')>0 AND SUBSTR(sql_text,1,7)='DECLARE')
  THEN RAISE; END IF;
 END;
BEGIN
 IF usuario='MAPA_IDOSOS' THEN
  SELECT COUNT(*) INTO n FROM user_tab_privs_made
  WHERE grantee IN ('MAPA_IDOSOS_RO','MAPA_OPERADOR','MAPA_ADMIN');
  IF n>0 THEN RAISE_APPLICATION_ERROR(-20023,'Ha grants diretos aos perfis. Consulte USER_TAB_PRIVS_MADE.'); END IF;
  SELECT COUNT(*) INTO n FROM user_tab_privs_made
  WHERE (grantee='ROLE_ANALISTA' AND (privilege<>'SELECT' OR table_name NOT IN
    ('VW_MAPA_IDOSOS','VW_TAXA_UF','VW_PNAD_ESCOLARIDADE','VW_CATALOGO_MUNICIPIOS','VW_COBERTURA_UF','VW_PROGRAMAS_MUNICIPIO','MV_RESUMO_UF')))
     OR (grantee='ROLE_OPERACIONAL' AND NOT
       ((privilege='SELECT' AND table_name IN ('VW_CATALOGO_MUNICIPIOS','VW_MAPA_IDOSOS','VW_PROGRAMAS_MUNICIPIO'))
       OR (privilege='EXECUTE' AND table_name IN ('PR_SALVAR_PROGRAMA','PR_REGISTRAR_OFERTA','PR_ATUALIZAR_INDICADORES'))))
     OR (grantee='ROLE_ADMIN_MAPA' AND privilege NOT IN ('SELECT','EXECUTE'));
  IF n>0 THEN RAISE_APPLICATION_ERROR(-20023,'Permissoes extras nas roles. Consulte USER_TAB_PRIVS_MADE.'); END IF;
  SELECT COUNT(*) INTO n FROM user_tab_privs_made WHERE grantee='ROLE_ANALISTA';
  IF n<>7 THEN RAISE_APPLICATION_ERROR(-20023,'Analista deve ter sete SELECTs.'); END IF;
  SELECT COUNT(*) INTO n FROM user_tab_privs_made WHERE grantee='ROLE_OPERACIONAL';
  IF n<>6 THEN RAISE_APPLICATION_ERROR(-20023,'Operador deve ter tres SELECTs e tres EXECUTEs.'); END IF;
  SELECT COUNT(*) INTO n FROM user_mviews WHERE mview_name='MV_RESUMO_UF';
  IF n<>1 THEN RAISE_APPLICATION_ERROR(-20023,'MV ausente.'); END IF;
 ELSIF usuario IN ('MAPA_IDOSOS_RO','MAPA_OPERADOR','MAPA_ADMIN') THEN
  perfil := CASE usuario WHEN 'MAPA_IDOSOS_RO' THEN 'ROLE_ANALISTA'
            WHEN 'MAPA_OPERADOR' THEN 'ROLE_OPERACIONAL' ELSE 'ROLE_ADMIN_MAPA' END;
  SELECT COUNT(*) INTO n FROM session_roles;
  IF n<>1 THEN RAISE_APPLICATION_ERROR(-20023,'Roles extras ou perfil ausente. Consulte SESSION_ROLES.'); END IF;
  SELECT COUNT(*) INTO n FROM session_roles WHERE role=perfil;
  IF n<>1 THEN RAISE_APPLICATION_ERROR(-20023,'Role esperada nao habilitada.'); END IF;
  SELECT COUNT(*) INTO n FROM session_privs WHERE privilege<>'CREATE SESSION';
  IF n>0 THEN RAISE_APPLICATION_ERROR(-20023,'Privilegios de sistema extras. Consulte SESSION_PRIVS.'); END IF;
  SELECT COUNT(*) INTO n FROM mapa_idosos.vw_mapa_idosos WHERE 1=0;
  negar('UPDATE mapa_idosos.tab_indicador_municipio SET renda_media=0 WHERE 1=0');
  negar('DELETE FROM mapa_idosos.tab_indicador_municipio WHERE 1=0');
  IF usuario='MAPA_IDOSOS_RO' THEN
   EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM mapa_idosos.mv_resumo_uf' INTO n;
   negar('SELECT * FROM mapa_idosos.tab_municipio WHERE 1=0');
   negar('DECLARE v NUMBER; BEGIN mapa_idosos.pr_atualizar_indicadores(NULL,NULL,NULL,NULL,NULL,NULL,NULL,v); END;');
  ELSIF usuario='MAPA_OPERADOR' THEN
   negar('SELECT * FROM mapa_idosos.tab_municipio WHERE 1=0');
   SELECT * INTO registro FROM mapa_idosos.vw_mapa_idosos FETCH FIRST 1 ROW ONLY;
   SAVEPOINT teste_operador;
   BEGIN
    EXECUTE IMMEDIATE 'BEGIN mapa_idosos.pr_atualizar_indicadores(:a,:b,:c,:d,:e,:f,:g,:h); END;'
      USING registro.id_municipio,registro.total_alfabetizacao,registro.nao_alfabetizados,
      registro.total_escolaridade,registro.baixa_escolaridade,NVL(registro.renda_media,0)+1,
      registro.versao,OUT nova_versao;
    IF nova_versao<>registro.versao+1 THEN RAISE_APPLICATION_ERROR(-20023,'Versao nao incrementou.'); END IF;
    ROLLBACK TO teste_operador;
   EXCEPTION WHEN OTHERS THEN ROLLBACK TO teste_operador; RAISE;
   END;
  ELSE
   EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM mapa_idosos.tab_auditoria_indicador' INTO n;
   EXECUTE IMMEDIATE 'SELECT mapa_idosos.fn_percentual(1,2) FROM dual' INTO renda;
   IF renda<>50 THEN RAISE_APPLICATION_ERROR(-20023,'Function falhou.'); END IF;
  END IF;
 ELSE
  RAISE_APPLICATION_ERROR(-20023,'Use uma das quatro conexoes documentadas.');
 END IF;
 DBMS_OUTPUT.PUT_LINE('OK: verificacoes do perfil ' || usuario);
END;
/
