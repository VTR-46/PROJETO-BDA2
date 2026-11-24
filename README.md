# Mapa do analfabetismo de idosos no Brasil

## Módulo PL/SQL e programas de alfabetização

O projeto inclui 3 procedures, 2 functions, 2 triggers e 3 tabelas adicionais de
programas, ofertas municipais e auditoria. Veja a [instalação incremental, fontes
oficiais e demonstração](Oracle/PLSQL.md). No banco existente, prepare as permissões
com `Oracle/00_permissoes_plsql.sql` e execute `Oracle/roteiros/00_incremento_plsql.sql` como
dono; esse roteiro não recarrega os indicadores do Censo.

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

## Executar em outra máquina

1. Instale **Python 3.10 ou superior**, com `pip` e `venv` (no Windows, habilite Python no `PATH`; no Linux, pode ser necessário instalar o pacote `python3-venv`).
2. Clone o repositório ou copie a pasta do projeto, **sem `.venv`, `.env` e `.owner.env`**. O ambiente Python precisa ser criado em cada máquina; as senhas são configuradas separadamente.
3. Tenha acesso a um Oracle já preparado, local ou remoto. Para um banco novo, siga o [roteiro do SQL Developer](Oracle/README.md): os scripts SQL já incluem os dados consolidados. Esse preparo é feito uma vez por banco, não por computador.
4. Copie `.env.example` para `.env` e preencha a senha de leitura. Em `ORACLE_DSN`, use `HOST:PORTA/SERVICO`, por exemplo `192.168.1.10:1521/XEPDB1` para um banco remoto. O servidor Oracle precisa permitir a conexão dessa máquina.
5. Na pasta principal, execute:

   ```sh
   python iniciar.py
   ```

   No Linux/macOS, use `python3 iniciar.py` se o comando disponível for `python3`.

Abra <http://127.0.0.1:5000>. O iniciador cria `.venv`, instala as dependências e inicia o Flask, sem precisar ativar o ambiente manualmente. Nas próximas execuções, reutiliza o ambiente e só reinstala dependências se `requirements.txt` mudar. A primeira instalação exige internet. Para encerrar, pressione `Ctrl+C`.

**Para apenas executar o mapa**, não é preciso instalar Node.js, SQL Developer, SQL*Plus ou Oracle Client nessa máquina: o driver Python conecta diretamente ao Oracle. Node.js só é necessário para reconstruir as malhas; SQL Developer ou SQL*Plus são usados no preparo do banco. Os mapas e dados SQL já acompanham o repositório. A chave Gemini é opcional; o mapa funciona sem ela.

Se optar pelo preparo local com `Python/setup_db.py`, execute-o **antes de criar `.env`**: ele gera as duas configurações e recusa sobrescrever arquivos existentes. Para cargas Python em um banco preparado por SQL Developer, use `.owner.env.example` como modelo de `.owner.env` e informe a senha do dono do esquema.

O iniciador mantém o servidor acessível somente no próprio computador. Ele não instala nem copia o Oracle e não altera os dados do banco. Se `.venv` estiver danificado ou tiver sido copiado de outra máquina, remova apenas essa pasta e execute novamente. Para testar o iniciador sem instalar pacotes nem acessar o banco:

```sh
python -m unittest discover -s Python -p test_iniciar.py -v
```

## Abrir a página neste computador

O Oracle XE local já está preparado em `XEPDB1`, e os dados e malhas já foram carregados. Abra o PowerShell **na pasta principal do projeto**:

```powershell
python iniciar.py
```

Abra <http://127.0.0.1:5000>. Para encerrar o servidor, pressione `Ctrl+C` no terminal. A conexão de leitura está em `.env`.

No mapa, a cor de cada UF mostra sua taxa estadual. Clique numa UF ou escolha-a na lista para carregar os municípios. A busca funciona desde o mapa do Brasil: digite um nome, escolha uma sugestão com a UF ou pressione Enter sobre um nome completo. A página abre a UF e o município encontrados. **Ver Brasil** retorna ao mapa estadual e mantém a busca disponível. Cinza significa **sem taxa calculável**, não taxa zero. O balão da UF informa sua taxa e a cobertura municipal.

## Pesquisar um município com Gemini

Acrescente à configuração `.env` na raiz (ou às variáveis de ambiente do servidor):

```dotenv
GEMINI_API_KEY=SUA_CHAVE_DO_GOOGLE_AI_STUDIO
GEMINI_MODEL=gemini-3.5-flash-lite
GEMINI_GOOGLE_SEARCH=0
```

