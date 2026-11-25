# Cálculos e consultas exibidos no HTML

Este documento explica de onde vêm os números da página, como são calculados e quais consultas os fornecem. Os exemplos numéricos abaixo são **fictícios**, apenas para demonstrar as contas.

## 1. Caminho dos dados

```text
Arquivos CSV e INSERTs → cálculo na carga Python → tabelas Oracle
Tabelas Oracle → views → SELECT na API Flask → números e gráficos no HTML
```

Os totais e as rendas médias são preparados pela carga e armazenados no banco. As views organizam os dados e calculam percentuais. A API também calcula os percentuais municipais e estaduais a partir das contagens que consulta. O JavaScript formata os valores e desenha os gráficos.

| Parte da página | Rota consultada | View utilizada |
|---|---|---|
| Mapa nacional e quantidade de municípios com taxa | `GET /api/ufs` | `VW_COBERTURA_UF` |
| Busca por nome | `GET /api/catalogo-municipios` | `VW_CATALOGO_MUNICIPIOS` |
| Municípios da UF e painel do município | `GET /api/municipios?uf=SP` | `VW_MAPA_IDOSOS` |
| Gráfico Renda e analfabetismo | Os mesmos dados de municípios da UF | `VW_MAPA_IDOSOS` |
| Gráfico Renda por escolaridade | `GET /api/pnad-escolaridade` | `VW_PNAD_ESCOLARIDADE` |
| Tabela de programas | `GET /api/programas-municipio` | `VW_PROGRAMAS_MUNICIPIO` |
| Pesquisa com Gemini | `POST /api/municipios/<codigo>/pesquisa` | `VW_MAPA_IDOSOS` |

Os `SELECTs` estão em [Python/app.py](Python/app.py). A função `query()` executa cada consulta no Oracle. Ao carregar uma UF, a API devolve todos os seus municípios. O clique em um município usa os dados já recebidos; somente a pesquisa com Gemini faz uma nova consulta municipal antes do envio à IA.

## 2. Taxa de analfabetismo do município

Exibida pela cor no mapa, no painel do município e no eixo vertical do gráfico de dispersão.

```text
Taxa de analfabetismo (%) = 100 × não alfabetizados / total de pessoas no recorte
```

No banco:

```text
100 × nao_alfabetizados / total_alfabetizacao
```

**Atenção ao nome da coluna:** `total_alfabetizacao` é o total de pessoas consideradas no recorte de alfabetização, incluindo alfabetizadas e não alfabetizadas. Não é somente o número de alfabetizadas.

Na carga, são somadas as idades **60, 61, 62, 63, 64 e 65 anos ou mais** do arquivo `CSV/censo_alfabetizacao_tratado_municipios_2022.csv`. São utilizadas as categorias “Total” e “Não alfabetizadas”, com sexo e cor ou raça iguais a “Total”, para não contar a mesma população várias vezes.

Exemplo: 200 pessoas não alfabetizadas em um total de 1.000:

```text
100 × 200 / 1.000 = 20%
```

Se faltar qualquer uma das células necessárias, a carga não utiliza uma soma parcial para a taxa municipal. Ela mantém as contagens de alfabetização ausentes. O total deve ser positivo e a quantidade não alfabetizada deve estar entre zero e o total.

A função `municipios()` consulta:

```sql
SELECT id_municipio, municipio,
       total_alfabetizacao, nao_alfabetizados,
       total_escolaridade, baixa_escolaridade, renda_media
FROM mapa_idosos.vw_mapa_idosos
WHERE id_uf = :uf
ORDER BY municipio;
```

`:uf` recebe o código do estado, por exemplo, 35 para São Paulo. A função `municipio_json()` calcula o percentual e o arredonda para duas casas.

## 3. Taxa de analfabetismo da UF

A fórmula é a mesma, mas usa os **totais oficiais da própria UF**, guardados em `TAB_INDICADOR_UF`:

```text
Taxa estadual (%) = 100 × não alfabetizados da UF / total da UF
```

Essas contagens vêm do arquivo `CSV/censo_alfabetizacao_tratado.csv`, com as mesmas seis idades e os filtros sexo/cor ou raça “Total”.

Exemplo: 15.000 não alfabetizados em 100.000 pessoas no recorte:

```text
100 × 15.000 / 100.000 = 15%
```

A taxa não é a média simples das taxas municipais. Também não é calculada somando apenas os municípios disponíveis, pois alguns têm dados ausentes.

Consulta da função `ufs()`:

```sql
SELECT id_uf, nome, municipios, com_taxa,
       total_alfabetizacao, nao_alfabetizados
FROM mapa_idosos.vw_cobertura_uf
ORDER BY nome;
```

O balão da UF mostra essa taxa e a quantidade de municípios com dados.

### Cores do mapa

| Taxa já arredondada recebida pela página | Cor |
|---|---|
| Até 10%, inclusive | Verde claro |
| Maior que 10% e até 20% | Verde |
| Maior que 20% e até 30% | Laranja |
| Maior que 30% | Vermelho |
| Taxa ausente | Cinza |

## 4. Quantidade de municípios com taxa disponível

O número no topo da página é uma **contagem de municípios**, não uma média nem uma porcentagem.

Na view `VW_COBERTURA_UF`:

```sql
COUNT(m.id_municipio) AS municipios,
COUNT(CASE WHEN i.total_alfabetizacao IS NOT NULL THEN 1 END) AS com_taxa
```

O JavaScript soma `com_taxa` das UFs. Na carga distribuída, o resultado esperado é **5.334**. Essa contagem considera que os indicadores carregados e validados possuem as contagens necessárias quando `total_alfabetizacao` está preenchido.

Ao carregar uma UF, o aviso do mapa conta os registros retornados com `taxa_analfabetismo` não nula e mostra “X de Y municípios com taxa disponível”.

Existem 5.571 municípios cadastrados na malha de 2025. Dos 5.570 municípios do Censo 2022, 236 não têm todas as células necessárias; Boa Esperança do Norte (MT), da malha de 2025, também não possui esse indicador do Censo.

## 5. Percentual de baixa escolaridade

No painel municipal, o rótulo é **“Sem instrução ou fundamental incompleto”**.

```text
Baixa escolaridade (%) = 100 × baixa_escolaridade / total_escolaridade
```

As contagens vêm de `CSV/censo_idosos_consolidado.csv`, somando as faixas **60 a 64 anos** e **65 anos ou mais**, com sexo e cor ou raça iguais a “Total”.

- `total_escolaridade`: soma da quantidade de idosos na categoria de instrução “Total”.
- `baixa_escolaridade`: soma da categoria “Sem instrução e fundamental incompleto”.

Exemplo: 700 pessoas nessa categoria em um total de 1.000:

```text
100 × 700 / 1.000 = 70%
```

Baixa escolaridade e analfabetismo são indicadores diferentes. Uma pessoa pode ter ensino fundamental incompleto e saber ler e escrever.

Na carga, se faltar o total de alguma faixa, o total consolidado fica ausente. Se faltar a contagem de baixa escolaridade, o percentual fica ausente. O ano desses dados não está documentado no arquivo do projeto.

## 6. Renda nominal média municipal

É a **média ponderada das rendas** das duas faixas disponíveis no mesmo CSV: 60–64 e 65 anos ou mais. O peso é a quantidade de idosos na categoria de instrução “Total” de cada faixa.

```text
Renda média = (N60–64 × R60–64 + N65+ × R65+) / (N60–64 + N65+)
```

`N` é a população da faixa e `R` é a renda nominal média mensal informada para ela.

Exemplo:

| Faixa | Quantidade | Renda média |
|---|---:|---:|
| 60–64 | 400 | R$ 2.000,00 |
| 65+ | 600 | R$ 1.500,00 |

