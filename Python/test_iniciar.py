"""Verifica o iniciador sem instalar pacotes nem abrir o servidor."""

import importlib.util
import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


spec = importlib.util.spec_from_file_location("iniciar", Path(__file__).resolve().parents[1] / "iniciar.py")
iniciar = importlib.util.module_from_spec(spec)
spec.loader.exec_module(iniciar)


class IniciarTest(unittest.TestCase):
    def setUp(self):
        folder = tempfile.TemporaryDirectory(prefix="mapa com espaços ")
        self.addCleanup(folder.cleanup)
        self.root = Path(folder.name)
        (self.root / "requirements.txt").write_bytes(b"Flask>=3.0,<4\n")
        patcher = patch.object(iniciar, "ROOT", self.root)
        patcher.start()
        self.addCleanup(patcher.stop)

    def prepare_environment(self):
        python = self.root / ".venv" / ("Scripts/python.exe" if os.name == "nt" else "bin/python")
        python.parent.mkdir(parents=True)
        python.touch()
        return python

    def test_first_run_creates_environment_and_installs(self):
        with patch.object(iniciar.venv, "EnvBuilder") as builder, \
                patch.object(iniciar.subprocess, "run") as install, \
                patch.object(iniciar.subprocess, "call", return_value=0) as server:
            # O ambiente simulado precisa existir para receber o marcador de instalação.
            builder.return_value.create.side_effect = lambda _: self.prepare_environment()
            self.assertEqual(iniciar.main(), 0)
        builder.assert_called_once_with(with_pip=True)
        builder.return_value.create.assert_called_once_with(self.root / ".venv")
        self.assertEqual(install.call_args.args[0][1:5], ["-m", "pip", "install", "-r"])
        self.assertTrue(install.call_args.kwargs["check"])
        self.assertEqual(server.call_args.kwargs["cwd"], self.root)
        self.assertEqual(server.call_args.args[0][-1], str(self.root / "Python" / "app.py"))

    def test_reuses_environment_and_propagates_server_exit(self):
        self.prepare_environment()
        (self.root / ".venv" / ".requirements-installed").write_bytes(
            (self.root / "requirements.txt").read_bytes())
        with patch.object(iniciar.subprocess, "run") as install, \
                patch.object(iniciar.subprocess, "call", return_value=1):
            self.assertEqual(iniciar.main(), 1)
        install.assert_not_called()

    def test_changed_requirements_trigger_installation(self):
        self.prepare_environment()
        marker = self.root / ".venv" / ".requirements-installed"
        marker.write_bytes(b"old\n")
        with patch.object(iniciar.subprocess, "run") as install, \
                patch.object(iniciar.subprocess, "call", return_value=0):
            iniciar.main()
        install.assert_called_once()
        self.assertEqual(marker.read_bytes(), (self.root / "requirements.txt").read_bytes())

    def test_failed_install_does_not_start_server_or_mark_success(self):
        self.prepare_environment()
        with patch.object(iniciar.subprocess, "run", side_effect=subprocess.CalledProcessError(1, "pip")), \
                patch.object(iniciar.subprocess, "call") as server:
            with self.assertRaises(subprocess.CalledProcessError):
                iniciar.main()
        server.assert_not_called()
        self.assertFalse((self.root / ".venv" / ".requirements-installed").exists())

    def test_old_python_stops_before_creating_environment(self):
        with patch.object(iniciar.sys, "version_info", (3, 9)), \
                patch.object(iniciar.venv, "EnvBuilder") as builder:
            with self.assertRaisesRegex(SystemExit, "3.10"):
                iniciar.main()
        builder.assert_not_called()
