#!/usr/bin/env python3
"""
Sanduíche cross-harness: planeja e revisa no Antigravity, executa no OpenCode.

    planejar (agy, modelo de fronteira)
       -> [gate humano: aprovar o plano]
       -> executar (opencode, modelo barato) + gate determinístico
       -> review adversarial (agy)  ->  ACCEPT | REWORK -> volta a executar

O contrato entre os dois harnesses é **arquivo**, não chamada de API: o plano vira
`.opencode/plans/<slug>.md`, a execução produz um diff, o review lê os dois.

Uso:
    python3 sandwich.py "adicionar GET /atletas/{id} com 404"
    python3 sandwich.py --review-only .opencode/plans/atleta-id.md

Configuração por variável de ambiente (as flags do agy variam por versão — confirme
com `agy --help` na sua máquina antes do primeiro uso):

    AGY_BIN        binário do CLI do Antigravity            (padrão: agy)
    AGY_HEADLESS   subcomando de execução não-interativa     (padrão: run)
    OPENCODE_BIN   binário do OpenCode                       (padrão: opencode)
    CHEAP_MODEL    modelo do executor, ex. opencode-go/deepseek-v4.1-flash
    MAX_CYCLES     tentativas de correção antes de escalar   (padrão: 3)
"""

import argparse
import os
import re
import subprocess
import sys
import unicodedata
from pathlib import Path

AGY = os.environ.get("AGY_BIN", "agy")
AGY_HEADLESS = os.environ.get("AGY_HEADLESS", "run").split()
OPENCODE = os.environ.get("OPENCODE_BIN", "opencode")
CHEAP_MODEL = os.environ.get("CHEAP_MODEL", "")
MAX_CYCLES = int(os.environ.get("MAX_CYCLES", "3"))
PLAN_DIR = Path(".opencode/plans")
GATE = Path(os.environ.get("AGENT_GATE", Path.home() / ".config/opencode/scripts/agent-gate.sh"))


def slugify(texto: str, limite: int = 48) -> str:
    s = unicodedata.normalize("NFKD", texto).encode("ascii", "ignore").decode()
    s = re.sub(r"[^a-zA-Z0-9]+", "-", s).strip("-").lower()
    return s[:limite] or "feature"


def rodar(cmd: list[str], entrada: str | None = None) -> tuple[int, str]:
    """Executa e devolve (exit, stdout+stderr). Nunca levanta exceção de subprocesso."""
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, input=entrada, timeout=1800)
        return p.returncode, (p.stdout or "") + (p.stderr or "")
    except FileNotFoundError:
        return 127, f"binário não encontrado: {cmd[0]}"
    except subprocess.TimeoutExpired:
        return 124, f"timeout: {' '.join(cmd[:3])}"


def agy(prompt: str) -> tuple[int, str]:
    return rodar([AGY, *AGY_HEADLESS, prompt])


def opencode(prompt: str, agent: str) -> tuple[int, str]:
    cmd = [OPENCODE, "run", "--agent", agent]
    if CHEAP_MODEL:
        cmd += ["--model", CHEAP_MODEL]
    cmd += [prompt]
    return rodar(cmd)


def gate() -> tuple[int, str]:
    """Roda o gate determinístico; cai para mvn direto se o script não existir."""
    if GATE.exists():
        return rodar([str(GATE)])
    if Path("pom.xml").exists():
        return rodar(["mvn", "-q", "-B", "-DskipITs", "verify"])
    return 3, "GATE_SKIP: nenhum gate disponível"


