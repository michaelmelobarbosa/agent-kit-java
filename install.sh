#!/usr/bin/env bash
# Instala o Agent Kit Java no config GLOBAL do OpenCode.
# Linux / macOS.  Uso: bash install.sh [--force]
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
STAMP="$(date +%Y%m%d-%H%M%S)"
FORCE="${1:-}"

echo "origem:  $SRC"
echo "destino: $DEST"

mkdir -p "$DEST"

# backup se já existir
if [ -e "$DEST/opencode.json" ] || [ -d "$DEST/agents" ]; then
  BK="$DEST/.backup-$STAMP"
  mkdir -p "$BK"
  for f in opencode.json AGENTS.md agents skills commands scripts; do
    [ -e "$DEST/$f" ] && cp -a "$DEST/$f" "$BK/" 2>/dev/null || true
  done
  echo "backup:  $BK"
fi

# agentes, skills, comandos, scripts
for d in agents skills commands scripts; do
  mkdir -p "$DEST/$d"
  cp -a "$SRC/global/$d/." "$DEST/$d/"
done
chmod +x "$DEST/scripts/agent-gate.sh" 2>/dev/null || true

# AGENTS.md global
cp -a "$SRC/global/AGENTS.md" "$DEST/AGENTS.md"

# opencode.json: nunca sobrescreve config existente
if [ -e "$DEST/opencode.json" ] && [ "$FORCE" != "--force" ]; then
  cp "$SRC/global/opencode.json" "$DEST/opencode.json.new"
  echo
  echo "ATENÇÃO: já existe $DEST/opencode.json — não mexi nele."
  echo "Mescle à mão os blocos 'subagent_depth', 'instructions' e 'agent' de:"
  echo "  $DEST/opencode.json.new"
  echo "(ou rode com --force para sobrescrever, sabendo que perde provider/API key)"
else
  cp "$SRC/global/opencode.json" "$DEST/opencode.json"
  echo "config:  $DEST/opencode.json"
fi

echo
echo "instalado:"
find "$DEST" -maxdepth 2 \( -name '*.md' -o -name '*.json' -o -name 'agent-gate.*' \) -newermt '-2 minutes' | sed 's|^|  |'
echo
echo "verifique com:  opencode agent list"
