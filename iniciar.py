"""Prepara o ambiente local e inicia o mapa: python iniciar.py."""

import os
import subprocess
import sys
import venv
from pathlib import Path


ROOT = Path(__file__).resolve().parent


def main():
    if sys.version_info < (3, 10):
        raise SystemExit("Use Python 3.10 ou superior.")

    environment = ROOT / ".venv"
    python = environment / ("Scripts/python.exe" if os.name == "nt" else "bin/python")
    if not python.exists():
        print("Criando ambiente Python em .venv...", flush=True)
        venv.EnvBuilder(with_pip=True).create(environment)

    requirements = ROOT / "requirements.txt"
    installed = environment / ".requirements-installed"
    if not installed.exists() or installed.read_bytes() != requirements.read_bytes():
        print("Instalando dependências...", flush=True)
        subprocess.run([str(python), "-m", "pip", "install", "-r", str(requirements)],
                       cwd=ROOT, check=True)
        installed.write_bytes(requirements.read_bytes())

    print("Abrindo servidor em http://127.0.0.1:5000 (Ctrl+C para encerrar).", flush=True)
    return subprocess.call([str(python), str(ROOT / "Python" / "app.py")], cwd=ROOT)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        pass
    except subprocess.CalledProcessError as error:
        raise SystemExit("Não foi possível instalar as dependências. Confira a conexão com a internet "
                         "e a mensagem do pip acima.") from error
    except OSError as error:
        raise SystemExit(f"Não foi possível preparar ou iniciar o ambiente: {error}. "
                         "Confira a instalação do Python (incluindo venv e pip) e a permissão da pasta.") from error
