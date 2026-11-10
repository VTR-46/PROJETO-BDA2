-- Execute com F5, conectado como MAPA_IDOSOS em XEPDB1.
-- Use este roteiro no banco já criado. Os MERGEs atualizam ou inserem por chave.
-- Não executa CREATE TABLE e não apaga registros.

@@01a_indicador_uf_migracao.sql
@@02_regioes_ufs.sql
@@03_municipios.sql
@@04_indicadores_municipais.sql
@@04a_indicadores_ufs.sql
@@05_pnad_resumo.sql
@@06_visoes.sql
@@07_validacao.sql
@@08_permissoes_leitura.sql
