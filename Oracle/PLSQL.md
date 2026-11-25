# PL/SQL e programas de alfabetização

O módulo acrescenta três tabelas às seis existentes. Programas e municípios têm
relação N:M por `tab_municipio_programa`, com uma observação documental por ano.
O cadastro não representa matrícula individual, adesão formal ou atendimento
exclusivo de idosos. A operação é pelo SQL Developer; a aplicação permanece de leitura.

## Instalar no banco existente

1. Consulte a conexão em `.owner.env`, sem divulgar a senha. Neste ambiente, a PDB
   é `FREEPDB1`, com conexão `localhost:1539/FREEPDB1`. Conectado como SYS nessa PDB, execute `00_permissoes_plsql.sql` com F5.
   Ele acrescenta CREATE PROCEDURE, CREATE TRIGGER e CREATE SEQUENCE (necessário
   às colunas identity). Não cria usuários nem altera senhas.
2. Como `MAPA_IDOSOS`, execute `roteiros/00_incremento_plsql.sql` com F5. Ele cria a estrutura
   complementar, compila os sete objetos, atualiza views, carrega as fontes reais e
   concede leitura das novas views. Não recarrega os indicadores históricos.
3. Confira `18_validacao_plsql.sql` e reinicie o Flask se já estava aberto.

Não execute `06_visoes.sql` sozinho: ele depende de `FN_PERCENTUAL` e das tabelas
criadas na etapa 1. Se ele já foi executado isoladamente, execute novamente
`roteiros/00_incremento_plsql.sql` na ordem completa; o roteiro usa `CREATE OR REPLACE`.

Não execute o instalador incremental no meio de outra transação: DDL no Oracle
confirma transações implicitamente. A migração é repetível, mas não é uma transação
única reversível. Em falha, corrija a causa e execute novamente. Não há DROP de dados.
As views só são substituídas depois de compilar funções e triggers.

Para banco novo, o roteiro `roteiros/00_instalacao_completa.sql` inclui o módulo depois da
carga geográfica e dos indicadores. A alternativa Python continua sendo
`setup_db.py` e depois `load_data.py`; a carga Python lê os SQLs de origem diretamente
do ZIP quando não foram extraídos e inclui o bloco de programas na mesma transação.
O preparo Python cria objetos, mas a validação completa requer a carga posterior.

## Interfaces

Os scripts `14_funcoes.sql`, `15_procedures.sql` e `16_triggers.sql` são a fonte das
assinaturas. Os parâmetros numéricos são NUMBER e as datas são DATE, sem conversão
implícita de texto. Use `DATE '2025-02-12'` nos exemplos SQL.

| Objeto | Uso |
|---|---|
| `fn_percentual(parte,total)` | Percentual com duas casas; NULL se faltar dado ou o denominador for zero. |
| `fn_validar_indicadores(total_a,nao_a,total_e,baixa_e,renda)` | Retorna 1 ou rejeita contagens/ausências/renda inconsistentes. |
| `pr_salvar_programa(...)` | Cadastra ou atualiza metadados pelo código único e devolve o ID. Bloqueia alteração de abrangência/UF se houver oferta. |
| `pr_registrar_oferta(...)` | Inclui ou retifica município/programa/ano. Inserção exige versão esperada NULL; retificação exige versão atual e justificativa. |
| `pr_atualizar_indicadores(...)` | Substitui integralmente os valores municipais existentes, verificando a versão; devolve a nova versão. |
| `trg_indicador_auditoria` | Valida DML direto, controla versão e grava valores anteriores/novos em JSON, usuário e instante. |
| `trg_oferta_validacao` | Valida abrangência estadual e identidade histórica; controla a versão da oferta. |

Não há COMMIT nas procedures ou no bloco de fontes. O chamador decide COMMIT/ROLLBACK;
os instaladores confirmam a carga explicitamente. Em erro, as procedures revertem
somente até seu próprio savepoint. Os triggers não usam transação autônoma.
Atualização sem mudança mantém a versão e não cria log de indicador.

