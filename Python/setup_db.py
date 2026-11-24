"""Cria uma vez os usuários e tabelas do projeto no Oracle XE local."""

import os
import secrets
import string
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
DSN = "localhost:1521/XEPDB1"


def password():
    alphabet = string.ascii_letters + string.digits
    return "A" + "".join(secrets.choice(alphabet) for _ in range(27))


def sqlplus(script, connection):
    result = subprocess.run(["sqlplus", "-L", "-s", connection], input=script,
                            text=True, encoding="utf-8", env=dict(os.environ, NLS_LANG=".AL32UTF8"),
                            cwd=ROOT, capture_output=True)
    if result.returncode or "ORA-" in result.stdout or "SP2-" in result.stdout:
        raise RuntimeError(result.stdout[-1500:] or result.stderr[-1500:])


def main():
    if (ROOT / ".env").exists() or (ROOT / ".owner.env").exists():
        raise SystemExit("Configuração já existe; não recrie usuários sobre os dados atuais.")
    owner_password, reader_password = password(), password()
    sqlplus(f"""WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION SET CONTAINER=XEPDB1;
CREATE USER MAPA_IDOSOS IDENTIFIED BY \"{owner_password}\";
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE TRIGGER, CREATE SEQUENCE TO MAPA_IDOSOS;
ALTER USER MAPA_IDOSOS QUOTA UNLIMITED ON USERS;
CREATE USER MAPA_IDOSOS_RO IDENTIFIED BY \"{reader_password}\";
GRANT CREATE SESSION TO MAPA_IDOSOS_RO;
EXIT
""", "/ as sysdba")
    (ROOT / ".owner.env").write_text(
        f"ORACLE_USER=MAPA_IDOSOS\nORACLE_PASSWORD={owner_password}\nORACLE_DSN={DSN}\n", encoding="utf-8")
    (ROOT / ".env").write_text(
        f"ORACLE_USER=MAPA_IDOSOS_RO\nORACLE_PASSWORD={reader_password}\nORACLE_DSN={DSN}\n", encoding="utf-8")
    sqlplus(f"""WHENEVER SQLERROR EXIT SQL.SQLCODE
@banco_base.sql
@schema_indicadores.sql
@Oracle/13_estrutura_programas.sql
@Oracle/14_funcoes.sql
@Oracle/15_procedures.sql
@Oracle/16_triggers.sql
@Oracle/06_visoes.sql
@Oracle/18_validacao_plsql.sql
@Oracle/08_permissoes_leitura.sql
EXIT
""", f"MAPA_IDOSOS/{owner_password}@{DSN}")
    print("Oracle preparado em XEPDB1; Python/load_data.py carrega indicadores e programas reais. Credenciais locais gravadas em .env e .owner.env.")


if __name__ == "__main__":
    main()
