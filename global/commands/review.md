---
description: Revisa o diff atual (ou o plano) antes do commit, com gate executado.
---

Alvo: $ARGUMENTS

Se vazio, revise o diff não commitado (`git diff` + `git status`). Se for um caminho para
`.opencode/plans/`, trate como revisão de plano.

## 1. Gate primeiro
Rode o gate você mesmo e capture a saída literal:

```bash
~/.config/opencode/scripts/agent-gate.sh
```

(Windows: `~\.config\opencode\scripts\agent-gate.ps1`)

Se o gate falhar, **é isso o resultado da revisão** — reporte a falha e o trecho do log, e
pare. Não revise código que nem compila.

## 2. Revisão
Invoque `code-reviewer` com: o diff do git, o plano correspondente (se existir), e a saída
do gate. Formato esperado: VEREDITO, MUST-FIX ranqueado com `arquivo:linha` e repro,
DEVERIA, e o que está bom.

## 3. QA e segurança (quando aplicável)
- Mudança de comportamento → `qa-blind` contra os critérios de aceite.
- Mudança que toca controller, query, auth, config ou dependência → `security-reviewer`.

## 4. Síntese para mim
Uma tabela: achado · severidade · bloqueia? · quem corrige.
Termine com `PODE COMMITAR` ou `REWORK NECESSÁRIO` e a lista do que fazer antes.

Não corrija nada sem eu pedir, e não faça commit.
