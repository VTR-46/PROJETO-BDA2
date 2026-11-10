PRONTUÁRIOS

Gabriela Moura Pereira- AQ303707X
Larissa Mari Hanada-   AQ3038769
Victor Ricardo Marques- Teodoro AQ3038491
Lesli Eloy Da Silva- AQ3037282


-- =====================================================================
-- 1 Junções e Subconsultas
-- =====================================================================
CREATE TABLE TAB_PNAD_IDOSOS (
IDADE NUMBER(38),
NIVEL_INSTRUCAO NUMBER(38),
RENDA_MENSAL NUMBER(26));

SELECT * FROM TAB_PNAD_IDOSOS;  --teste

CREATE TABLE tab_censo_idosos (
localizacao VARCHAR2(70),
sexo VARCHAR2(26),
cor_ou_raca VARCHAR2(26),
grupo_de_idade VARCHAR2(26),
nivel_de_instrucao VARCHAR2(128),
quantidade_idosos_por_formacao NUMBER(38),
rendimento_nominal_medio_idosos NUMBER(38));

CREATE TABLE censo_alfabetizacao_formatado (
    localizacao VARCHAR2(500),
    cor_ou_raca VARCHAR2(100),
    grupo_de_idade VARCHAR2(100),
    sexo VARCHAR2(50),
    alfabetizacao VARCHAR2(100),
    qtd_idosos NUMBER(25, 0)
);


-- Tabela adicional criada para viabilizar a junção de 3 tabelas com LEFT JOIN
CREATE TABLE tab_programas_sociais (
    localizacao VARCHAR2(500),
    nome_programa VARCHAR2(100),
    orcamento_mensal NUMBER(26)
);

-- Consulta atendendo ao requisito (3 tabelas, INNER JOIN e LEFT JOIN)
-- Contexto: Listar os dados demográficos dos idosos, cruzando com os índices de
-- alfabetização e identificando se a localização possui ou não um programa social ativo.
SELECT
    c.localizacao,
    c.grupo_de_idade,
    c.sexo,
    a.alfabetizacao,
    c.rendimento_nominal_medio_idosos,
    p.nome_programa
FROM tab_censo_idosos c
INNER JOIN censo_alfabetizacao_formatado a
    ON c.localizacao = a.localizacao
    AND c.sexo = a.sexo
LEFT JOIN tab_programas_sociais p
    ON c.localizacao = p.localizacao;

-- =====================================================================
-- 2 Tomada de Decisão com SUBCONSULTAS
-- =====================================================================

SELECT
    CASE nivel_instrucao
        WHEN 1 THEN 'Sem instrução'
        WHEN 2 THEN 'Fundamental incompleto'
        WHEN 3 THEN 'Fundamental completo'
        WHEN 4 THEN 'Médio incompleto'
        WHEN 5 THEN 'Médio completo'
        WHEN 6 THEN 'Superior incompleto'
        WHEN 7 THEN 'Superior completo'
        ELSE 'Não identificado'
    END AS descricao_escolaridade,
    ROUND(AVG(renda_mensal), 2) AS media_renda_reais,
    COUNT(*) AS volume_amostra
FROM
    tab_pnad_idosos
WHERE
    renda_mensal IS NOT NULL
GROUP BY
    nivel_instrucao
ORDER BY
    nivel_instrucao;

-- =====================================================================
-- 3 OPERAÇÕES DE CONJUNTO (UNION)
-- =====================================================================

SELECT
    'Vulnerabilidade (Sem Instrução)' AS PERFIL,
    COUNT(*) AS TOTAL_IDOSOS,
    ROUND(AVG(RENDA_MENSAL), 2) AS MEDIA_RENDA
FROM TAB_PNAD_IDOSOS
WHERE NIVEL_INSTRUCAO = 1 AND RENDA_MENSAL IS NOT NULL

UNION

SELECT
    'Alta Qualificação (Superior Completo)' AS PERFIL,
    COUNT(*) AS TOTAL_IDOSOS,
    ROUND(AVG(RENDA_MENSAL), 2) AS MEDIA_RENDA
FROM TAB_PNAD_IDOSOS
WHERE NIVEL_INSTRUCAO = 7 AND RENDA_MENSAL IS NOT NULL;


-- =====================================================================
-- 4 Abstração e Segurança com VISÕES (Views)
-- =====================================================================

