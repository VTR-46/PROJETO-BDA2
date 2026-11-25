> Perfis de acesso: prepare `20a_roles_admin.sql` como SYS em XEPDB1 antes dos roteiros automaticos; eles terminam executando `20_roles_seguranca.sql`. Na instalacao manual, execute o 20 depois dos objetos e dados. Consulte [SEGURANCA.md](SEGURANCA.md).

# Banco Oracle — guia para começar

Este banco guarda os dados do projeto **Mapa do analfabetismo de idosos no Brasil**: regiões, estados, municípios, indicadores de educação e renda e ofertas documentadas de programas de alfabetização.

Esta pasta contém os scripts que criam o banco, carregam os dados e permitem consultá-los pelo **Oracle SQL Developer**.

## 1. Como o banco se conecta à página

```text
Scripts desta pasta → banco Oracle → servidor Python/Flask → página HTML
```

O Oracle guarda os dados. O SQL Developer é a ferramenta usada para executar os scripts. O servidor Python consulta o Oracle e entrega os resultados para os mapas e gráficos da página.

O SQL Developer não abre a página HTML. Para isso, também é necessário iniciar o servidor Python, como explicado no [README principal](../README.md).

## 2. Qual arquivo devo executar?

Escolha o roteiro conforme a situação. Os três ficam na pasta [roteiros](roteiros/).

| Situação | Arquivo |
|---|---|
| Vou instalar em um esquema novo e vazio. | [00_instalacao_completa.sql](roteiros/00_instalacao_completa.sql) |
| O banco já existe e quero recarregar os dados distribuídos com o projeto. | [00_atualizar_dados.sql](roteiros/00_atualizar_dados.sql) |
| O banco já existe e quero atualizar funções, procedures, triggers e os catálogos da PNAD. | [00_incremento_plsql.sql](roteiros/00_incremento_plsql.sql) |

**Execute o roteiro escolhido com F5 — Executar Script.** Ele chama os outros arquivos na ordem necessária. Os números dos arquivos individuais não indicam, sozinhos, a ordem completa de instalação.

Mantenha a pasta `Oracle` inteira, incluindo `roteiros`. As linhas `@@../` dos roteiros procuram os scripts na pasta acima.

O roteiro de instalação completa cria tabelas e deve ser usado apenas em esquema vazio. O de atualização recarrega valores por chave e pode substituir correções manuais nos indicadores. O de incremento atualiza a estrutura complementar e os programas documentados, sem recarregar os indicadores do Censo.

Antes de executar, confirme ou desfaça trabalhos pendentes na conexão. Comandos que criam ou alteram estruturas confirmam transações automaticamente no Oracle.

## 3. Primeira instalação no SQL Developer

Você precisa de um Oracle em execução e do SQL Developer para acessá-lo. Os exemplos abaixo usam Oracle XE local com serviço `XEPDB1`.

### Passo 1 — Criar os usuários

Crie uma conexão administrativa com estas configurações:

| Campo | Valor no exemplo local |
|---|---|
| Usuário | `SYS` |
| Atribuição/papel | `SYSDBA` |
| Host | `localhost` |
| Porta | `1521` |
| Tipo de identificação | **Nome do Serviço**, não SID |
| Serviço | `XEPDB1` |
| Senha | A senha administrativa escolhida na instalação do Oracle |

Se o banco usar outro computador, porta ou serviço, ajuste esses campos e o destino do script administrativo.

Nessa conexão, abra [00_admin_usuarios.sql](00_admin_usuarios.sql) e pressione **F5**. Informe as senhas solicitadas. Ele cria:

- `MAPA_IDOSOS`: dono das tabelas; instala e atualiza os dados.
- `MAPA_IDOSOS_RO`: usuário de leitura usado pela página.

Ainda como SYS/SYSDBA, execute `20a_roles_admin.sql` para preparar as roles e os usuários adicionais antes do roteiro de instalação. O roteiro do dono termina com o script 20, que configura a MV e as permissões.

