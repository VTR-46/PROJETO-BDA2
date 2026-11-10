-- DROP TABLE tab_municipio CASCADE CONSTRAINTS;
-- DROP TABLE tab_uf CASCADE CONSTRAINTS;
-- DROP TABLE tab_regiao CASCADE CONSTRAINTS;

-- 1. Tabela de Regiões
CREATE TABLE tab_regiao (
    id_regiao NUMBER(10)    NOT NULL,
    nome      VARCHAR2(100) NOT NULL,
    CONSTRAINT pk_tab_regiao PRIMARY KEY (id_regiao)
);

-- 2. Tabela de Unidades Federativas (UF)
CREATE TABLE tab_uf (
    id_uf     NUMBER(10)    NOT NULL,
    nome      VARCHAR2(100) NOT NULL,
    id_regiao NUMBER(10)    NOT NULL,
    CONSTRAINT pk_tab_uf PRIMARY KEY (id_uf),
    CONSTRAINT fk_uf_regiao FOREIGN KEY (id_regiao)
        REFERENCES tab_regiao (id_regiao)
);

-- 3 Tabela de Municípios
CREATE TABLE tab_municipio (
    id_municipio NUMBER(10)    NOT NULL,
    nome         VARCHAR2(150) NOT NULL,
    id_uf        NUMBER(10)    NOT NULL,
    CONSTRAINT pk_tab_municipio PRIMARY KEY (id_municipio),
    CONSTRAINT fk_municipio_uf FOREIGN KEY (id_uf) REFERENCES tab_uf (id_uf)
);

-- Índices para as chaves estrangeiras (boas práticas no Oracle para evitar locks e otimizar JOINs)
CREATE INDEX idx_uf_id_regiao ON tab_uf (id_regiao);
CREATE INDEX idx_municipio_id_uf ON tab_municipio (id_uf);