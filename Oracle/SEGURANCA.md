# Segurança e view materializada — XEPDB1

Conexão: `localhost:1521/XEPDB1`, usando Nome do Serviço. Os scripts 20a e 20 interrompem em erros. DDL e GRANTs não são uma transação inteiramente reversível; valide primeiro em um Oracle de teste.

## Instalar ou atualizar

1. Os usuários `MAPA_IDOSOS` e `MAPA_IDOSOS_RO` devem existir. Em instalação nova, crie-os com `00_admin_usuarios.sql`.
2. Como SYS/SYSDBA em XEPDB1, execute `20a_roles_admin.sql`. Use senhas com 12 a 30 letras/números, iniciadas por letra, sem aspas ou `&`. Usuários existentes conservam suas senhas. A entrada é administrativa e deve respeitar esse formato.
3. Crie/carregue os objetos e dados. Os roteiros automáticos exigem a etapa 2 previamente e executam o script 20 ao final. Na execução manual, rode `20_roles_seguranca.sql` como `MAPA_IDOSOS` depois das views e da carga.
4. Reconecte os usuários e reinicie o Flask para testar as permissões. O arquivo `08_permissoes_leitura.sql` é uma chamada de compatibilidade ao 20: não concede mais SELECT direto às tabelas.
5. Execute `21_teste_seguranca.sql` separadamente em cada conexão abaixo. O arquivo identifica o usuário e executa somente o ramo correspondente. Use conexão sem alterações pendentes.

Se optar pelo preparo Python, execute `setup_db.py`, depois `load_data.py`, e conclua as etapas administrativas 20a e 20 antes de abrir a página. O preparo Python não concede os acessos antigos.

## Matriz de acesso

| Usuário | Role | Acesso |
|---|---|---|
| MAPA_IDOSOS | Dono | Estrutura, carga, dados e atualização da MV. |
| MAPA_IDOSOS_RO | ROLE_ANALISTA | SELECT nas seis views e na MV; sem tabelas ou procedures. |
| MAPA_OPERADOR | ROLE_OPERACIONAL | SELECT no catálogo municipal, mapa e programas; EXECUTE nas três procedures. |
| MAPA_ADMIN | ROLE_ADMIN_MAPA | SELECT nas tabelas, views e MV; EXECUTE nas três procedures e duas functions. Sem DML direto ou DDL. |

As procedures usam `AUTHID DEFINER`. O operador usa os direitos do dono durante sua execução, sem receber DML nas tabelas. `VW_MAPA_IDOSOS.versao` permite ler a versão necessária à atualização. O administrador funcional também pode alterar os dados pelas procedures autorizadas.

A migração concede os novos acessos antes de revogar os grants diretos antigos da conta web. Grants ou roles extras de instalações preexistentes devem ser revisados; o teste acusa inconsistências sem removê-las silenciosamente.

## MV_RESUMO_UF

É criada somente quando ausente. Reexecuções preservam a MV e não atualizam seus dados. Se a definição existente for diferente da prevista, o script interrompe com `-20021`; planeje uma migração explícita em vez de apagar o objeto automaticamente.

Armazena uma linha por UF com região, número de municípios, cobertura de taxa e renda, somas de alfabetização, taxa agregada municipal e média simples das rendas municipais disponíveis. Não representa a taxa estadual oficial nem renda estadual ponderada.

Após confirmar alterações/cargas, o dono executa, em uma conexão sem trabalho pendente:

```sql
EXEC DBMS_MVIEW.REFRESH('MV_RESUMO_UF', 'C');
```

Não há atualização automática após procedures ou cargas Python. A MV é para consulta no SQL Developer, sem nova seção HTML.

## Conferir

O script 21 verifica leitura permitida, recusas de SELECT/DML e chamada de procedure pelo operador com leitura da versão atual e ROLLBACK. Não execute DROP de tabelas para demonstrar uma recusa. O resultado esperado em cada conexão é `OK` para seu perfil.

Para investigar permissões extras, consulte `SESSION_ROLES` e `SESSION_PRIVS` na conexão afetada. Como dono, consulte `USER_TAB_PRIVS_MADE`; como SYS, confira `DBA_ROLE_PRIVS`, `DBA_SYS_PRIVS` e `DBA_TAB_PRIVS`, incluindo privilégios herdados e concedidos a PUBLIC. Nunca conceda privilégios gerais de tabela para contornar uma falha no teste.