Se esses usuários já existem, siga a seção de banco existente abaixo.

### Passo 2 — Criar e preencher o banco

1. Crie outra conexão com o usuário `MAPA_IDOSOS` e a senha escolhida.
2. Use o mesmo host, porta e serviço, com atribuição **padrão**.
3. Teste e abra essa conexão.
4. Abra [00_instalacao_completa.sql](roteiros/00_instalacao_completa.sql).
5. Pressione **F5** e acompanhe a saída até o final.

Esse roteiro cria as tabelas, carrega os dados, cria funções, procedures, triggers e views, apresenta verificações e concede leitura à conta da página.

### Passo 3 — Conectar a página

Na raiz do projeto, configure o arquivo `.env`:

```dotenv
ORACLE_USER=MAPA_IDOSOS_RO
ORACLE_PASSWORD=SUA_SENHA_DE_LEITURA
ORACLE_DSN=localhost:1521/XEPDB1
```

Depois, na pasta principal do projeto, execute:

```powershell
python iniciar.py
```

Abra <http://127.0.0.1:5000>. As senhas são locais e não devem ser incluídas na entrega ou no repositório.

## 4. Se o banco já está instalado

1. Conecte-se como `MAPA_IDOSOS`.
2. Escolha o roteiro de atualização de dados ou de incremento explicado na seção 2.
3. Execute com **F5** e confira a saída.
4. Reinicie o servidor Python se ele já estava aberto.

Em uma instalação antiga sem permissão para criar objetos PL/SQL, execute primeiro [00_permissoes_plsql.sql](00_permissoes_plsql.sql) como `SYS`, na PDB do projeto — o banco identificado pelo serviço `XEPDB1` neste exemplo. Depois volte à conexão `MAPA_IDOSOS` para executar o roteiro.

## 5. Quais tabelas existem?

O esquema completo tem **11 tabelas: 3 do esquema base e 8 adicionais**.

| Tabela | O que guarda |
|---|---|
| `TAB_REGIAO` | As regiões brasileiras. |
| `TAB_UF` | Os estados e o Distrito Federal, ligados às regiões. |
| `TAB_MUNICIPIO` | Os municípios e seus códigos IBGE, ligados às UFs. |
| `TAB_INDICADOR_MUNICIPIO` | Alfabetização, escolaridade e renda dos idosos por município. |
| `TAB_INDICADOR_UF` | Totais oficiais de alfabetização dos idosos por UF. |
| `TAB_PNAD_RESUMO` | Quantidade de registros e renda média por escolaridade na amostra nacional. |
| `TAB_NIVEL_INSTRUCAO` | Os nomes dos sete níveis de instrução da PNAD. |
| `TAB_FONTE_DADO` | A descrição e o arquivo de origem da amostra PNAD usada no projeto. |
| `TAB_PROGRAMA` | O cadastro dos programas de alfabetização. |
| `TAB_MUNICIPIO_PROGRAMA` | As ofertas documentadas por município, programa e ano. |
| `TAB_AUDITORIA_INDICADOR` | O histórico de alterações dos indicadores municipais. |

As seis primeiras tabelas são criadas em [01_estrutura.sql](01_estrutura.sql). Programas, ofertas e auditoria são criados em [13_estrutura_programas.sql](13_estrutura_programas.sql). Os dois catálogos da PNAD são criados em [13a_catalogos_pnad.sql](13a_catalogos_pnad.sql).

## 6. O que são views, functions, procedures e triggers?

| Objeto | Significado | Uso neste projeto |
|---|---|---|
| View | Uma consulta salva. | Junta tabelas e mostra indicadores para a página. |
| Function | Recebe valores e devolve um resultado. | Calcula percentuais ou valida indicadores. |
| Procedure | Executa uma operação. | Salva programas, registra ofertas ou atualiza indicadores. |
| Trigger | Executa automaticamente quando dados mudam. | Confere ofertas e registra alterações dos indicadores. |