```text
(400 × 2.000 + 600 × 1.500) / (400 + 600) = R$ 1.700,00
```

A carga arredonda o resultado para centavos com `Decimal` e `ROUND_HALF_UP`. Se faltar população ou renda necessária de uma das faixas, não calcula uma média parcial. A página lê a renda consolidada do banco e apenas a formata em reais.

Esse número não é a renda total do município nem a renda por escolaridade da PNAD. Seu ano de referência não está documentado.

## 7. Gráfico “Renda e analfabetismo”

Cada ponto representa um município da UF selecionada que tem **renda e taxa de analfabetismo disponíveis ao mesmo tempo**.

- Eixo horizontal: `renda_media`, em reais por mês.
- Eixo vertical: `taxa_analfabetismo`, em porcentagem.
- Legenda abaixo: quantidade de municípios com os dois indicadores.

Não é feita outra média para formar os pontos. A função `drawScatter()` usa os registros já recebidos de `/api/municipios` e elimina aqueles com um dos dois valores nulo. Valor zero válido continua sendo um dado disponível.

O JavaScript ajusta a escala para caberem os pontos: o limite horizontal é a maior renda multiplicada por 1,05; o vertical é a maior taxa elevada ao próximo múltiplo de 10, com mínimo de 10%. Isso muda apenas o desenho dos eixos, não os valores consultados.

O gráfico é descritivo: não apresenta uma medida de causalidade, regressão ou coeficiente de correlação. A consulta `CORR` existente no script de validação não é exibida nesse gráfico.

## 8. Gráfico “Renda por escolaridade”

Utiliza os registros de idosos do arquivo `tab_pnad_idosos_INSERT.sql`, disponível em `INSERT/` ou no ZIP distribuído. A carga agrupa os registros pelos sete níveis de instrução.

Para cada nível:

```text
total_amostra = quantidade de todos os registros do nível
amostra_com_renda = quantidade dos registros do nível com renda não NULL
renda_media = soma das rendas informadas / amostra_com_renda
```

Exemplo: um nível tem rendas de R$ 1.000, R$ 2.000 e um registro sem renda:

```text
total_amostra = 3
amostra_com_renda = 2
renda_media = (1.000 + 2.000) / 2 = R$ 1.500,00
```

Um registro sem renda não entra no denominador da média, mas permanece em `total_amostra`. Uma renda informada como zero entra na média. Se ninguém informar renda, a média fica NULL.

A média é arredondada a centavos na carga, sem pesos amostrais. O resumo fica em `TAB_PNAD_RESUMO`.

Consulta da API:

```sql
SELECT nivel_instrucao, escolaridade,
       total_amostra, amostra_com_renda, renda_media,
       fonte, ano_fonte, fonte_url
FROM mapa_idosos.vw_pnad_escolaridade
ORDER BY nivel_instrucao;
```

A view obtém os nomes dos níveis em `TAB_NIVEL_INSTRUCAO` e a fonte em `TAB_FONTE_DADO`. Os dois catálogos descrevem os dados; não alteram a fórmula da renda média.

O tamanho visual de cada barra é:

```text
Largura da barra (%) = 100 × renda média do nível / maior renda média dos níveis
```

A maior renda ocupa 100% da largura. Isso **não significa participação na renda total**. Renda zero ou ausente não produz largura positiva; o texto distingue “R$ 0,00” de “Sem dados”.

O rodapé soma `amostra_com_renda` e `total_amostra` dos níveis. O total esperado da amostra é 76.492. Ano e URL da fonte aparecem somente quando documentados; atualmente ambos podem ser nulos.

## 9. Programas de alfabetização para idosos

A tabela consulta `VW_PROGRAMAS_MUNICIPIO`. Essa view junta o cadastro do programa, a oferta municipal e a view de indicadores municipais.

Os campos exibidos — ano, turmas, participantes, participantes 60+, data e fonte — são **valores cadastrados a partir das publicações**, não resultados de uma fórmula estatística.

