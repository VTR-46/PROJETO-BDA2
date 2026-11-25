-- Pre-requisito: executar 20a_roles_admin.sql como SYS antes deste roteiro.
-- Execute com F5, conectado como MAPA_IDOSOS em FREEPDB1.
-- Use este roteiro para uma instalação nova, após 00_admin_usuarios.sql.
-- Os @@ apontam para os scripts SQL mantidos na pasta Oracle.
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

@@../01_estrutura.sql
@@../02_regioes_ufs.sql
@@../03_municipios.sql
@@../04_indicadores_municipais.sql
@@../04a_indicadores_ufs.sql
@@../13a_catalogos_pnad.sql
@@../05_pnad_resumo.sql
@@../13_estrutura_programas.sql
@@../14_funcoes.sql
@@../15_procedures.sql
@@../16_triggers.sql
@@../06_visoes.sql
@@../17_programas_reais.sql
COMMIT;
@@../18_validacao_plsql.sql
@@../07_validacao.sql
@@../20_roles_seguranca.sql
