-- Execute com F5, conectado como MAPA_IDOSOS em XEPDB1.
-- Use este roteiro no banco já criado. Os MERGEs atualizam ou inserem por chave.
-- Cria a estrutura complementar se ausente e não apaga registros.
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

@@../01a_indicador_uf_migracao.sql
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
@@../08_permissoes_leitura.sql
