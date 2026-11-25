"""Verifica o destino da instalação sem criar usuários nem conectar ao Oracle."""

import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import setup_db


class SetupDbTest(unittest.TestCase):
    def setUp(self):
        folder = tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        self.root = Path(folder.name)
        root_patch = patch.object(setup_db, "ROOT", self.root)
        root_patch.start()
        self.addCleanup(root_patch.stop)

    def test_installs_in_freepdb1_and_writes_the_same_dsn_for_both_users(self):
        with patch.object(setup_db, "sqlplus") as sqlplus, \
                patch.object(setup_db, "password", side_effect=["SenhaDonoTeste", "SenhaLeituraTeste"]), \
                patch("builtins.print"):
            setup_db.main()

        self.assertEqual(sqlplus.call_count, 2)
        admin_sql, admin_connection = sqlplus.call_args_list[0].args
        self.assertIn("ALTER SESSION SET CONTAINER=FREEPDB1;", admin_sql)
        self.assertEqual(admin_connection, "/ as sysdba")
        _, owner_connection = sqlplus.call_args_list[1].args
        self.assertEqual(owner_connection, "MAPA_IDOSOS/SenhaDonoTeste@localhost:1539/FREEPDB1")
        for filename, user in [(".env", "MAPA_IDOSOS_RO"), (".owner.env", "MAPA_IDOSOS")]:
            content = (self.root / filename).read_text(encoding="utf-8")
            self.assertIn(f"ORACLE_USER={user}\n", content)
            self.assertIn("ORACLE_DSN=localhost:1539/FREEPDB1\n", content)

    def test_existing_configuration_prevents_installation_and_overwrite(self):
        for filename in (".env", ".owner.env"):
            with self.subTest(filename=filename):
                path = self.root / filename
                path.write_text("configuracao local", encoding="utf-8")
                with patch.object(setup_db, "sqlplus") as sqlplus:
                    with self.assertRaises(SystemExit):
                        setup_db.main()
                    sqlplus.assert_not_called()
                self.assertEqual(path.read_text(encoding="utf-8"), "configuracao local")
                path.unlink()


if __name__ == "__main__":
    unittest.main()
