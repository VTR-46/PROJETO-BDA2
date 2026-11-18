"""Página e API de indicadores municipais de idosos."""

import os
from pathlib import Path

import oracledb
from dotenv import load_dotenv
from flask import Flask, jsonify, render_template, request
from werkzeug.exceptions import BadRequest, HTTPException, NotFound

from gemini import pesquisar, validar_pedido
from load_data import PNAD_LABELS, UF


ROOT = Path(__file__).resolve().parent.parent
load_dotenv(ROOT / ".env")
app = Flask(__name__, template_folder=str(ROOT / "templates"), static_folder=str(ROOT / "static"))
app.config["MAX_CONTENT_LENGTH"] = 512 * 1024
UF_BY_SIGLA = {sigla: code for code, (sigla, _) in UF.items()}
if not all(os.getenv(name) for name in ("ORACLE_USER", "ORACLE_PASSWORD", "ORACLE_DSN")):
    raise SystemExit("Configure ORACLE_USER, ORACLE_PASSWORD e ORACLE_DSN no ambiente ou em .env. "
                     "Use .env.example como modelo; veja o roteiro de instalação no README.md.")
try:
    pool = oracledb.create_pool(
        user=os.environ["ORACLE_USER"],
        password=os.environ["ORACLE_PASSWORD"],
        dsn=os.environ["ORACLE_DSN"],
        min=1, max=4, increment=1,
    )
except oracledb.Error:
    raise SystemExit("Não foi possível conectar ao Oracle. Confira o serviço, a rede e "
                     "ORACLE_USER, ORACLE_PASSWORD e ORACLE_DSN em .env.") from None


def query(sql, params=None):
    with pool.acquire() as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql, params or {})
            return cursor.fetchall()


def number(value):
    return float(value) if value is not None else None


def municipio_json(row, sigla):
    code, name, total_a, nao_a, total_e, baixa_e, renda = row
    return {"id_municipio": int(code), "nome": name, "uf": sigla,
            "total_alfabetizacao": int(total_a) if total_a is not None else None,
            "nao_alfabetizados": int(nao_a) if nao_a is not None else None,
            "taxa_analfabetismo": number(round(100 * nao_a / total_a, 2))
            if total_a and nao_a is not None else None,
            "total_escolaridade": int(total_e) if total_e is not None else None,
            "baixa_escolaridade": int(baixa_e) if baixa_e is not None else None,
            "percentual_baixa_escolaridade": number(round(100 * baixa_e / total_e, 2))
            if total_e and baixa_e is not None else None,
            "renda_media": number(renda)}


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
    return jsonify([municipio_json(row, sigla) for row in rows])


@app.post("/api/municipios/<int:codigo>/pesquisa")
def pesquisa_municipio(codigo):
    try:
        if not 1000000 <= codigo <= 9999999:
            raise BadRequest("Informe um código IBGE de sete dígitos.")
        pergunta, historico = validar_pedido(request.get_json(silent=True))
        rows = query("""SELECT m.id_municipio,m.nome,i.total_alfabetizacao,i.nao_alfabetizados,
                    i.total_escolaridade,i.baixa_escolaridade,i.renda_media,m.id_uf
                    FROM mapa_idosos.tab_municipio m LEFT JOIN mapa_idosos.tab_indicador_municipio i
                    ON i.id_municipio=m.id_municipio WHERE m.id_municipio=:codigo""", {"codigo": codigo})
        if not rows:
            raise NotFound("Município não encontrado.")
        city = municipio_json(rows[0][:-1], UF[int(rows[0][-1])][0])
        result = pesquisar(city, pergunta, historico)
        result["municipio"] = {key: city[key] for key in ("id_municipio", "nome", "uf")}
        result["indicadores"] = {key: value for key, value in city.items()
                                 if key not in result["municipio"]}
        return jsonify(result)
    except HTTPException as error:
        response = jsonify({"erro": error.description})
        if error.code == 429 and error.retry_after is not None:
            response.headers["Retry-After"] = str(error.retry_after)
        return response, error.code


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