CREATE OR REPLACE VIEW VW_ESCOLARIDADE_RENDA (escolaridade, total_idosos, media_renda)
AS SELECT
    CASE nivel_instrucao
        WHEN 1 THEN 'Sem instrução'
        WHEN 2 THEN 'Fundamental incompleto'
        WHEN 3 THEN 'Fundamental completo'
        WHEN 4 THEN 'Médio incompleto'
        WHEN 5 THEN 'Médio completo'
        WHEN 6 THEN 'Superior incompleto'
        WHEN 7 THEN 'Superior completo'
        ELSE 'Não identificado'
    END,
    COUNT(*),
    ROUND(AVG(renda_mensal), 2)
FROM TAB_PNAD_IDOSOS
WHERE renda_mensal IS NOT NULL
GROUP BY nivel_instrucao
ORDER BY nivel_instrucao
WITH READ ONLY;

SELECT * FROM VW_ESCOLARIDADE_RENDA;

--JUSTIFICATIVAÇÃO:
--A visão VW_ESCOLARIDADE_RENDA simplifica o desenvolvimento por esconder a complexidade dos cálculos e da tradução dos dados,
--isso permite que a aplicação consulte o relatório final através do SELECT * FROM VW_ESCOLARIDADE_RENDA . Além disso, o uso de
--WITH READ ONLY  impede qualquer alteração ou eliminação acidental de dados, garantindo a segurança dos 70mil registros do banco de dados.

-- =====================================================================
-- 5 CONFIGURAÇÃO INICIAL E CRIAÇÃO DE USUÁRIOS
-- =============================================


ALTER SESSION SET "_ORACLE_SCRIPT"=true;

-- 1. Criação do Usuário Administrador do Sistema
CREATE USER admin_sistema IDENTIFIED BY "SenhaForteAdmin123";
GRANT CONNECT, RESOURCE TO admin_sistema;
ALTER USER admin_sistema QUOTA UNLIMITED ON USERS;

-- 2. Criação do Usuário para o Perfil de Relatórios/Auditoria
CREATE USER perfil_auditoria IDENTIFIED BY "SenhaAuditoria2026";
GRANT CREATE SESSION TO perfil_auditoria;

-- Cria a tabela de logs do sistema
CREATE TABLE TAB_LOGS_SISTEMA (
    id_log NUMBER PRIMARY KEY,
    data_acao DATE,
    descricao VARCHAR2(255)
);


-- APLICAÇÃO DA ARQUITETURA DE SEGURANÇA (GRANTS E REVOKES)


-- dá permissões totais nas tabelas para o admin_sistema
GRANT SELECT, INSERT, UPDATE, DELETE ON TAB_PNAD_IDOSOS TO admin_sistema;
GRANT SELECT, INSERT, UPDATE, DELETE ON TAB_LOGS_SISTEMA TO admin_sistema;

-- Remove  a permissão de deletar dados da tabela de logs do administrador
REVOKE DELETE ON TAB_LOGS_SISTEMA FROM admin_sistema;

-- Dá acesso estritamente de leitura apenas na VIEW para o perfil_auditoria
GRANT SELECT ON VW_ESCOLARIDADE_RENDA TO perfil_auditoria;


-- ================================================
-- 6. GARANTIA DE CONSISTÊNCIA COM TRANSAÇÕES
-- ==============================================
BEGIN
    -- 1. Atualiza a primeira tabela
    UPDATE tab_censo_idosos
    SET quantidade_idosos_por_formacao = quantidade_idosos_por_formacao + 50
    WHERE localizacao = 'Bahia' AND nivel_de_instrucao = 'Superior completo';

    -- 2. Atualiza a segunda tabela
    UPDATE censo_alfabetizacao_formatado
    SET qtd_idosos = qtd_idosos + 50
    WHERE localizacao = 'Bahia' AND alfabetizacao = 'Sabe ler e escrever';

    -- Se tudo der certo, confirma e salva as duas operações juntas
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        -- JUSTIFICATIVA DO ROLLBACK:
        -- Se a atualização da segunda tabela der erro (ex: falha no banco),
        -- o ROLLBACK desfaz a primeira. Isso evita dados inconsistentes,
        -- garantindo que ou as duas tabelas são atualizadas, ou nenhuma.
        ROLLBACK;
END;
/

-- Execute este SELECT isoladamente APÓS rodar o bloco acima para ver o resultado:
SELECT * FROM tab_censo_idosos
WHERE localizacao = 'Bahia' AND nivel_de_instrucao = 'Superior completo';
