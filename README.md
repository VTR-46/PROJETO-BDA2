# Mapa do analfabetismo de idosos no Brasil

Aplicação web para explorar a **taxa de analfabetismo de pessoas com 60 anos ou mais** nos estados e municípios brasileiros, junto com indicadores de renda e escolaridade.

O painel oferece:

- Mapa interativo com seleção de UF e busca nacional por município.
- Indicadores municipais de analfabetismo, baixa escolaridade e renda média.
- Gráficos de renda versus analfabetismo e renda por escolaridade na amostra PNAD.
- Tabela de ofertas documentadas de programas de alfabetização, com filtros e fontes.
- Pesquisa opcional com Gemini para explorar o contexto do município e fazer perguntas.

## Como funciona

```text
Dados do IBGE e arquivos do projeto → Oracle → API Flask → HTML, JavaScript e Leaflet
```

O Oracle armazena os dados e suas regras. O Flask consulta as views com uma conta de leitura e envia os resultados ao navegador. Ao carregar uma UF, a página recebe os indicadores dos seus municípios; o clique no mapa mostra o registro correspondente.

O banco possui **11 tabelas: 3 do esquema geográfico base e 8 adicionais**, além de **3 procedures, 2 functions, 2 triggers e 6 views**.

## Como executar — passo a passo

### 1. Preparar o computador

Instale **Python 3.10 ou superior**, com `pip` e `venv`. No Windows, habilite Python no `PATH`. Você também precisa de acesso a um **Oracle preparado**, local ou remoto, e de internet na primeira instalação das dependências.

Clone o repositório ou copie a pasta do projeto. Ao transferir para outra máquina, deixe que ela crie sua própria `.venv` e configure suas próprias credenciais.

### 2. Preparar o Oracle

Se o banco já está instalado e atualizado, siga para o passo 3.

Execute manualmente os **scripts SQL de `00` a `19` da pasta `Oracle/`**, com **F5 — Executar Script** no SQL Developer, seguindo a sequência abaixo. Alguns arquivos têm dependências: por isso, o `06_visoes.sql` vem depois das funções e das tabelas complementares, mesmo tendo número menor.

Para uma instalação nova:

| Ordem | Arquivo em `Oracle/` | O que fazer |
|---|---|---|
| 1 | `00_admin_usuarios.sql` | Como `SYS` com papel `SYSDBA`, criar os usuários e informar as senhas. |
| 2 | `00_permissoes_plsql.sql` | Ainda como `SYS`, conceder permissões PL/SQL. A criação dos usuários já concede essas permissões; este arquivo também atende instalações antigas. |
| 3 | `01_estrutura.sql` | Trocar para `MAPA_IDOSOS` e criar as tabelas em um esquema vazio. |
| 4 | `02_regioes_ufs.sql` e `03_municipios.sql` | Executar nessa ordem para carregar regiões, UFs e municípios. |
| 5 | `04_indicadores_municipais.sql` e `04a_indicadores_ufs.sql` | Carregar os indicadores municipais e estaduais. |
| 6 | `13a_catalogos_pnad.sql` e `05_pnad_resumo.sql` | Criar os catálogos e depois carregar o resumo da PNAD. |
| 7 | `13_estrutura_programas.sql` | Criar programas, ofertas e auditoria; acrescentar o controle de versão. |
| 8 | `14_funcoes.sql`, `15_procedures.sql` e `16_triggers.sql` | Executar nessa ordem para criar os objetos PL/SQL. |
| 9 | `06_visoes.sql` | Criar as views após suas dependências. |
| 10 | `17_programas_reais.sql` | Carregar os programas e as ofertas documentadas; depois executar `COMMIT;`. |
| 11 | `18_validacao_plsql.sql` e `07_validacao.sql` | Conferir a compilação e os dados carregados. |
| 12 | `08_permissoes_leitura.sql` | Liberar a leitura para o usuário da página. |
| 13 | `09_consulta_analfabetismo.sql` até `12_consulta_codigos_municipios.sql` | Executar as consultas de exemplo. Elas não alteram dados. |
| 14 | `19_demonstracao_plsql.sql` | Demonstrar as regras e a auditoria; o script desfaz suas alterações temporárias. |

Após a etapa 2, os demais arquivos são executados como **`MAPA_IDOSOS`**, com atribuição padrão. Confira a saída de cada etapa antes de continuar.

No banco existente, não recrie usuários nem execute `01_estrutura.sql`. O arquivo `01a_indicador_uf_migracao.sql` cria a tabela estadual se ela ainda estiver ausente. Para atualizar os dados ou os objetos, execute os arquivos correspondentes respeitando as dependências acima; recarregar indicadores pode substituir correções manuais.

Os exemplos usam `localhost:1521/XEPDB1`. Ajuste host, porta e serviço à sua instalação. Para a explicação de cada arquivo, consulte o [guia Oracle](Oracle/README.md).

**O banco é preparado uma vez por instalação.** Para executar a página em outra máquina, basta que ela consiga acessar esse Oracle.

### 3. Configurar a conexão

Copie `.env.example` para um arquivo chamado `.env`, na raiz do projeto, e preencha:

```dotenv
ORACLE_USER=MAPA_IDOSOS_RO
ORACLE_PASSWORD=SUA_SENHA_DE_LEITURA
ORACLE_DSN=localhost:1521/XEPDB1
```

