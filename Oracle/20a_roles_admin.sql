-- PASSO 1 DE 2 (como SYS com papel SYSDBA, na PDB do projeto).
-- Cria os três perfis (ROLES), os usuários de cada perfil e o privilégio
-- necessário para o dono criar a visão materializada. Não concede acesso a
-- objetos: isso é feito pelo dono em 20_roles_seguranca.sql (passo 2).
-- Repetível: ignora ORA-01921 (role existe) e ORA-01920 (usuário existe).
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
ALTER SESSION SET CONTAINER = FREEPDB1;
SET VERIFY OFF
SET ECHO OFF

-- O dono precisa deste privilégio para criar MV_RESUMO_UF.
GRANT CREATE MATERIALIZED VIEW TO MAPA_IDOSOS;

-- Perfis: o acesso real é concedido às ROLES, nunca diretamente aos usuários.
DECLARE
    PROCEDURE criar_role(p_nome VARCHAR2) IS
        n NUMBER;
    BEGIN
        SELECT COUNT(*) INTO n FROM dba_roles WHERE role=p_nome;
        IF n=0 THEN EXECUTE IMMEDIATE 'CREATE ROLE ' || p_nome; END IF;
    END;
BEGIN
    criar_role('ROLE_ADMIN_MAPA');    -- Administrador: leitura total + EXECUTE em tudo
    criar_role('ROLE_ANALISTA');      -- Analista/Leitura: somente views e MV
    criar_role('ROLE_OPERACIONAL');   -- Operacional: views de consulta + procedures
END;
/

-- Usuários dos perfis. Use senhas fortes, sem aspas ou &.
-- O MAPA_IDOSOS_RO já existe (00_admin_usuarios.sql) e passa a ser o Analista.
ACCEPT SENHA_ADMIN CHAR PROMPT 'Senha de MAPA_ADMIN: ' HIDE
ACCEPT SENHA_OPER  CHAR PROMPT 'Senha de MAPA_OPERADOR: ' HIDE

DECLARE
    PROCEDURE criar_usuario(p_nome VARCHAR2, p_senha VARCHAR2) IS
        n NUMBER;
    BEGIN
        SELECT COUNT(*) INTO n FROM dba_users WHERE username=p_nome;
        IF n=0 THEN
            -- Entrada administrativa: use 12 a 30 letras/numeros, com letra inicial.
            IF NOT REGEXP_LIKE(p_senha,'^[A-Za-z][A-Za-z0-9]{11,29}$') THEN
                RAISE_APPLICATION_ERROR(-20022,'Senha: use 12 a 30 letras e numeros, com letra inicial, sem aspas ou &.');
            END IF;
            EXECUTE IMMEDIATE 'CREATE USER ' || p_nome || ' IDENTIFIED BY ' || DBMS_ASSERT.ENQUOTE_NAME(p_senha,FALSE);
        END IF;
        EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO ' || p_nome;
    END;
BEGIN
    criar_usuario('MAPA_ADMIN',    '&SENHA_ADMIN');
    criar_usuario('MAPA_OPERADOR', '&SENHA_OPER');
END;
/
UNDEFINE SENHA_ADMIN
UNDEFINE SENHA_OPER

GRANT ROLE_ADMIN_MAPA  TO MAPA_ADMIN;
GRANT ROLE_ANALISTA    TO MAPA_IDOSOS_RO;
GRANT ROLE_OPERACIONAL TO MAPA_OPERADOR;

-- Conferência: cada usuário deve aparecer com um único perfil.
SELECT grantee, granted_role FROM dba_role_privs
WHERE grantee IN ('MAPA_ADMIN','MAPA_IDOSOS_RO','MAPA_OPERADOR') ORDER BY 1;
