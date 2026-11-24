# Dicionário de dados e objetos PL/SQL

Este documento resume a finalidade das tabelas, funções, procedures e triggers do esquema Oracle do projeto. Os comentários nos scripts (`01_estrutura.sql`, `13_estrutura_programas.sql`, `14_funcoes.sql`, `15_procedures.sql` e `16_triggers.sql`) também descrevem cada objeto junto à sua definição.

## Tabelas

| Tabela | O que armazena |
|---|---|
| `TAB_REGIAO` | Regiões geográficas brasileiras. |
| `TAB_UF` | Unidades federativas e sua região. |
| `TAB_MUNICIPIO` | Municípios identificados pelo código IBGE e sua UF. |
| `TAB_INDICADOR_MUNICIPIO` | Totais de alfabetização e escolaridade, contagem de idosos não alfabetizados/baixa escolaridade e renda média por município. A coluna `VERSAO` controla atualizações concorrentes. |
| `TAB_PNAD_RESUMO` | Resumo da amostra PNAD por nível de instrução, com total de registros e renda média dos registros com renda informada. |
| `TAB_INDICADOR_UF` | Totais oficiais de alfabetização e pessoas não alfabetizadas por UF, independentes da soma de municípios disponíveis. |
| `TAB_PROGRAMA` | Catálogo de programas: código, nome, órgão, público, abrangência (nacional ou estadual), UF quando aplicável e fonte consultada. |
| `TAB_MUNICIPIO_PROGRAMA` | Oferta documentada de um programa em um município e ano: turmas, participantes, fonte, datas, justificativa e versão. Não representa matrícula individual. |
| `TAB_AUDITORIA_INDICADOR` | Registro de INSERT, UPDATE e DELETE em indicadores municipais, com usuário, instante e valores anteriores/novos em JSON. Não possui FK para preservar o histórico se o município for removido. |

## Functions

| Function | Finalidade |
|---|---|
| `FN_PERCENTUAL(parte, total)` | Calcula `parte / total * 100`, arredondado a duas casas. Retorna `NULL` se faltar entrada ou o total for zero; rejeita contagens negativas ou parte maior que total. |
| `FN_VALIDAR_INDICADORES(total_a, nao_a, total_e, baixa_e, renda)` | Valida consistência, integridade dos pares de valores ausentes, contagens inteiras e renda não negativa. Retorna `1` se válido ou gera erro Oracle se inválido. |

## Procedures

| Procedure | Finalidade |
|---|---|
| `PR_SALVAR_PROGRAMA` | Insere um programa ou atualiza seus metadados pelo código único. Retorna o ID e impede mudar abrangência/UF quando já há ofertas vinculadas. |
| `PR_REGISTRAR_OFERTA` | Insere uma oferta anual ou retifica uma existente. Usa versão esperada para evitar sobrescrever alteração concorrente; retificação requer justificativa. Retorna a nova versão. |
| `PR_ATUALIZAR_INDICADORES` | Substitui os indicadores de um município existente após validação e conferência da versão esperada. Retorna a nova versão. |

As procedures definem savepoints e não executam `COMMIT`: a confirmação ou reversão final pertence ao chamador.

## Triggers

| Trigger | Finalidade |
|---|---|
| `TRG_INDICADOR_AUDITORIA` | Valida DML direto em indicadores, incrementa a versão quando os valores mudam e grava o estado anterior/novo na auditoria. Alterações sem mudança de valores preservam a versão e não geram auditoria. |
| `TRG_OFERTA_VALIDACAO` | Confere se município pertence à UF do programa estadual, protege a identidade município/programa/ano e controla a versão da oferta. |

Os triggers executam na mesma transação do DML: se a operação for revertida, a auditoria também é revertida.
