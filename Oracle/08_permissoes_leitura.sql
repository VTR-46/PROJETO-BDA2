-- Compatibilidade: acesso somente por roles. Prepare 20a como SYS antes.
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
@@20_roles_seguranca.sql
