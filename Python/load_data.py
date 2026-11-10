"""Valida os arquivos do projeto e carrega os resumos no Oracle."""

import csv
import os
import re
import sys
import unicodedata
from collections import defaultdict
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
UF = {
    11: ("RO", "Rondônia"), 12: ("AC", "Acre"), 13: ("AM", "Amazonas"),
    14: ("RR", "Roraima"), 15: ("PA", "Pará"), 16: ("AP", "Amapá"),
    17: ("TO", "Tocantins"), 21: ("MA", "Maranhão"), 22: ("PI", "Piauí"),
    23: ("CE", "Ceará"), 24: ("RN", "Rio Grande do Norte"),
    25: ("PB", "Paraíba"), 26: ("PE", "Pernambuco"), 27: ("AL", "Alagoas"),
    28: ("SE", "Sergipe"), 29: ("BA", "Bahia"), 31: ("MG", "Minas Gerais"),
    32: ("ES", "Espírito Santo"), 33: ("RJ", "Rio de Janeiro"),
    35: ("SP", "São Paulo"), 41: ("PR", "Paraná"),
    42: ("SC", "Santa Catarina"), 43: ("RS", "Rio Grande do Sul"),
    50: ("MS", "Mato Grosso do Sul"), 51: ("MT", "Mato Grosso"),
    52: ("GO", "Goiás"), 53: ("DF", "Distrito Federal"),
}
REGIONS = {1: "Norte", 2: "Nordeste", 3: "Sudeste", 4: "Sul", 5: "Centro-Oeste"}
AGES_ALPHABET = {"60 anos", "61 anos", "62 anos", "63 anos", "64 anos", "65 anos ou mais"}
AGES_CENSUS = {"60 a 64 anos", "65 anos ou mais"}
PNAD_LABELS = {
    1: "Sem instrução", 2: "Fundamental incompleto", 3: "Fundamental completo",
    4: "Médio incompleto", 5: "Médio completo", 6: "Superior incompleto",
    7: "Superior completo",
}
PLACE = re.compile(r"^(.*) \(([A-Z]{2})\)$")


def key(name):
    return "".join(char for char in unicodedata.normalize("NFKD", name.casefold())
                   if not unicodedata.combining(char))


def number(value):
    return Decimal(value) if value else None


def geography():
    path = next((ROOT / "INSERT").glob("Importar-RELATORIO_DTB_BRASIL_2025_MUNICIPIOS*.sql"))
    municipalities = {}
    with path.open(encoding="utf-8") as source:
        for line in source:
            if not line.startswith("VALUES ("):
                continue
            fields = next(csv.reader([line[8:].strip().removesuffix(");")],
                                     quotechar="'", skipinitialspace=True))
            uf_id, name = int(fields[0]), fields[8]
            assert fields[1] == UF[uf_id][1], (uf_id, fields[1])
            lookup = (UF[uf_id][0], key(name))
            assert lookup not in municipalities, lookup
            municipalities[lookup] = (int(fields[7]), name, uf_id)
    assert len(municipalities) == 5571, len(municipalities)
    return municipalities


def age_rows(filename, category_column, categories, ages):
    result = defaultdict(lambda: defaultdict(dict))
    with (ROOT / "CSV" / filename).open(encoding="utf-8-sig", newline="") as source:
        for row in csv.DictReader(source):
            match = PLACE.fullmatch(row["localizacao"])
            if not match or row["sexo"] != "Total" or row["cor_ou_raca"] != "Total":
                continue
            age, category = row["grupo_de_idade"], row[category_column]
            if age not in ages or category not in categories:
                continue
            result[(match[2], key(match[1]))][age][category] = row
    return result


def alphabet_data():
    data = age_rows("censo_alfabetizacao_tratado_municipios_2022.csv", "alfabetizacao",
                    {"Total", "Não alfabetizadas"}, AGES_ALPHABET)
    result = {}
    for place, ages in data.items():
        if set(ages) != AGES_ALPHABET:
            continue
        pairs = [(number(ages[age].get("Total", {}).get("qtd_idosos")),
                  number(ages[age].get("Não alfabetizadas", {}).get("qtd_idosos")))
                 for age in AGES_ALPHABET]
        if any(total is None or missing is None for total, missing in pairs):
            continue
        total, missing = sum(pair[0] for pair in pairs), sum(pair[1] for pair in pairs)
        if total > 0 and 0 <= missing <= total:
            result[place] = (int(total), int(missing))
    return result, set(data)