def diff() -> str:
    rc, out = rodar(["git", "diff", "--stat"])
    rc2, completo = rodar(["git", "diff"])
    return f"{out}\n\n{completo}"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("feature", nargs="?", help="descrição da feature")
    ap.add_argument("--review-only", metavar="PLANO", help="pula o plano e revisa o diff contra um plano existente")
    ap.add_argument("--yes", action="store_true", help="não pede confirmação entre etapas")
    args = ap.parse_args()

    PLAN_DIR.mkdir(parents=True, exist_ok=True)

    # ---------- 1. PLANO (fronteira) ----------
    if args.review_only:
        plano_path = Path(args.review_only)
        if not plano_path.exists():
            print(f"plano não encontrado: {plano_path}", file=sys.stderr)
            return 2
    else:
        if not args.feature:
            ap.error("informe a feature ou use --review-only")
        plano_path = PLAN_DIR / f"{slugify(args.feature)}.md"
        prompt = (
            "Você é o planejador. Investigue o repositório antes de perguntar. "
            "Escreva o plano em markdown, com as seções: Contexto, Contrato, "
            "Arquivos que podem ser tocados, Passos (com o comando de verificação de cada um), "
            "Critérios de aceite verificáveis por comando, Riscos, Fora de escopo. "
            "Não escreva código. Responda SOMENTE com o markdown do plano.\n\n"
            f"Feature: {args.feature}"
        )
        print("[1/4] planejando no Antigravity…")
        rc, saida = agy(prompt)
        if rc != 0:
            print(f"falhou ao planejar (exit {rc}):\n{saida[:2000]}", file=sys.stderr)
            return rc
        plano_path.write_text(saida, encoding="utf-8")
        print(f"      plano salvo em {plano_path}")

        if not args.yes:
            print("\n--- plano ---")
            print(saida[:4000])
            print("-------------")
            if input("Aprovar o plano e executar? [s/N] ").strip().lower() != "s":
                print("plano mantido; execução cancelada.")
                return 0

    plano = plano_path.read_text(encoding="utf-8")

    # ---------- 2..N. EXECUTAR + REVISAR ----------
    for ciclo in range(1, MAX_CYCLES + 1):
        print(f"\n[{2}/4] ciclo {ciclo}/{MAX_CYCLES}: executando no OpenCode…")
        rc, saida = opencode(
            f"Implemente o plano em {plano_path}. Carregue a skill tdd-java: escreva o teste "
            "que falha, rode para provar que falha, implemente o mínimo, rode de novo. "
            "Não faça commit nem push. Ao terminar, reporte GATE, DESVIOS e PENDÊNCIAS.",
            agent="builder",
        )
        print(f"      builder exit={rc}")
        print(saida[-1500:] if saida else "")

        print(f"[3/4] gate determinístico…")
        g_rc, g_out = gate()
        print(f"      gate exit={g_rc}")
        if g_rc == 3:
            print("      sem gate configurado: não há como validar a execução.\n"
                  "      Crie .agent-gate.sh no repo (ou use um projeto Maven/Gradle).",
                  file=sys.stderr)
            return 3
        if g_rc != 0:
            print(g_out[-2000:])
            must_fixes = f"O gate falhou. Corrija a causa:\n\n{g_out[-3000:]}"
        else:
            print(f"[4/4] review adversarial no Antigravity…")
            prompt_review = (
                "Você é um revisor adversarial. Não escreveu este código. "
                "Procure o que passaria no teste e ainda assim estaria errado: "
                "caminho de erro ignorado, transação faltando, autorização ausente, "
                "teste que não testa o que diz.\n"
                "Responda começando com uma linha 'VEREDITO: ACCEPT' ou 'VEREDITO: REWORK'. "
                "Em REWORK, liste MUST-FIX numerado com arquivo:linha e o que mudar.\n\n"
                f"## Plano aprovado\n{plano[:6000]}\n\n## Diff\n{diff()[:12000]}"
            )
            r_rc, r_out = agy(prompt_review)
            if r_rc != 0:
                print(f"review falhou (exit {r_rc}):\n{r_out[:1500]}", file=sys.stderr)
                return r_rc
            print(r_out[:3000])
            if re.search(r"VEREDITO:\s*ACCEPT", r_out, re.I):
                print(f"\nACCEPT no ciclo {ciclo}. Diff pronto para você revisar e commitar.")
                return 0
            must_fixes = r_out

        if ciclo == MAX_CYCLES:
            print(f"\n{MAX_CYCLES} ciclos sem ACCEPT — escalando para você.")
            print(must_fixes[:3000])
            return 1
        print(f"      REWORK — devolvendo ao builder…")
        plano = plano + f"\n\n## Must-fixes do ciclo {ciclo}\n{must_fixes[:4000]}"
        plano_path.write_text(plano, encoding="utf-8")

    return 0


if __name__ == "__main__":
    sys.exit(main())
