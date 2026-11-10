"""Gera malhas leves por UF a partir da Malha Municipal Digital 2025 do IBGE."""

import json
import shutil
import subprocess
import urllib.request
import zipfile
from pathlib import Path

from load_data import UF, geography


ROOT = Path(__file__).resolve().parent.parent
TEMP = ROOT / "malha_tmp"
OUTPUT = ROOT / "static" / "malhas"
BASE_URL = "https://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_municipais/municipio_2025/Brasil/"


def convert(name):
    TEMP.mkdir(exist_ok=True)
    result = TEMP / f"{name}.geojson"
    if result.exists():
        return json.loads(result.read_text(encoding="utf-8"))
    archive = TEMP / f"{name}.zip"
    if not archive.exists():
        print(f"Baixando {name} do IBGE…", flush=True)
        urllib.request.urlretrieve(BASE_URL + archive.name, archive)
    folder = TEMP / name
    folder.mkdir(exist_ok=True)
    with zipfile.ZipFile(archive) as source:
        for member in source.namelist():
            if Path(member).suffix.lower() in {".shp", ".dbf", ".shx", ".prj", ".cpg"}:
                source.extract(member, folder)
    shapefiles = list(folder.rglob("*.shp"))
    if len(shapefiles) != 1:
        raise RuntimeError(f"Esperava uma malha SHP em {name}: {shapefiles}")
    npx = shutil.which("npx")
    if not npx:
        raise RuntimeError("Node.js/npx é necessário para simplificar a malha.")
    subprocess.run([npx, "--yes", "--package=mapshaper@0.7.101", "mapshaper",
                    str(shapefiles[0]), "-simplify", "10%", "keep-shapes",
                    "-o", "format=geojson", "precision=0.0001", str(result)], check=True)
    return json.loads(result.read_text(encoding="utf-8"))


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    geo = convert("BR_Municipios_2025")
    grouped = {sigla: [] for sigla, _ in UF.values()}
    valid_codes = {str(row[0]) for row in geography().values()}
    codes = set()
    for feature in geo["features"]:
        props = feature["properties"]
        code = str(props.get("CD_MUN", props.get("codarea", "")))
        if code not in valid_codes:
            continue  # A malha também contém áreas que não constam no banco do projeto.
        sigla = UF.get(int(code[:2]), (None,))[0]
        if not sigla:
            continue
        assert code not in codes, code
        codes.add(code)
        feature["properties"] = {"id_municipio": int(code)}
        grouped[sigla].append(feature)
    assert codes == valid_codes and "5101837" in codes, (len(codes), len(valid_codes))
    for sigla, features in grouped.items():
        (OUTPUT / f"{sigla}.geojson").write_text(
            json.dumps({"type": "FeatureCollection", "features": features}, separators=(",", ":")), encoding="utf-8")
    ufs = convert("BR_UF_2025")
    seen = set()
    for feature in ufs["features"]:
        code = str(feature["properties"].get("CD_UF", feature["properties"].get("codarea", "")))
        assert code.isdigit() and int(code) in UF and code not in seen, code
        seen.add(code)
        feature["properties"] = {"id_uf": int(code)}
    assert len(seen) == 27
    (OUTPUT / "ufs.geojson").write_text(json.dumps(ufs, separators=(",", ":")), encoding="utf-8")
    print(f"Malhas prontas: {len(codes)} municípios e {len(seen)} UFs.")


if __name__ == "__main__":
    main()
