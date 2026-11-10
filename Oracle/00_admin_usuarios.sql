-- OPCIONAL: execute apenas em uma instalação nova.
-- Conecte-se como SYS com papel SYSDBA ao serviço XEPDB1.
-- O SQL Developer solicitará as duas senhas. Use senhas fortes sem aspas ou &.
-- Neste computador os usuários já existem; não execute este arquivo novamente.

CREATE USER MAPA_IDOSOS IDENTIFIED BY "&&SENHA_DONO";
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW TO MAPA_IDOSOS;
ALTER USER MAPA_IDOSOS QUOTA UNLIMITED ON USERS;

CREATE USER MAPA_IDOSOS_RO IDENTIFIED BY "&&SENHA_LEITURA";
GRANT CREATE SESSION TO MAPA_IDOSOS_RO;

UNDEFINE SENHA_DONO
UNDEFINE SENHA_LEITURA