A contagem exibida funciona assim:

```text
X de Y ofertas documentadas
X = número de linhas que atendem aos filtros atuais
Y = número de linhas recebidas da API
```

Por exemplo, “3 de 3” significa três ofertas registradas e visíveis. Não significa que existam apenas três programas no Brasil. Um mesmo programa pode gerar várias ofertas por município e ano.

Os filtros de programa, UF, ano e município são combinados no navegador. A ordenação troca a posição das linhas e não modifica as quantidades.

O “Ano do indicador” é 2022, referente à alfabetização; “Ano da oferta” vem da publicação cadastrada. Quantidades ausentes aparecem como “Não informado”. Não são calculados taxa de atendimento dos idosos, eficácia do programa ou impacto no analfabetismo.

## 10. Busca de municípios e pesquisa com Gemini

**Busca:** consulta código IBGE, nome e UF em `VW_CATALOGO_MUNICIPIOS`. O navegador compara o texto digitado aos nomes, ignorando diferenças de maiúsculas/minúsculas e acentos. Não há cálculo estatístico.

**Gemini:** antes de cada pedido de pesquisa, a API faz um `SELECT` em `VW_MAPA_IDOSOS` com `WHERE id_municipio = :codigo`. Usa `municipio_json()` para os mesmos percentuais e renda descritos acima e envia esse conjunto à IA.

Os valores mostrados no registro da pesquisa são o retrato dessa consulta, acompanhado da data/hora da geração. O texto produzido pelo Gemini é uma interpretação com fontes e hipóteses; não constitui um novo indicador oficial nem comprova causalidade.

## 11. Arredondamento e dados ausentes

- Os percentuais nas views usam `FN_PERCENTUAL(parte,total)`: `ROUND(100 * parte / total, 2)`. A função retorna NULL para entradas ausentes ou total zero, e rejeita contagens negativas ou parte maior que total.
- A API municipal e estadual calcula a mesma razão a partir das contagens, usando `round(..., 2)` em Python. As regras de desempate do arredondamento Python e do Oracle não são idênticas; em valores exatamente no meio entre centésimos, pode haver diferença de 0,01 entre uma consulta à view e o valor recalculado pela API.
- O navegador usa formatação brasileira: vírgula decimal, separador de milhares e reais para renda. Os percentuais têm até duas casas; as rendas são exibidas com duas.
- `NULL` do banco vira `null` no JSON e, nos indicadores, “Sem dados” no HTML. Ausência não é substituída por zero.

## 12. Arquivos responsáveis

| Arquivo | Responsabilidade |
|---|---|
| [Python/load_data.py](Python/load_data.py) | Soma as populações, calcula renda ponderada municipal e médias da PNAD. |
| [Oracle/04_indicadores_municipais.sql](Oracle/04_indicadores_municipais.sql) | Carga SQL dos valores municipais consolidados. |
| [Oracle/04a_indicadores_ufs.sql](Oracle/04a_indicadores_ufs.sql) | Carga SQL dos totais estaduais oficiais. |
| [Oracle/05_pnad_resumo.sql](Oracle/05_pnad_resumo.sql) | Carga SQL do resumo por nível de instrução. |
| [Oracle/06_visoes.sql](Oracle/06_visoes.sql) | Relaciona tabelas e fornece as views para consulta. |
| [Oracle/14_funcoes.sql](Oracle/14_funcoes.sql) | Contém `FN_PERCENTUAL` e a validação dos indicadores. |
| [Python/app.py](Python/app.py) | Executa os SELECTs e monta as respostas da API. |
| [static/app.js](static/app.js) | Mostra indicadores, desenha gráficos e aplica filtros e contagens. |
| [templates/index.html](templates/index.html) | Define onde cada resultado aparece na página. |

Para executar o projeto, veja o [README principal](README.md). Para consultar diretamente pelo SQL Developer, veja o [guia Oracle](Oracle/README.md).
