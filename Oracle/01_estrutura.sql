-- Estrutura relacional do projeto. Execute uma vez em um esquema vazio.
-- As três primeiras tabelas seguem banco_base.sql; as demais guardam
-- indicadores consolidados para evitar carregar milhões de linhas na página.

CREATE TABLE tab_regiao (
    id_regiao NUMBER(10) NOT NULL,
    nome VARCHAR2(100) NOT NULL,
    CONSTRAINT pk_tab_regiao PRIMARY KEY (id_regiao)
);

CREATE TABLE tab_uf (
    id_uf NUMBER(10) NOT NULL,
    nome VARCHAR2(100) NOT NULL,
    id_regiao NUMBER(10) NOT NULL,
    CONSTRAINT pk_tab_uf PRIMARY KEY (id_uf),
    CONSTRAINT fk_uf_regiao FOREIGN KEY (id_regiao)
        REFERENCES tab_regiao (id_regiao)
);

CREATE TABLE tab_municipio (
    id_municipio NUMBER(10) NOT NULL,
    nome VARCHAR2(150) NOT NULL,
    id_uf NUMBER(10) NOT NULL,
    CONSTRAINT pk_tab_municipio PRIMARY KEY (id_municipio),
    CONSTRAINT fk_municipio_uf FOREIGN KEY (id_uf)
        REFERENCES tab_uf (id_uf)
);

-- Índices das chaves estrangeiras usados nos JOINs e filtros por UF.
CREATE INDEX idx_uf_id_regiao ON tab_uf (id_regiao);
CREATE INDEX idx_municipio_id_uf ON tab_municipio (id_uf);

CREATE TABLE tab_indicador_municipio (
    id_municipio NUMBER(10) NOT NULL,
    total_alfabetizacao NUMBER(12),
    nao_alfabetizados NUMBER(12),
    total_escolaridade NUMBER(12),
    baixa_escolaridade NUMBER(12),
    renda_media NUMBER(12,2),
    CONSTRAINT pk_indicador_municipio PRIMARY KEY (id_municipio),
    CONSTRAINT fk_indicador_municipio FOREIGN KEY (id_municipio)
        REFERENCES tab_municipio (id_municipio),
    CONSTRAINT ck_alfabetizacao CHECK (
        total_alfabetizacao > 0
        AND nao_alfabetizados BETWEEN 0 AND total_alfabetizacao
    ),
    CONSTRAINT ck_escolaridade CHECK (
        total_escolaridade > 0
        AND baixa_escolaridade BETWEEN 0 AND total_escolaridade
    ),
    CONSTRAINT ck_renda CHECK (renda_media >= 0)
);

CREATE TABLE tab_pnad_resumo (
    nivel_instrucao NUMBER(2) NOT NULL,
    total_amostra NUMBER(10) NOT NULL,
    amostra_com_renda NUMBER(10) NOT NULL,
    renda_media NUMBER(12,2),
    CONSTRAINT pk_pnad_resumo PRIMARY KEY (nivel_instrucao),
    CONSTRAINT ck_pnad_amostra CHECK (
        amostra_com_renda BETWEEN 0 AND total_amostra
    )
);

-- Totais oficiais da UF, independentes da cobertura municipal.
CREATE TABLE tab_indicador_uf (
    id_uf NUMBER(10) NOT NULL,
    total_alfabetizacao NUMBER(12) NOT NULL,
    nao_alfabetizados NUMBER(12) NOT NULL,
    CONSTRAINT pk_indicador_uf PRIMARY KEY (id_uf),
    CONSTRAINT fk_indicador_uf FOREIGN KEY (id_uf) REFERENCES tab_uf (id_uf),
    CONSTRAINT ck_indicador_uf CHECK (
        total_alfabetizacao > 0 AND nao_alfabetizados BETWEEN 0 AND total_alfabetizacao
    )
);
