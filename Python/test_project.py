"""Checagens dos dados, malhas e API após a instalação local."""

import json
import unittest
from pathlib import Path

from load_data import build_data, uf_data


ROOT = Path(__file__).resolve().parent.parent


class ProjectTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.geo, cls.indicators, cls.pnad = build_data()

    def test_data_coverage_and_rates(self):
        self.assertEqual(len(self.geo), 5571)
        self.assertEqual(sum(row[1] is not None for row in self.indicators), 5334)
        self.assertEqual(sum(row[1] is not None and row[5] is not None for row in self.indicators), 5330)
        self.assertEqual(sum(row[1] for row in self.pnad), 76492)
        self.assertEqual(next(row for row in self.indicators if row[0] == 5101837)[1:], (None,) * 5)
        for _, total, nonliterate, school_total, low_school, income in self.indicators:
            if total is not None:
                self.assertGreater(total, 0)
                self.assertLessEqual(nonliterate, total)
            if school_total is not None and low_school is not None:
                self.assertLessEqual(low_school, school_total)
            if income is not None:
                self.assertGreaterEqual(income, 0)

    def test_geometry_codes(self):
        folder = ROOT / "static" / "malhas"
        self.assertEqual(len(json.loads((folder / "ufs.geojson").read_text(encoding="utf-8"))["features"]), 27)
        codes = set()
        for path in folder.glob("[A-Z][A-Z].geojson"):
            features = json.loads(path.read_text(encoding="utf-8"))["features"]
            for feature in features:
                code = feature["properties"]["id_municipio"]
                self.assertNotIn(code, codes)
                codes.add(code)
        self.assertEqual(codes, {row[0] for row in self.indicators})

    def test_state_totals(self):
        states = uf_data()
        self.assertEqual(len(states), 27)
        self.assertEqual(len({code for code, _, _ in states}), 27)
        for _, total, nonliterate in states:
            self.assertGreater(total, 0)
            self.assertGreaterEqual(nonliterate, 0)
            self.assertLessEqual(nonliterate, total)
        # O total oficial difere da soma municipal quando ha municipios sem dados.
        mt_total = next(total for code, total, _ in states if code == 51)
        mt_municipal = sum(row[1] or 0 for row in self.indicators
                           if str(row[0]).startswith("51"))
        self.assertNotEqual(mt_total, mt_municipal)

    def test_api(self):
        from app import app

        with app.test_client() as client:
            self.assertEqual(client.get("/").status_code, 200)
            script = client.get("/static/app.js")
            self.assertEqual(script.status_code, 200)
            script.close()
            ufs = client.get("/api/ufs").get_json()
            self.assertEqual(len(ufs), 27)
            self.assertEqual(sum(uf["com_taxa"] for uf in ufs), 5334)
            self.assertEqual(sum(uf["taxa_analfabetismo"] is not None for uf in ufs), 27)
            state_totals = {code: (total, nonliterate) for code, total, nonliterate in uf_data()}
            for uf in ufs:
                total, nonliterate = state_totals[uf["id_uf"]]
                self.assertEqual(uf["total_alfabetizacao"], total)
                self.assertEqual(uf["nao_alfabetizados"], nonliterate)
                self.assertEqual(uf["taxa_analfabetismo"], round(100 * nonliterate / total, 2))
            self.assertEqual(client.get("/api/municipios?uf=XX").status_code, 400)
            catalog = client.get("/api/catalogo-municipios").get_json()
            self.assertEqual(len(catalog), 5571)
            self.assertEqual(len({city["id_municipio"] for city in catalog}), 5571)
            self.assertTrue(all(city["uf"] in {uf["sigla"] for uf in ufs} for city in catalog))
            self.assertEqual(next(city["uf"] for city in catalog if city["id_municipio"] == 5101837), "MT")
            mt = client.get("/api/municipios?uf=MT").get_json()
            boa = next(city for city in mt if city["id_municipio"] == 5101837)
            self.assertIsNone(boa["taxa_analfabetismo"])
            self.assertIsNone(boa["renda_media"])
            self.assertEqual(sum(row["total_amostra"] for row in client.get("/api/pnad-escolaridade").get_json()), 76492)


if __name__ == "__main__":
    unittest.main()