def uf_data():
    """Lê os totais estaduais do CSV original, sem depender da cobertura municipal."""
    names = {name: code for code, (_, name) in UF.items()}
    cells = defaultdict(dict)
    with (ROOT / "CSV" / "censo_alfabetizacao_tratado.csv").open(encoding="utf-8-sig", newline="") as source:
        for row in csv.DictReader(source):
            code = names.get(row["localizacao"])
            if code is None or row["sexo"] != "Total" or row["cor_ou_raca"] != "Total":
                continue
            age, category = row["grupo_de_idade"], row["alfabetizacao"]
            if age not in AGES_ALPHABET or category not in {"Total", "Não alfabetizadas"}:
                continue
            cell = (age, category)
            value = number(row["qtd_idosos"])
            if cell in cells[code] or value is None or value != int(value):
                raise ValueError(f"Célula estadual duplicada ou inválida: {code}, {cell}")
            cells[code][cell] = int(value)
    result = []
    for code in UF:
        if len(cells[code]) != 12:
            raise ValueError(f"Faltam células de alfabetização para a UF {code}: {len(cells[code])}/12")
        total = sum(cells[code][age, "Total"] for age in AGES_ALPHABET)
        missing = sum(cells[code][age, "Não alfabetizadas"] for age in AGES_ALPHABET)
        if not total > 0 or not 0 <= missing <= total:
            raise ValueError(f"Contagens estaduais inválidas para a UF {code}")
        result.append((code, total, missing))
    return result


def census_data():
    path = ROOT / "CSV" / "censo_idosos_consolidado.csv"
    result = defaultdict(lambda: defaultdict(dict))
    with path.open(encoding="utf-8-sig", newline="") as source:
        for row in csv.DictReader(source):
            match = PLACE.fullmatch(row["localizacao"])
            if not match or row["sexo"] != "Total" or row["cor_ou_raca"] != "Total":
                continue
            age = row["grupo_de_idade"]
            if age not in AGES_CENSUS:
                continue
            category = row["nivel_de_instrucao"]
            if category == "Total" or category.startswith("Sem instru"):
                result[(match[2], key(match[1]))][age]["total" if category == "Total" else "low"] = row
    combined = {}
    for place, ages in result.items():
        totals = [ages[age].get("total", {}) for age in AGES_CENSUS]
        low = [ages[age].get("low", {}) for age in AGES_CENSUS]
        populations = [number(row.get("quantidade_idosos_por_formacao")) for row in totals]
        lows = [number(row.get("quantidade_idosos_por_formacao")) for row in low]
        incomes = [number(row.get("rendimento_nominal_medio_idosos")) for row in totals]
        population = school = income = None
        if all(value is not None for value in populations) and sum(populations) > 0:
            population = int(sum(populations))
            if all(value is not None for value in lows) and 0 <= sum(lows) <= population:
                school = int(sum(lows))
            if all(value is not None for value in incomes):
                income = (sum(p * r for p, r in zip(populations, incomes)) / population)
                income = income.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        combined[place] = (population, school, income)
    return combined


def pnad_data():
    pattern = re.compile(r"VALUES \((\d+), (\d+), (NULL|\d+)\);")
    totals = defaultdict(lambda: [0, 0, 0])
    with (ROOT / "INSERT" / "tab_pnad_idosos_INSERT.sql").open(encoding="utf-8") as source:
        for line in source:
            match = pattern.fullmatch(line.strip())
            if not match:
                continue
            age, level, income = match.groups()
            assert int(age) >= 60 and int(level) in PNAD_LABELS
            item = totals[int(level)]
            item[0] += 1
            if income != "NULL":
                item[1] += 1
                item[2] += int(income)
    assert sum(item[0] for item in totals.values()) == 76492
    return [(level, item[0], item[1],
             (Decimal(item[2]) / item[1]).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
             if item[1] else None) for level, item in sorted(totals.items())]


def build_data():
    geo = geography()
    alphabet, alphabet_places = alphabet_data()
    census = census_data()
    assert set(census) <= set(geo) and alphabet_places <= set(geo)
    assert len(census) == 5570 and len(alphabet) == 5334
    indicators = []
    for place, (code, _, _) in geo.items():
        total_alphabet, nonliterate = alphabet.get(place, (None, None))
        total_school, low_school, income = census.get(place, (None, None, None))
        indicators.append((code, total_alphabet, nonliterate, total_school, low_school, income))
    both = sum(row[1] is not None and row[5] is not None for row in indicators)
    assert both == 5330, both
    return geo, indicators, pnad_data()


