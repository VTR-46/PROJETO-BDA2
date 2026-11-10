"""Página e API de indicadores municipais de idosos."""

import os
from pathlib import Path

import oracledb
from dotenv import load_dotenv
from flask import Flask, jsonify, render_template, request

from load_data import PNAD_LABELS, UF


ROOT = Path(__file__).resolve().parent.parent
load_dotenv(ROOT / ".env")
app = Flask(__name__, template_folder=str(ROOT / "templates"), static_folder=str(ROOT / "static"))
UF_BY_SIGLA = {sigla: code for code, (sigla, _) in UF.items()}
pool = oracledb.create_pool(
    user=os.environ["ORACLE_USER"],
    password=os.environ["ORACLE_PASSWORD"],
    dsn=os.environ["ORACLE_DSN"],
    min=1, max=4, increment=1,
)


def query(sql, params=None):
    with pool.acquire() as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql, params or {})
            return cursor.fetchall()


def number(value):
    return float(value) if value is not None else None


@app.get("/")
def index():
    return render_template("index.html")


@app.get("/api/ufs")
def ufs():
    rows = query("""SELECT u.id_uf,u.nome,COUNT(m.id_municipio),
                COUNT(CASE WHEN i.total_alfabetizacao IS NOT NULL THEN 1 END),
                iu.total_alfabetizacao,iu.nao_alfabetizados
                FROM mapa_idosos.tab_uf u JOIN mapa_idosos.tab_municipio m ON m.id_uf=u.id_uf
                LEFT JOIN mapa_idosos.tab_indicador_municipio i ON i.id_municipio=m.id_municipio
                LEFT JOIN mapa_idosos.tab_indicador_uf iu ON iu.id_uf=u.id_uf
                GROUP BY u.id_uf,u.nome,iu.total_alfabetizacao,iu.nao_alfabetizados ORDER BY u.nome""")
    return jsonify([{"id_uf": int(code), "sigla": UF[int(code)][0], "nome": name,
                     "municipios": int(total), "com_taxa": int(available),
                     "total_alfabetizacao": int(total_a) if total_a is not None else None,
                     "nao_alfabetizados": int(nao_a) if nao_a is not None else None,
                     "taxa_analfabetismo": number(round(100 * nao_a / total_a, 2))
                     if total_a and nao_a is not None else None}
                    for code, name, total, available, total_a, nao_a in rows])


@app.get("/api/municipios")
def municipios():
    sigla = request.args.get("uf", "").upper()
    if sigla not in UF_BY_SIGLA:
        return jsonify({"erro": "Informe uma sigla de UF válida."}), 400
    rows = query("""SELECT m.id_municipio,m.nome,i.total_alfabetizacao,i.nao_alfabetizados,
                i.total_escolaridade,i.baixa_escolaridade,i.renda_media
                FROM mapa_idosos.tab_municipio m LEFT JOIN mapa_idosos.tab_indicador_municipio i
                ON i.id_municipio=m.id_municipio
                WHERE m.id_uf=:uf ORDER BY m.nome""", {"uf": UF_BY_SIGLA[sigla]})
    return jsonify([{"id_municipio": int(code), "nome": name, "uf": sigla,
                     "total_alfabetizacao": int(total_a) if total_a is not None else None,
                     "nao_alfabetizados": int(nao_a) if nao_a is not None else None,
                     "taxa_analfabetismo": number(round(100 * nao_a / total_a, 2))
                     if total_a and nao_a is not None else None,
                     "total_escolaridade": int(total_e) if total_e is not None else None,
                     "baixa_escolaridade": int(baixa_e) if baixa_e is not None else None,
                     "percentual_baixa_escolaridade": number(round(100 * baixa_e / total_e, 2))
                     if total_e and baixa_e is not None else None,
                     "renda_media": number(renda)}
                    for code, name, total_a, nao_a, total_e, baixa_e, renda in rows])


@app.get("/api/pnad-escolaridade")
def pnad():
    rows = query("""SELECT nivel_instrucao,total_amostra,amostra_com_renda,renda_media
                FROM mapa_idosos.tab_pnad_resumo ORDER BY nivel_instrucao""")
    return jsonify([{"nivel": int(level), "escolaridade": PNAD_LABELS[int(level)],
                     "total_amostra": int(total), "amostra_com_renda": int(with_income),
                     "renda_media": number(income)}
                    for level, total, with_income, income in rows])


@app.get("/api/catalogo-municipios")
def catalogo_municipios():
    rows = query("""SELECT m.id_municipio,m.nome,m.id_uf
                FROM mapa_idosos.tab_municipio m ORDER BY m.nome,m.id_uf""")
    return jsonify([{"id_municipio": int(code), "nome": name, "uf": UF[int(uf)][0]}
                    for code, name, uf in rows])


@app.errorhandler(oracledb.Error)
def oracle_error(error):
    app.logger.error("Falha na consulta Oracle: %s", error)
    return jsonify({"erro": "Banco de dados indisponível."}), 503


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000)
