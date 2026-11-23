#!/usr/bin/env bash
# Gate determinístico do ambiente Java. Sai 0 só se o build e os testes passarem.
# Uso:  agent-gate.sh            (gate padrão do repo)
#       agent-gate.sh --full     (não pula testes de integração)
# Override por projeto: crie .agent-gate.sh na raiz do repo (executável).
set -uo pipefail

MODE="${1:-default}"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT" || exit 2

LOG="${TMPDIR:-/tmp}/agent-gate.$$.log"
START=$(date +%s)

run() {
  echo "GATE: $*"
  "$@" >"$LOG" 2>&1
  local rc=$?
  if [ $rc -ne 0 ]; then
    echo "GATE_FAIL (exit $rc) em ${#} comandos — últimas 40 linhas:"
    tail -40 "$LOG"
    echo "GATE_FAIL repo=$ROOT cmd=$(printf '%q ' "$@")"
    rm -f "$LOG"
    exit $rc
  fi
  return 0
}

# 1) override do projeto
if [ -x "./.agent-gate.sh" ]; then
  echo "GATE: override do projeto (.agent-gate.sh)"
  ./.agent-gate.sh "$@"
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "GATE_FAIL override repo=$ROOT exit=$rc"
    exit $rc
  fi
  echo "GATE_OK override repo=$ROOT"
  exit 0
fi

# 2) Maven
if [ -f pom.xml ]; then
  if [ -x ./mvnw ]; then MVN=./mvnw; else MVN=mvn; fi
  if [ "$MODE" = "--full" ]; then
    run $MVN -q -B verify
  else
    run $MVN -q -B -DskipITs verify
  fi
  SECS=$(( $(date +%s) - START ))
  echo "GATE_OK maven repo=$ROOT ${SECS}s"
  rm -f "$LOG"; exit 0
fi

# 3) Gradle
if [ -f build.gradle ] || [ -f build.gradle.kts ]; then
  if [ -x ./gradlew ]; then GR=./gradlew; else GR=gradle; fi
  run $GR -q test
  SECS=$(( $(date +%s) - START ))
  echo "GATE_OK gradle repo=$ROOT ${SECS}s"
  rm -f "$LOG"; exit 0
fi

# 4) nada reconhecido: não finge que passou
echo "GATE_SKIP: nenhum build tool reconhecido em $ROOT (nem pom.xml, nem build.gradle, nem .agent-gate.sh)"
rm -f "$LOG"
exit 3
