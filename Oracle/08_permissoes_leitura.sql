-- A aplicação usa MAPA_IDOSOS_RO: leitura apenas, sem INSERT/UPDATE/DELETE.
-- Execute como dono das tabelas após criar MAPA_IDOSOS_RO.

GRANT SELECT ON tab_regiao TO MAPA_IDOSOS_RO;
GRANT SELECT ON tab_uf TO MAPA_IDOSOS_RO;
GRANT SELECT ON tab_municipio TO MAPA_IDOSOS_RO;
GRANT SELECT ON tab_indicador_municipio TO MAPA_IDOSOS_RO;
GRANT SELECT ON tab_indicador_uf TO MAPA_IDOSOS_RO;
GRANT SELECT ON tab_pnad_resumo TO MAPA_IDOSOS_RO;
GRANT SELECT ON vw_mapa_idosos TO MAPA_IDOSOS_RO;
GRANT SELECT ON vw_taxa_uf TO MAPA_IDOSOS_RO;
GRANT SELECT ON vw_pnad_escolaridade TO MAPA_IDOSOS_RO;
