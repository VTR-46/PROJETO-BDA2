# MER e modelo relacional

Este documento descreve as 11 tabelas do esquema: três geográficas base e oito adicionais para indicadores, catálogos, programas, ofertas e auditoria.

## Modelo Entidade-Relacionamento (MER)

```mermaid
erDiagram
    TAB_REGIAO ||--|{ TAB_UF : "abrange"
    TAB_UF ||--|{ TAB_MUNICIPIO : "localiza"
    TAB_MUNICIPIO ||--o| TAB_INDICADOR_MUNICIPIO : "possui indicadores"
    TAB_UF ||--o| TAB_INDICADOR_UF : "possui totais oficiais"
    TAB_PROGRAMA ||--o{ TAB_MUNICIPIO_PROGRAMA : "tem ofertas"
    TAB_MUNICIPIO ||--o{ TAB_MUNICIPIO_PROGRAMA : "recebe ofertas documentadas"
    TAB_MUNICIPIO ||--o{ TAB_AUDITORIA_INDICADOR : "origina eventos de auditoria"
    TAB_NIVEL_INSTRUCAO ||--o| TAB_PNAD_RESUMO : "classifica o resumo"
    TAB_FONTE_DADO ||--o{ TAB_PNAD_RESUMO : "identifica a origem"

    TAB_REGIAO {
        NUMBER id_regiao PK
        VARCHAR2 nome
    }
    TAB_UF {
        NUMBER id_uf PK
        VARCHAR2 nome
        NUMBER id_regiao FK
    }
    TAB_MUNICIPIO {
        NUMBER id_municipio PK
        VARCHAR2 nome
        NUMBER id_uf FK
    }
    TAB_INDICADOR_MUNICIPIO {
        NUMBER id_municipio PK, FK
        NUMBER total_alfabetizacao
        NUMBER nao_alfabetizados
        NUMBER total_escolaridade
        NUMBER baixa_escolaridade
        NUMBER renda_media
        NUMBER versao
    }
    TAB_PNAD_RESUMO {
        NUMBER nivel_instrucao PK, FK
        NUMBER total_amostra
        NUMBER amostra_com_renda
        NUMBER renda_media
        NUMBER id_fonte FK
    }
    TAB_NIVEL_INSTRUCAO {
        NUMBER nivel_instrucao PK
        VARCHAR2 nome
    }
    TAB_FONTE_DADO {
        NUMBER id_fonte PK
        VARCHAR2 codigo UK
        VARCHAR2 descricao
        VARCHAR2 arquivo_origem
        NUMBER ano_referencia
        VARCHAR2 url
    }
    TAB_INDICADOR_UF {
        NUMBER id_uf PK, FK
        NUMBER total_alfabetizacao
        NUMBER nao_alfabetizados
    }
    TAB_PROGRAMA {
        NUMBER id_programa PK
        VARCHAR2 codigo UK
        VARCHAR2 nome
        VARCHAR2 orgao
        VARCHAR2 publico
        VARCHAR2 abrangencia
        NUMBER id_uf FK "opcional para programa nacional"
        VARCHAR2 fonte_url
        DATE consultado_em
    }
    TAB_MUNICIPIO_PROGRAMA {
        NUMBER id_municipio PK, FK
        NUMBER id_programa PK, FK
        NUMBER ano_referencia PK
        NUMBER qtd_turmas
        NUMBER participantes_total
        NUMBER participantes_60mais
        VARCHAR2 fonte_url
        DATE publicado_em
        DATE consultado_em
        VARCHAR2 justificativa
        NUMBER versao
    }
    TAB_AUDITORIA_INDICADOR {
        NUMBER id_auditoria PK
        NUMBER id_municipio "referência lógica sem FK"
        VARCHAR2 operacao
        VARCHAR2 usuario
        TIMESTAMP alterado_em
        CLOB anterior
        CLOB novo
    }
```

`TAB_PNAD_RESUMO` é um resumo nacional agregado por nível de instrução, ligado aos catálogos de níveis e fontes. `TAB_AUDITORIA_INDICADOR.id_municipio` não possui chave estrangeira intencionalmente, para preservar os registros de auditoria mesmo se o município relacionado for removido.

## Cardinalidades e regras

