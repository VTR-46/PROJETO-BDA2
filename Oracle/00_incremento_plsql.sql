-- F5 como dono, na mesma PDB das tabelas existentes. Não recarrega o Censo.
SET DEFINE OFF
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
@@13_estrutura_programas.sql
@@14_funcoes.sql
@@15_procedures.sql
@@16_triggers.sql
@@06_visoes.sql
@@17_programas_reais.sql
COMMIT;
@@18_validacao_plsql.sql
@@08_permissoes_leitura.sql
