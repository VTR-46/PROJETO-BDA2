"""Gera o recorte municipal completo da alfabetização no Censo 2022."""

import csv
import gzip
import json
import os
import tempfile
import urllib.parse
import urllib.request
from pathlib import Path

from load_data import geography


ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "CSV" / "censo_alfabetizacao_tratado_municipios_2022.csv"
AGES = [(6613, "60 anos"), (6614, "61 anos"), (6615, "62 anos"),
        (6616, "63 anos"), (6617, "64 anos"), (3000, "65 anos ou mais")]
CATEGORIES = [(93024, "Total"), (1024, "Não alfabetizadas")]
URL = "https://servicodados.ibge.gov.br/api/v3/agregados/9542/periodos/2022/variaveis/950"


def fetch():
    params = urllib.parse.urlencode({
        "localidades": "N6[all]",
        "classificacao": "59[93024,1024]|2[6794]|86[95251]|287[6613,6614,6615,6616,6617,3000]",
    })
    request = urllib.request.Request(f"{URL}?{params}", headers={"User-Agent": "MapaIdosos/1.0"})
    with urllib.request.urlopen(request, timeout=120) as response:
        body = response.read()
        if response.headers.get("Content-Encoding") == "gzip" or body.startswith(b"\x1f\x8b"):
            body = gzip.decompress(body)
        return json.loads(body)


def build_rows(payload):
    if len(payload) != 1 or str(payload[0]["id"]) != "950":
        raise ValueError("Resposta inesperada da tabela 9542.")
    by_code = {str(code): (name, sigla) for (sigla, _), (code, name, _) in geography().items()}
    values = {}
    for result in payload[0]["resultados"]:
        categories = {str(item["id"]): str(next(iter(item["categoria"])))
                      for item in result["classificacoes"]}
        if (categories.get("2"), categories.get("86")) != ("6794", "95251"):
            raise ValueError("A consulta não retornou sexo e raça Total.")
        category, age = int(categories["59"]), int(categories["287"])
        if category not in dict(CATEGORIES) or age not in dict(AGES):
            raise ValueError((category, age))
        for series in result["series"]:
            code = str(series["localidade"]["id"])
            value = series["serie"].get("2022")
            if code not in by_code or (value != "-" and (value is None or not value.isdigit())):
                raise ValueError((code, value))
            cell = (code, age, category)
            if cell in values:
                raise ValueError(f"Célula duplicada: {cell}")
            values[cell] = "" if value == "-" else value
    codes = {code for code, _, _ in values}
    if len(codes) != 5570 or len(values) != 5570 * len(AGES) * len(CATEGORIES):
        raise ValueError(f"Cobertura incompleta: {len(codes)} municípios, {len(values)} células")
    for code in sorted(codes):
        name, sigla = by_code[code]
        for age_id, age in AGES:
            for category_id, category in CATEGORIES:
                yield [f"{name} ({sigla})", "Total", age, "Total", category,
                       values[(code, age_id, category_id)]]


def main():
    print("Consultando a tabela 9542 do IBGE…", flush=True)
    payload = fetch()
    rows = list(build_rows(payload))
    with tempfile.NamedTemporaryFile("w", encoding="utf-8-sig", newline="", suffix=".csv",
                                     dir=OUTPUT.parent, delete=False) as temporary:
        temp_path = Path(temporary.name)
        writer = csv.writer(temporary)
        writer.writerow(["localizacao", "cor_ou_raca", "grupo_de_idade", "sexo", "alfabetizacao", "qtd_idosos"])
        writer.writerows(rows)
    os.replace(temp_path, OUTPUT)
    print(f"Gerado {OUTPUT.name}: {len(rows)} linhas, 5.570 municípios; '-' salvo como campo vazio.")


if __name__ == "__main__":
    main()