def load():
    import oracledb
    from dotenv import load_dotenv

    load_dotenv(ROOT / ".owner.env")
    geo, indicators, pnad = build_data()
    states = uf_data()
    user, password, dsn = (os.getenv(name) for name in ("ORACLE_USER", "ORACLE_PASSWORD", "ORACLE_DSN"))
    if not all((user, password, dsn)):
        raise SystemExit("Defina ORACLE_USER, ORACLE_PASSWORD e ORACLE_DSN.")
    connection = oracledb.connect(user=user, password=password, dsn=dsn)
    try:
        with connection.cursor() as cursor:
            cursor.executemany("""MERGE INTO tab_regiao t USING (SELECT :1 id, :2 nome FROM dual) s
                ON (t.id_regiao=s.id) WHEN MATCHED THEN UPDATE SET t.nome=s.nome
                WHEN NOT MATCHED THEN INSERT (id_regiao,nome) VALUES (s.id,s.nome)""", list(REGIONS.items()))
            cursor.executemany("""MERGE INTO tab_uf t USING (SELECT :1 id, :2 nome, :3 regiao FROM dual) s
                ON (t.id_uf=s.id) WHEN MATCHED THEN UPDATE SET t.nome=s.nome,t.id_regiao=s.regiao
                WHEN NOT MATCHED THEN INSERT (id_uf,nome,id_regiao) VALUES (s.id,s.nome,s.regiao)""",
                [(code, name, int(str(code)[0])) for code, (_, name) in UF.items()])
            cursor.executemany("""MERGE INTO tab_municipio t USING (SELECT :1 id, :2 nome, :3 uf FROM dual) s
                ON (t.id_municipio=s.id) WHEN MATCHED THEN UPDATE SET t.nome=s.nome,t.id_uf=s.uf
                WHEN NOT MATCHED THEN INSERT (id_municipio,nome,id_uf) VALUES (s.id,s.nome,s.uf)""",
                [row for row in geo.values()])
            cursor.executemany("""MERGE INTO tab_indicador_municipio t USING
                (SELECT :1 id,:2 total_a,:3 nao_a,:4 total_e,:5 baixa_e,:6 renda FROM dual) s
                ON (t.id_municipio=s.id) WHEN MATCHED THEN UPDATE SET
                t.total_alfabetizacao=s.total_a,t.nao_alfabetizados=s.nao_a,
                t.total_escolaridade=s.total_e,t.baixa_escolaridade=s.baixa_e,t.renda_media=s.renda
                WHEN NOT MATCHED THEN INSERT
                (id_municipio,total_alfabetizacao,nao_alfabetizados,total_escolaridade,baixa_escolaridade,renda_media)
                VALUES (s.id,s.total_a,s.nao_a,s.total_e,s.baixa_e,s.renda)""", indicators)
            cursor.executemany("""MERGE INTO tab_indicador_uf t USING
                (SELECT :1 id,:2 total_a,:3 nao_a FROM dual) s
                ON (t.id_uf=s.id) WHEN MATCHED THEN UPDATE SET
                t.total_alfabetizacao=s.total_a,t.nao_alfabetizados=s.nao_a
                WHEN NOT MATCHED THEN INSERT (id_uf,total_alfabetizacao,nao_alfabetizados)
                VALUES (s.id,s.total_a,s.nao_a)""", states)
            cursor.executemany("""MERGE INTO tab_pnad_resumo t USING
                (SELECT :1 nivel,:2 total,:3 com_renda,:4 renda FROM dual) s
                ON (t.nivel_instrucao=s.nivel) WHEN MATCHED THEN UPDATE SET
                t.total_amostra=s.total,t.amostra_com_renda=s.com_renda,t.renda_media=s.renda
                WHEN NOT MATCHED THEN INSERT
                (nivel_instrucao,total_amostra,amostra_com_renda,renda_media)
                VALUES (s.nivel,s.total,s.com_renda,s.renda)""", pnad)
        connection.commit()
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()
    print(f"Carregados: {len(geo)} municípios, {len(indicators)} indicadores, {len(states)} UFs, {len(pnad)} níveis PNAD.")


if __name__ == "__main__":
    if sys.argv[1:] == ["--check"]:
        geo, indicators, pnad = build_data()
        states = uf_data()
        print(f"Verificados: {len(geo)} municípios; "
              f"{len(states)} UFs; "
              f"{sum(row[1] is not None for row in indicators)} taxas; "
              f"{sum(row[1] is not None and row[5] is not None for row in indicators)} taxas com renda; "
              f"{sum(row[1] for row in pnad)} registros PNAD.")
    elif not sys.argv[1:]:
        load()
    else:
        raise SystemExit("Uso: python Python/load_data.py [--check]")