As correções de oferta preservam a última justificativa e fonte; este módulo não
mantém histórico completo das ofertas. A auditoria detalhada cobre os indicadores.
Usuários donos continuam capazes de DDL/DML direto: os contratos de concorrência
e mudança de abrangência pressupõem operação pelas procedures. Não foram criados
novos usuários operacionais ou roles nesta entrega.

| Erro | Significado |
|---|---|
| -20001 / -20002 | Percentual / indicadores inválidos. |
| -20003 / -20004 | Registro inexistente / cadastro concorrente ou duplicado. |
| -20005 | Versão desatualizada ou ausência da versão exigida. Releia antes de tentar. |
| -20006 / -20007 | Metadados inválidos / tentativa de mudar abrangência histórica. |
| -20008 / -20009 | Alteração de identidade / município fora da UF do programa. |
| -20010 / -20011 | Compilação inválida / divergência da carga com retificação existente. |

Constraints continuam produzindo erros Oracle próprios (por exemplo ORA-02290 para
contagem negativa). Erros inesperados são propagados, nunca ocultados.

## Fontes reais e limitações

Recorte consultado em **24/11/2026**, reproduzido em `17_programas_reais.sql`:

- [FNDE — PBA](https://www.gov.br/fnde/pt-br/acesso-a-informacao/acoes-e-programas/programas/programas_suplementares/eja/pba): programa nacional para jovens, adultos e idosos.
- [Seduc-MT — Mais MT Muxirum](https://www5.sefaz.mt.gov.br/web/seduc/w/munic%C3%ADpios-participantes-do-programa-mais-mt-muxirum-devem-indicar-coordenadores-locais-e-selecionar-alfabetizadores): programa estadual que inclui idosos.
- [Barra do Garças, publicação de 09/05/2025](https://educacao.barradogarcas.mt.gov.br/Imprensa/Noticias/Secretaria-municipal-de-educacao-celebra-inicio-das-aulas-dos-programas-mais-mt-muxirum-e-brasil-alfabetizado-205/): documenta os dois programas. As 43 turmas são conjuntas, por isso não são atribuídas a cada programa.
- [Ananindeua, publicação de 12/02/2025](https://www.ananindeua.pa.gov.br/secdh/noticia/8608/programa-brasil-alfabetizado-em-ananindeua-o-conhecimento-e-um-direito-para-todos): documenta 13 turmas do PBA em 2025.

São dois programas e três associações reais. Quantidade de participantes totais e
60+ permanece NULL. Ausência de outro município neste pequeno recorte não significa
ausência de programa. Repetir a carga preserva metadados existentes e não sobrescreve
retificações: divergências nas ofertas interrompem o bloco com -20011.

`vw_programas_municipio` cruza oferta documentada com indicadores: ano do programa
e Censo 2022 aparecem separados. Renda/escolaridade continuam sem ano documentado.
Não há cálculo de cobertura de idosos, eficácia ou redução causal do analfabetismo.
As APIs existentes preservam seus campos JSON e passam a consultar somente views.

## Demonstração e testes

Execute `19_demonstracao_plsql.sql` como dono, com F5. Demonstra retificação,
auditoria, conflito de versão e rollback; não confirma dados de demonstração.

Os testes de escrita em `Python/test_plsql.py` exigem um esquema **isolado** com
nome `MAPA_TEST_*`, instalado com os scripts principais, sem executar o arquivo
de GRANTs destinado à conta web real. Defina `PLSQL_TEST_USER`,
`PLSQL_TEST_PASSWORD` e `PLSQL_TEST_DSN` somente no processo de testes, depois execute:

```powershell
python -m unittest discover -s Python -p test_plsql.py -v
```

Sem essas variáveis, os testes são explicitamente ignorados. Nunca aponte-os ao
esquema do projeto: um teste de concorrência confirma uma fixture exclusiva,
removendo-a ao final. Os demais testes usam rollback. As fixtures são sintéticas
e não integram a carga documental.

Os cenários incluem funções, metadados, criação/retificação de oferta, DML direto,
abrangência estadual, versões, auditoria INSERT/UPDATE/DELETE, rollback, ausência
de COMMIT e atualização concorrente por duas sessões. Execute também a suíte
Python existente e `node --test tests/test_app.cjs`.
