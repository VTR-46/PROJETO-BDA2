# Scripts para Oracle SQL Developer

Esta pasta contém a estrutura, os dados consolidados e consultas do projeto em SQL Oracle. Os arquivos de carga usam `MERGE`: executar novamente atualiza os registros por código IBGE, sem duplicá-los ou apagar outras linhas.

## Banco já criado neste computador

1. No SQL Developer, crie ou abra uma conexão com **usuário `MAPA_IDOSOS`**, host `localhost`, porta `1521` e serviço `XEPDB1`. A senha está no arquivo local `.owner.env` da pasta principal; não a copie para um script ou repositório.
2. Abra `00_atualizar_dados.sql` e execute com **F5 (Executar Script)**. O comando `@@` abre os demais arquivos desta pasta na ordem correta.
3. Confira o resultado de `07_validacao.sql`: **5.571 municípios**, **5.334 com taxa**, **5.330 com taxa e renda**, **27 UFs com taxa** e **76.492 registros PNAD**.

## Instalação em outro Oracle XE

1. Conecte-se ao serviço `XEPDB1` como `SYS` com papel `SYSDBA`. Execute `00_admin_usuarios.sql` com F5 e informe senhas fortes quando solicitado. A conta `MAPA_IDOSOS_RO` terá apenas acesso de leitura.
2. Crie uma conexão `MAPA_IDOSOS` com a senha escolhida. Abra `00_instalacao_completa.sql` e execute com F5. Ele cria as tabelas, carrega os dados, cria as views, valida a cobertura e concede leitura.
3. Para a página local funcionar com esse novo banco, configure `.env` com `ORACLE_USER=MAPA_IDOSOS_RO`, a senha de leitura e `ORACLE_DSN=localhost:1521/XEPDB1`. O servidor Flask continua necessário para exibir o mapa no navegador.

Execute o roteiro de instalação apenas em um esquema vazio; no banco existente, use o roteiro de atualização. O SQL Developer executa toda a parte **Oracle** do projeto. HTML, Leaflet, malhas GeoJSON e a API Flask não rodam dentro do SQL Developer.

## Conteúdo dos arquivos

| Arquivo | O que faz |
| --- | --- |
| `01_estrutura.sql` | Cria 6 tabelas, chaves e índices. Parte das 3 tabelas de `banco_base.sql`. |
| `01a_indicador_uf_migracao.sql` | Cria a tabela estadual no banco existente, se ainda não existir. |
| `02_regioes_ufs.sql` | Carrega 5 regiões e 27 UFs. |
| `03_municipios.sql` | Carrega 5.571 municípios e seus códigos IBGE da DTB 2025. |
| `04_indicadores_municipais.sql` | Carrega os contadores de alfabetização, escolaridade e renda média. |
| `04a_indicadores_ufs.sql` | Carrega os totais oficiais das 27 UFs por `MERGE`. |
| `05_pnad_resumo.sql` | Carrega o resumo nacional da PNAD por nível de instrução. |
| `06_visoes.sql` | Cria views com os percentuais e nomes para consulta. |
| `07_validacao.sql` | Verifica totais, lacunas e exemplos de análise. |
| `08_permissoes_leitura.sql` | Concede `SELECT` à conta usada pela página. |
| `09_consulta_analfabetismo.sql` | Mostra a taxa e as contagens de alfabetização de um município. |
| `10_consulta_renda_nominal_media.sql` | Mostra a renda média mensal de um município. |
| `11_consulta_baixa_escolaridade.sql` | Mostra a taxa e as contagens de baixa escolaridade de um município. |
| `12_consulta_codigos_municipios.sql` | Encontra o código IBGE pelo nome do município e mostra o estado. |

## Consultar os mesmos indicadores da página

Os arquivos `09`, `10` e `11` são **apenas consultas**: não alteram o banco e não fazem parte dos roteiros de instalação. Abra cada um no SQL Developer e execute com **F5**, conectado como `MAPA_IDOSOS` ou `MAPA_IDOSOS_RO`. Todos usam São Paulo (código IBGE `3550308`) como exemplo. Para ver outra cidade, substitua esse número no `WHERE id_municipio = 3550308`.

Para descobrir o código, abra `12_consulta_codigos_municipios.sql`, troque `Campinas` pelo nome procurado e execute com **F5**. A coluna `ESTADO` distingue municípios que tenham o mesmo nome. Copie o valor de `CODIGO_IBGE` para um dos scripts de indicadores.

As consultas leem `MAPA_IDOSOS.vw_mapa_idosos`, que reúne os indicadores municipais exibidos no painel da página. Um resultado `NULL` corresponde a **“Sem dados”** na página. Os percentuais já vêm calculados com duas casas decimais; a renda está em reais por mês.

A alfabetização vem da [Tabela 9542 do Censo 2022 do IBGE](https://servicodados.ibge.gov.br/api/v3/agregados/9542/metadados). A renda e a escolaridade vêm de `CSV/censo_idosos_consolidado.csv`; a PNAD vem dos `INSERTs` já existentes. A taxa municipal é `100 × não alfabetizados / total` para 60 anos ou mais. Valores `NULL` significam que alguma célula necessária não estava disponível; não são zeros. Dos 5.570 municípios do Censo, 236 não têm taxa calculável. Boa Esperança do Norte (MT) consta na malha 2025, mas não no Censo 2022.

A taxa estadual usa as 12 células de cada UF no `CSV/censo_alfabetizacao_tratado.csv`: `Total` e `Não alfabetizadas` nas seis faixas de idade, com sexo e raça `Total`. Ela não é calculada pela soma dos municípios disponíveis. O roteiro de atualização cria a tabela estadual antes de carregar esses dados e pode ser executado novamente.
