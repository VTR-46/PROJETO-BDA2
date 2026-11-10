# Mapa do analfabetismo de idosos no Brasil

Esta página local mostra a **taxa de analfabetismo de pessoas com 60 anos ou mais** em estados e municípios. Ao escolher um município, também aparecem renda média e baixa escolaridade. Dois gráficos comparam renda e analfabetismo municipal e mostram renda por escolaridade na amostra nacional da PNAD.

## Como funciona

```text
CSV, INSERTs e códigos geográficos → cálculo em Python → Oracle XE
                                      Oracle XE → API Flask → mapa Leaflet no navegador
```

O Oracle guarda indicadores resumidos. O Flask consulta o banco usando uma conta de leitura e entrega JSON à página. O Leaflet desenha os mapas com os GeoJSON já preparados. O SQL Developer executa a parte Oracle; o Flask continua necessário para abrir a página.

## Estrutura do projeto

| Caminho | Conteúdo |
| --- | --- |
| `Python/` | Servidor, carga, preparação de arquivos e testes. |
| `Oracle/` | Scripts SQL para instalação, atualização e validação. Veja o [guia do SQL Developer](Oracle/README.md). |
| `CSV/` | Fontes do Censo usadas nos cálculos. |
| `INSERT/` | Códigos geográficos e registros da PNAD. |
| `static/` | JavaScript, CSS, Leaflet e malhas GeoJSON. |
| `templates/` | Página HTML. |
| `banco_base.sql` | Esquema inicial. |
| `schema_indicadores.sql` | Tabelas adicionais para a instalação via Python. |
| `.env` e `.owner.env` | Conexões locais de leitura e carga. São ignoradas pelo Git. |

## Abrir a página neste computador

O Oracle XE local já está preparado em `XEPDB1`, e os dados e malhas já foram carregados. Abra o PowerShell **na pasta principal do projeto**:

```powershell
python -m pip install -r requirements.txt
python Python/app.py
```

Abra <http://127.0.0.1:5000>. Para encerrar o servidor, pressione `Ctrl+C` no terminal. A conexão de leitura está em `.env`.

No mapa, a cor de cada UF mostra sua taxa estadual. Clique numa UF ou escolha-a na lista para carregar os municípios. A busca funciona desde o mapa do Brasil: digite um nome, escolha uma sugestão com a UF ou pressione Enter sobre um nome completo. A página abre a UF e o município encontrados. **Ver Brasil** retorna ao mapa estadual e mantém a busca disponível. Cinza significa **sem taxa calculável**, não taxa zero. O balão da UF informa sua taxa e a cobertura municipal.

## Preparar outro Oracle XE

Há duas formas de instalar o banco. **Escolha uma**; não execute ambas no mesmo esquema.

### Pelo Oracle SQL Developer

Siga o [roteiro da pasta Oracle](Oracle/README.md). Resumidamente: execute `Oracle/00_admin_usuarios.sql` como `SYS` no serviço `XEPDB1`; depois execute `Oracle/00_instalacao_completa.sql` como `MAPA_IDOSOS`, usando **F5**. Configure `.env` na raiz:

```dotenv
ORACLE_USER=MAPA_IDOSOS_RO
ORACLE_PASSWORD=SUA_SENHA_DE_LEITURA
ORACLE_DSN=localhost:1521/XEPDB1
```

Instale as dependências e execute `python Python/app.py`. Para atualizar um banco existente, use `Oracle/00_atualizar_dados.sql` como `MAPA_IDOSOS`.

### Pelos scripts Python

Requer Oracle XE local, `sqlplus` disponível e autenticação local `/ as sysdba`. Para recriar a malha, também requer Node.js com `npx` e internet.

```powershell
python -m pip install -r requirements.txt
python Python/setup_db.py
python Python/fetch_alfabetizacao.py
python Python/load_data.py
python Python/build_geo.py
python -m unittest discover -s Python -p test_project.py
python Python/app.py
```

Execute `setup_db.py` **uma vez, em uma instalação nova**. Ele cria `MAPA_IDOSOS` (dono dos dados) e `MAPA_IDOSOS_RO` (somente leitura), executa `banco_base.sql` e `schema_indicadores.sql` e grava `.owner.env` e `.env` na raiz. As cargas podem ser repetidas. Se os CSVs e malhas já existem, não é necessário baixá-los novamente. Para verificar as fontes sem gravar no Oracle:

```powershell
python Python/load_data.py --check
```

## Scripts Python

| Script | O que faz |
| --- | --- |
| `Python/app.py` | Inicia Flask e a página na porta 5000. |
| `Python/setup_db.py` | Cria usuários, tabelas e permissões no Oracle local. |
| `Python/fetch_alfabetizacao.py` | Consulta a tabela 9542 do IBGE e gera o CSV municipal completo. |
| `Python/load_data.py` | Valida fontes, calcula indicadores e os carrega por `MERGE`. |
| `Python/build_geo.py` | Baixa e simplifica a malha de 2025; cria GeoJSON por UF. |
| `Python/test_project.py` | Verifica dados, geografia e API. |

## De onde vêm os indicadores

- **Taxa municipal:** [Tabela 9542 do Censo 2022 do IBGE](https://servicodados.ibge.gov.br/api/v3/agregados/9542/metadados), no `CSV/censo_alfabetizacao_tratado_municipios_2022.csv`. Soma **Total** e **Não alfabetizadas** nas idades 60, 61, 62, 63, 64 e 65 anos ou mais, com sexo e raça `Total`. Taxa = `100 × não alfabetizados ÷ total`.
- **Taxa estadual:** a mesma conta, usando as 12 células de cada UF em `CSV/censo_alfabetizacao_tratado.csv`. É calculada diretamente pelos totais estaduais, pois há municípios sem dados. Não é a média das taxas municipais.
- **Baixa escolaridade:** proporção de idosos **sem instrução ou com fundamental incompleto** nas faixas 60 a 64 e 65 anos ou mais de `CSV/censo_idosos_consolidado.csv`.
- **Renda municipal:** média das rendas dessas duas faixas, ponderada pelo número de idosos de cada faixa. Os `INSERTs` antigos do censo de idosos não entram nesses cálculos: seus primeiros valores estão em escala diferente do CSV.
- **PNAD:** resumo de `INSERT/tab_pnad_idosos_INSERT.sql`. A renda média considera registros com renda informada. É uma descrição da **amostra nacional**, sem pesos amostrais.
- **Geografia:** os códigos vêm do arquivo em `INSERT/` e as formas vêm da [Malha Municipal Digital 2025 do IBGE](https://www.ibge.gov.br/geociencias/organizacao-do-territorio/malhas-territoriais/15774-malhas.html).

## Banco e API

`tab_regiao`, `tab_uf` e `tab_municipio` formam a hierarquia geográfica. `tab_indicador_uf` e `tab_indicador_municipio` guardam os indicadores; `tab_pnad_resumo` guarda o resumo nacional. As views `vw_taxa_uf`, `vw_mapa_idosos` e `vw_pnad_escolaridade` facilitam consultas no SQL Developer.

| Endereço | Resposta |
| --- | --- |
| `/api/ufs` | 27 UFs, contagens, taxa estadual e cobertura municipal. |
| `/api/catalogo-municipios` | Código IBGE, nome e UF dos municípios para a busca nacional. |
| `/api/municipios?uf=SP` | Indicadores dos municípios da UF. |
| `/api/pnad-escolaridade` | Renda média e tamanho da amostra por escolaridade. |

O Flask usa a conta `MAPA_IDOSOS_RO`. Não compartilhe `.env` nem `.owner.env`, que contêm senhas.

## Verificação e limites

```powershell
python -m unittest discover -s Python -p test_project.py
```

São esperados **27 UFs com taxa**, **5.571 municípios na malha**, **5.334 com taxa**, **5.330 com taxa e renda** e **76.492 registros da PNAD**. Dos 5.570 municípios do Censo 2022, 236 têm pelo menos um valor necessário ausente e aparecem em cinza. Boa Esperança do Norte (MT) aparece na malha de 2025, mas não no Censo 2022.

Renda é apenas um indicador indireto de qualidade de vida. O ano dos indicadores de renda e escolaridade não está documentado nos arquivos disponíveis. A PNAD não permite estimar renda municipal nem concluir uma relação causal neste projeto.

Se a página mostrar **“Banco de dados indisponível”**, confira se o Oracle XE está ligado e se `.env` aponta para a conta de leitura e o serviço corretos. Se faltar a malha, confira `static/malhas/`. Para validar as tabelas, execute `Oracle/07_validacao.sql` no SQL Developer.