| Relacionamento | Cardinalidade | Regra implementada |
|---|---|---|
| Região — UF | 1:N | Cada UF referencia exatamente uma região; uma região possui uma ou mais UFs. |
| UF — Município | 1:N | Cada município referencia exatamente uma UF; uma UF pode ter vários municípios. |
| Município — Indicador municipal | 1:0..1 | Pode existir no máximo um registro de indicadores por município; a ausência do registro ou de valores é permitida. |
| UF — Indicador estadual | 1:0..1 | Pode existir no máximo um registro de totais oficiais por UF. |
| Programa — Oferta municipal | 1:0..N | Um programa pode ter ofertas em vários municípios e anos. |
| Município — Oferta municipal | 1:0..N | Um município pode registrar vários programas e anos. |
| Programa — Município | N:M, resolvido por `TAB_MUNICIPIO_PROGRAMA` | A chave da associativa é `(id_municipio, id_programa, ano_referencia)`, portanto há uma ocorrência por município, programa e ano. |
| Município — Auditoria | 1:0..N lógica | Eventos guardam o código do município, sem FK física para manter o histórico. |
| Nível de instrução — Resumo PNAD | 1:0..1 | Cada nível tem no máximo um resumo; todo resumo exige um nível cadastrado. |
| Fonte — Resumo PNAD | 1:0..N | Uma fonte pode ser usada por vários níveis; todo resumo exige uma fonte cadastrada. |

Os símbolos Mermaid `||`, `|{`, `o|` e `o{` indicam respectivamente “um obrigatório”, “um ou mais”, “zero ou um” e “zero ou muitos”.

## Modelo relacional

### Tabelas base

- **TAB_REGIAO** (`id_regiao` PK, `nome`)
- **TAB_UF** (`id_uf` PK, `nome`, `id_regiao` FK → `TAB_REGIAO.id_regiao`)
- **TAB_MUNICIPIO** (`id_municipio` PK, `nome`, `id_uf` FK → `TAB_UF.id_uf`)

### Tabelas adicionais

- **TAB_INDICADOR_MUNICIPIO** (`id_municipio` PK e FK → `TAB_MUNICIPIO.id_municipio`, `total_alfabetizacao`, `nao_alfabetizados`, `total_escolaridade`, `baixa_escolaridade`, `renda_media`, `versao`)
- **TAB_PNAD_RESUMO** (`nivel_instrucao` PK/FK → `TAB_NIVEL_INSTRUCAO.nivel_instrucao`, `total_amostra`, `amostra_com_renda`, `renda_media`, `id_fonte` FK → `TAB_FONTE_DADO.id_fonte`)
- **TAB_NIVEL_INSTRUCAO** (`nivel_instrucao` PK, `nome`)
- **TAB_FONTE_DADO** (`id_fonte` PK, `codigo` UNIQUE, `descricao`, `arquivo_origem`, `ano_referencia`, `url`)
- **TAB_INDICADOR_UF** (`id_uf` PK e FK → `TAB_UF.id_uf`, `total_alfabetizacao`, `nao_alfabetizados`)
- **TAB_PROGRAMA** (`id_programa` PK, `codigo` UNIQUE, `nome`, `orgao`, `publico`, `abrangencia`, `id_uf` FK opcional → `TAB_UF.id_uf`, `fonte_url`, `consultado_em`)
- **TAB_MUNICIPIO_PROGRAMA** (`id_municipio` PK e FK → `TAB_MUNICIPIO.id_municipio`, `id_programa` PK e FK → `TAB_PROGRAMA.id_programa`, `ano_referencia` PK, `qtd_turmas`, `participantes_total`, `participantes_60mais`, `fonte_url`, `publicado_em`, `consultado_em`, `justificativa`, `versao`)
- **TAB_AUDITORIA_INDICADOR** (`id_auditoria` PK, `id_municipio` sem FK, `operacao`, `usuario`, `alterado_em`, `anterior`, `novo`)

## Integridade referencial

As FKs geográficas ligam região → UF → município. Os indicadores usam relacionamento um-para-um opcional com sua unidade geográfica, implementado por PK compartilhada. A tabela associativa conecta programa e município e inclui o ano na chave para manter ofertas anuais separadas. As regras adicionais de abrangência estadual, versões e auditoria são aplicadas pelas constraints, procedures e triggers descritas em [`DICIONARIO_DADOS.md`](DICIONARIO_DADOS.md).