Para um Oracle remoto, troque `localhost` pelo endereço do servidor. Use a senha de leitura criada no passo anterior. Não publique `.env` nem `.owner.env`, pois contêm credenciais.

### 4. Iniciar a aplicação

Abra o terminal na pasta que contém `iniciar.py` e execute:

```powershell
python iniciar.py
```

No Linux/macOS, use `python3 iniciar.py` se esse for o comando disponível.

O iniciador cria a pasta `.venv`, instala as dependências e inicia o Flask. Nas próximas execuções, reutiliza o ambiente. Ele não instala o Oracle nem carrega o banco.

### 5. Abrir e utilizar a página

Acesse **<http://127.0.0.1:5000>** no mesmo computador em que iniciou o servidor.

Escolha uma UF ou busque um município para consultar os indicadores. Use **Ver Brasil** para retornar ao mapa nacional. As seções podem ser recolhidas clicando no título. Para encerrar o servidor, pressione **Ctrl+C** no terminal.

Os mapas e os dados SQL já acompanham o projeto. Para apenas executar a página, não é necessário instalar Node.js ou SQL Developer no computador que acessa o Oracle.

## Pesquisa com Gemini — opcional

Para habilitar a pesquisa, acrescente ao `.env` e reinicie o servidor:

```dotenv
GEMINI_API_KEY=SUA_CHAVE
GEMINI_GOOGLE_SEARCH=0
```

Obtenha a chave no [Google AI Studio](https://aistudio.google.com/apikey). Selecione um município e clique em **Pesquisar município com Gemini**. Depois, use o campo de perguntas para continuar a conversa.

O servidor consulta os indicadores no Oracle antes de enviá-los ao Gemini. A chave fica no servidor. As conversas ficam na memória da aba e são perdidas ao recarregar. Cada envio depende da cota e do acesso do seu projeto Google; em caso de erro, a página informa o problema. O mapa funciona sem essa chave.

## Dados e limites da análise

- **Alfabetização:** Censo 2022, tabela 9542 do IBGE, para pessoas com 60 anos ou mais. A taxa estadual usa os totais oficiais da UF.
- **Renda e escolaridade municipais:** arquivo `CSV/censo_idosos_consolidado.csv`; o ano não está documentado. Baixa escolaridade significa “sem instrução e fundamental incompleto”.
- **PNAD:** resumo nacional de 76.492 registros, sem pesos amostrais nos arquivos utilizados. Sua renda não representa cada município.
- **Geografia:** malha IBGE de 2025, com 5.571 municípios; 5.334 têm taxa calculável e 5.330 têm taxa e renda disponíveis.
- **Programas:** o catálogo inicial reúne dois programas e três ofertas documentadas; não é um levantamento completo do Brasil.

Cinza no mapa ou `NULL` significa **dado ausente**, não zero. Renda é um indicador indireto de qualidade de vida, e as comparações não comprovam relações causais.

## Estrutura e documentação

| Local | Conteúdo |
|---|---|
| `Python/` | Servidor Flask, carga de dados e testes. |
| `Oracle/` | Estrutura do banco, cargas, consultas e objetos PL/SQL. |
| `CSV/` e `INSERT/` | Arquivos de origem dos dados. |
| `templates/` e `static/` | HTML, JavaScript, CSS, Leaflet e mapas GeoJSON. |
| `iniciar.py` | Prepara o ambiente Python e inicia a aplicação. |

- [Guia do banco Oracle](Oracle/README.md): instalação, atualização e consultas.
- [MER e modelo relacional](Oracle/MODELAGEM_MER.md): tabelas, chaves e cardinalidades.
- [Diagrama editável](Oracle/diagramas/MODELAGEM_MER.drawio): versão para diagrams.net.
- [Dicionário de dados](Oracle/DICIONARIO_DADOS.md): finalidade das tabelas e dos objetos.
- [Cálculos exibidos no HTML](CALCULOS_HTML.md): fórmulas, exemplos, consultas e origem de cada indicador.
- [Guia PL/SQL](Oracle/PLSQL.md): regras de negócio, demonstrações e testes no Oracle.

## Problemas comuns e verificações

| Problema | O que conferir |
|---|---|
| “Banco de dados indisponível” | Oracle ligado e conexão correta no `.env`. |
| “Renda por escolaridade” não carrega após atualização | Como `MAPA_IDOSOS`, execute `Oracle/13a_catalogos_pnad.sql` e depois `Oracle/06_visoes.sql` (com as funções já criadas); reinicie o Flask. |
| Mapa não aparece | Arquivos em `static/malhas/` e conexão com a API. |
| Gemini não responde | Chave, acesso ao modelo, conexão e cota no Google AI Studio. |

Para conferir o banco, execute `Oracle/07_validacao.sql` no SQL Developer. Os testes da pesquisa abaixo funcionam sem Oracle ativo nem chamadas pagas ao Gemini; Node.js é necessário para o teste JavaScript:

```powershell
.venv\Scripts\python.exe -m unittest discover -s Python -p test_pesquisa.py -v
node --test tests/test_app.cjs
```

No Linux/macOS, use `.venv/bin/python` no lugar do executável Windows.