Obtenha sua chave no [Google AI Studio](https://aistudio.google.com/apikey) e reinicie o Flask. `GEMINI_MODEL` e `GEMINI_GOOGLE_SEARCH` são opcionais. Por padrão (`GEMINI_GOOGLE_SEARCH=0`), o servidor coleta gratuitamente o contexto territorial e histórico em APIs públicas (IBGE Localidades, IBGE Cidades@, SIDRA Censo 2022 e Wikipédia em português) e envia ao Gemini sem exigir a ferramenta paga `google_search`, funcionando imediatamente no plano gratuito. Se o seu projeto tiver faturamento ativo para *Grounding with Google Search*, defina `GEMINI_GOOGLE_SEARCH=1` (se a cota de busca retornar `429`, o servidor faz fallback automático para o modo público). A chave fica no servidor: não a coloque no JavaScript, em capturas de tela nem no Git. Nenhuma dependência adicional é necessária.

Selecione um município pelo mapa, pela busca ou pelo gráfico e clique em **Pesquisar município com Gemini**. O relatório aparece abaixo do mapa, com contexto histórico e atual, relações possíveis com analfabetismo, renda e escolaridade dos idosos, fontes e limitações. Depois, use **Enviar pergunta** para aprofundar a análise. Os links acompanham os trechos que sustentam; respostas sem citações recebem um aviso explícito.

O servidor consulta os números diretamente no Oracle antes de cada envio. A IA recebe apenas identificação municipal, indicadores agregados e conversa; nunca recebe credenciais nem acesso para executar SQL. Os números utilizados e a data da pesquisa aparecem em cada resposta. Fatos recentes não explicam automaticamente o Censo 2022, o ano da renda e escolaridade permanece desconhecido, e hipóteses não comprovam causas.

Relatórios e perguntas ficam separados por código IBGE, somente na memória da aba. Voltar a um município reaproveita sua conversa; recarregar ou fechar a aba apaga os resultados. Cada pergunta envia o relatório inicial e até cinco trocas anteriores, com até 1.000 caracteres por pergunta. A chamada usa `store=false`, sem histórico de interações persistido pela aplicação ou encadeamento no servidor do Gemini; o processamento do Google segue seus próprios termos.

Cada clique de pesquisa ou envio de pergunta faz uma chamada, com busca habilitada e timeout de 60 segundos, sem repetição automática. Consultas podem consumir cota e gerar cobrança: veja a [documentação de busca e preços](https://aistudio.google.com/docs/google-search#pricing). Se faltar chave, rede, acesso ao modelo ou cota, o painel informa o problema e permite nova tentativa; o mapa continua funcionando.

**Erro 429 ao pesquisar:** confira as [cotas do projeto no Google AI Studio](https://aistudio.google.com/rate-limit). O limite pode ser temporário, diário ou corresponder a um recurso indisponível no seu plano. A busca na web pela API do `gemini-3.5-flash-lite` não está disponível no plano gratuito, conforme a [tabela de preços do modelo](https://aistudio.google.com/docs/pricing#gemini-3.5-flash-lite), embora uma chamada de texto sem busca possa funcionar. Nesse caso, aguardar ou gerar outra chave do mesmo projeto não libera a busca: é necessário habilitar o acesso e o faturamento adequados no projeto, sujeito a cobrança. A aplicação preserva o `Retry-After` informado em segundos pelo Google e explica a espera na mensagem, sem repetir a chamada automaticamente.

## Preparar outro Oracle XE

Há duas formas de instalar o banco. **Escolha uma**; não execute ambas no mesmo esquema.

### Pelo Oracle SQL Developer

Siga o [roteiro da pasta Oracle](Oracle/README.md). Resumidamente: execute `Oracle/00_admin_usuarios.sql` como `SYS` no serviço `XEPDB1`; depois execute `Oracle/roteiros/00_instalacao_completa.sql` como `MAPA_IDOSOS`, usando **F5**. Configure `.env` na raiz:

```dotenv
ORACLE_USER=MAPA_IDOSOS_RO
ORACLE_PASSWORD=SUA_SENHA_DE_LEITURA
ORACLE_DSN=localhost:1521/XEPDB1
```

Instale as dependências e execute `python Python/app.py`. Para atualizar um banco existente, use `Oracle/roteiros/00_atualizar_dados.sql` como `MAPA_IDOSOS`.

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
| `POST /api/municipios/<codigo>/pesquisa` | Relatório ou resposta do Gemini com indicadores do Oracle e fontes. |

A pesquisa aceita `{}` para gerar o relatório ou `{"pergunta":"...","historico":[{"role":"assistant","content":"relatório inicial"}]}` para perguntar. O histórico começa com o relatório (`assistant`), seguido de até cinco pares `user`/`assistant`. Responde com `municipio`, `indicadores`, `resposta`, `fontes` (`titulo`, `url`, `trecho`), `sugestoes_busca` (HTML do Google, isolado em iframe com sandbox) e `gerado_em` (UTC). Erros usam `{"erro":"..."}`: 400 entrada inválida, 404 município inexistente, 413 corpo acima de 512 KiB, 429 cota, 502 falha do provedor/rede, 503 configuração/Oracle e 504 timeout.

O Flask usa a conta `MAPA_IDOSOS_RO`. Não compartilhe `.env` nem `.owner.env`, que contêm senhas.

## Verificação e limites

Os testes da pesquisa funcionam sem Oracle ativo, sem chave Gemini e sem consumir cota:

```powershell
python -m unittest discover -s Python -p test_pesquisa.py -v
node --test tests/test_app.cjs
```

Para a suíte completa, o Oracle e os arquivos locais de dados precisam estar disponíveis. Se faltarem os SQLs geográficos ou da PNAD em `INSERT/`, extraia os respectivos arquivos de `INSERT/Inserts.zip` nessa pasta.

```powershell
python -m unittest discover -s Python -p 'test_*.py'
```

São esperados **27 UFs com taxa**, **5.571 municípios na malha**, **5.334 com taxa**, **5.330 com taxa e renda** e **76.492 registros da PNAD**. Dos 5.570 municípios do Censo 2022, 236 têm pelo menos um valor necessário ausente e aparecem em cinza. Boa Esperança do Norte (MT) aparece na malha de 2025, mas não no Censo 2022.

Renda é apenas um indicador indireto de qualidade de vida. O ano dos indicadores de renda e escolaridade não está documentado nos arquivos disponíveis. A PNAD não permite estimar renda municipal nem concluir uma relação causal neste projeto.

Se a página mostrar **“Banco de dados indisponível”**, confira se o Oracle XE está ligado e se `.env` aponta para a conta de leitura e o serviço corretos. Se faltar a malha, confira `static/malhas/`. Para validar as tabelas, execute `Oracle/07_validacao.sql` no SQL Developer.
