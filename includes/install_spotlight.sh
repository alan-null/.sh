#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

sudo apt install -y python3
python3 -c 'import sys; sys.exit("Spotlight requires Python 3.11 or newer; upgrade python3 and rerun the installer." if sys.version_info < (3, 11) else 0)'
git -C "$INSTALL_DIR" submodule sync --recursive -- spotlight
git -C "$INSTALL_DIR" submodule update --init --recursive --checkout -- spotlight

echo "→ Spotlight installed"
