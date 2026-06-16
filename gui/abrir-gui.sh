#!/usr/bin/env bash
# Lanza la ventana OptiComSoc. Instala python3-tk si hace falta.
cd "$(dirname "$0")"
if ! python3 -c "import tkinter" 2>/dev/null; then
  echo ">> Instalando python3-tk (requiere internet)..."
  sudo apt-get update && sudo apt-get install -y python3-tk
fi
python3 optcomsoc.py