As views estão em `06_visoes.sql`, as duas functions em `14_funcoes.sql`, as três procedures em `15_procedures.sql` e os dois triggers em `16_triggers.sql`.

Uma **chave primária (PK)** identifica um registro sem repetição. Uma **chave estrangeira (FK)** liga uma tabela a outra: por exemplo, cada município aponta para sua UF.

O [dicionário de dados](DICIONARIO_DADOS.md) explica cada objeto. O [MER e modelo relacional](MODELAGEM_MER.md) mostra as chaves e os relacionamentos.

Para editar o desenho, abra o [arquivo de diagrama .drawio](diagramas/MODELAGEM_MER.drawio) no diagrams.net. As tabelas, os campos e as conexões são editáveis.

## 7. Como conferir os resultados

Execute [07_validacao.sql](07_validacao.sql) como `MAPA_IDOSOS`. Com a carga distribuída, são esperados:

| Verificação | Resultado |
|---|---|
| Regiões / UFs | 5 / 27 |
| Municípios cadastrados | 5.571 |
| Municípios com taxa de analfabetismo calculável | 5.334 |
| Municípios com taxa e renda disponíveis | 5.330 |
| UFs com taxa disponível | 27 |
| Registros representados no resumo PNAD | 76.492 |
| Níveis de instrução / fontes cadastradas inicialmente | 7 / 1 |

O resumo PNAD possui sete linhas, uma por nível de instrução. As 76.492 pessoas da amostra estão representadas pelos totais dessas linhas.

Use [18_validacao_plsql.sql](18_validacao_plsql.sql) para verificar a compilação das funções, procedures e triggers.

Para demonstrar as regras de versão e auditoria, execute [19_demonstracao_plsql.sql](19_demonstracao_plsql.sql) como dono. Ele faz alterações temporárias e as desfaz ao final. Execute essa demonstração em uma conexão sem alterações suas pendentes.

## 8. Como consultar um município

Os arquivos abaixo apenas consultam dados. Abra no SQL Developer e pressione **F5**, conectado como `MAPA_IDOSOS` ou `MAPA_IDOSOS_RO`.

| Arquivo | Consulta |
|---|---|
| [09_consulta_analfabetismo.sql](09_consulta_analfabetismo.sql) | Taxa e contagens de alfabetização. |
| [10_consulta_renda_nominal_media.sql](10_consulta_renda_nominal_media.sql) | Renda média mensal. |
| [11_consulta_baixa_escolaridade.sql](11_consulta_baixa_escolaridade.sql) | Percentual e contagens de baixa escolaridade. |
| [12_consulta_codigos_municipios.sql](12_consulta_codigos_municipios.sql) | Código IBGE pelo nome do município. |

As três consultas de indicadores usam São Paulo (`3550308`) como exemplo. Troque o código no `WHERE` para consultar outra cidade. A consulta de códigos usa `Campinas` como exemplo; altere o nome procurado e confira o estado para distinguir cidades com o mesmo nome.

## 9. Como interpretar os dados

- `NULL` significa dado ausente, e não zero. Na página aparece como “Sem dados”.
- A alfabetização vem do Censo 2022, tabela 9542 do IBGE. O ano dos dados municipais de renda e escolaridade não está documentado.
- A renda da PNAD descreve uma amostra nacional sem pesos amostrais nos arquivos utilizados. Ela não representa a renda de cada município.
- A taxa estadual usa os totais oficiais da UF, e não a média das taxas municipais.
- A malha municipal é de 2025. Boa Esperança do Norte (MT) aparece nela, mas não no Censo 2022.
- O catálogo inicial tem dois programas e três ofertas documentadas. Isso não representa todos os programas existentes no Brasil.

Para detalhes das regras, das fontes dos programas e dos testes, consulte o [guia PL/SQL](PLSQL.md). Para executar a aplicação, consulte o [README principal](../README.md).
