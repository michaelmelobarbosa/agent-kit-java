# Agent Kit — Java / Spring Boot para OpenCode

Configuração **global** de agentes de código para desenvolvimento Java/Spring Boot com
[OpenCode](https://opencode.ai): um planejador que não edita código, um implementador que
testa antes de codar, e revisores independentes que rodam o gate em vez de acreditar no
relatório.

O objetivo é sair do microgerenciamento: você aparece três vezes por feature — aprovar o
plano, decidir quando um ciclo de correção sai do trilho, e revisar o diff final.

> Instalado em `~/.config/opencode/`. Os cinco agentes ficam disponíveis em **todos** os
> projetos Java da máquina; cada repositório só acrescenta o que é específico dele.

## O fluxo

```
você: feature + critérios de aceite
  |
  v
planner  ──────────> .opencode/plans/<feature>.md        (artefato, não conversa)
  |                        ^
  |                        └── code-reviewer critica o plano
  v  [GATE HUMANO: aprovar o plano]
builder + skill tdd-java (RED -> GREEN -> REFACTOR)
  |
  v
GATE DETERMINÍSTICO: agent-gate.sh  =>  mvn -DskipITs verify
  |  falhou -> volta ao builder (máx. 3 ciclos)
  v  passou
code-reviewer  ||  qa-blind  ||  security-reviewer        (paralelo, read-only)
  |
  v  ACCEPT / REWORK com must-fixes
```

## Por que funciona

- **Plano é arquivo, não conversa.** O estado sobrevive à sessão e o builder não improvisa
  escopo.
- **O revisor não escreveu o código** e roda o gate: quem avalia o próprio trabalho é
  sistematicamente otimista.
- **Teste antes do código** (skill `tdd-java`): teste que nunca falhou não prova nada.
- **Permissão reduzida de verdade** — `planner` e revisores têm `edit: deny` na
  configuração, não só na instrução do prompt.

## Índice

| Caminho | O que é |
|---|---|
| `global/agents/` | os cinco agentes (planner, builder, code-reviewer, qa-blind, security-reviewer) |
| `global/skills/tdd-java/` | skill de TDD aplicada a Maven/JUnit 5 |
| `global/scripts/agent-gate.*` | gate determinístico (bash e PowerShell) |
| `global/commands/` | `/feature` e `/review` |
| `global/AGENTS.md` | convenções Java/Spring universais |
| `global/opencode.json` | `subagent_depth`, instruções e matriz de permissões |
| `project-template/AGENTS.md` | modelo do que é específico de cada repositório |

Instalação, verificação e ajuste de modelo: veja abaixo.

---
## As três camadas

| Camada | Onde | O que entra | Por que |
|---|---|---|---|
| **Global** | `~/.config/opencode/` | agentes, skills, permissões, `AGENTS.md` com convenções Java universais, script do gate | você é Java em quase todo projeto; escrever isso uma vez e esquecer |
| **Projeto** | `./AGENTS.md` + `./.opencode/` | convenções do repo (pacotes, módulos, regra de negócio), plano da feature, override do gate | é o único lugar onde "Spring Boot" vira "este projeto" |
| **Nunca** | — | credencial, path absoluto de máquina, modelo hardcoded que você não tem | quebra ao trocar de máquina/repo |

**Regra de bolso:** se a instrução vale para qualquer repo Java, é global. Se ela cita um
nome de módulo, tabela, endpoint ou cliente, é do projeto.

## O que é aplicado vs. o que é aconselhado

Isto é a parte honesta do kit. Nem tudo é garantido por configuração.

| Mecanismo | Força | Como |
|---|---|---|
| `planner` não edita código | **aplicado** | `permission.edit` restrito a `**/plans/**` |
| `builder` não faz `git commit`/`push` | **aplicado** | `permission.bash` com deny |
| `code-reviewer`/`qa-blind` são read-only | **aplicado** | `edit: deny` no agente |
| builder só alcança os especialistas nomeados | **aplicado** | `permission.task` como allowlist |
| `mvn verify` antes de fechar | **aconselhado** | skill + prompt; o reviewer **reexecuta** o gate |
| testes escritos antes do código | **aconselhado** | skill `tdd-java` |

O kit não usa plugin JS (a API de plugin do OpenCode muda entre versões). O gate roda
como **script** e quem o executa é o reviewer — se o builder mentir no relatório, o
reviewer pega, porque roda o comando em vez de ler o resumo.

## Instalação

```bash
# Linux / macOS
bash install.sh
```

```powershell
# Windows (PowerShell)
powershell -ExecutionPolicy Bypass -File install.ps1
```

O instalador:
1. faz backup de `~/.config/opencode/` se já existir;
2. copia agentes, skills, comandos e o `AGENTS.md` global;
3. **não sobrescreve** um `opencode.json` existente — ele gera `opencode.json.new` e
   avisa, porque esse arquivo costuma ter provider/API key;
4. deixa o script do gate executável.

Se você já tem config global, o caminho é: abra `~/.config/opencode/opencode.json` e
mescle os blocos `subagent_depth`, `instructions` e `agent` do `opencode.json.new`.

## Verificar que carregou

```bash
opencode agent list
```

Deve aparecer `planner`, `builder`, `code-reviewer`, `qa-blind`, `security-reviewer`.

Smoke test:

```bash
opencode
# digite: /feature adicionar endpoint GET /atletas/{id} com teste
```

Esperado: `planner` escreve `.opencode/plans/<slug>.md` → você aprova → `builder`
implementa com teste primeiro → `code-reviewer` roda o gate e devolve ACCEPT ou REWORK.

## Ajustar modelos

Os agentes vêm **sem `model`** fixo de propósito: sem `model`, o subagente usa o modelo
do primário que o chamou. Para rotear por custo (caro no julgamento, barato na mecânica),
descomente o campo no frontmatter de cada `.md`. Com `opencode go`, os ids que costumam
existir:

- `opencode-go/kimi-k3` — julgamento (planner, reviewer)
- `opencode-go/deepseek-v4.1-flash` — mecânica (builder, qa-blind)

Confirme com `/models` antes de fixar — id de modelo muda de mês em mês.

## Cuidado ao editar permissões: a ÚLTIMA regra vence

`permission` é uma lista avaliada em ordem e **a última regra que casa ganha**. Isso tem
duas consequências:

- o coringa (`"*"`) tem que vir **primeiro**; se ele vier por último, apaga todas as
  permissões específicas acima dele;
- para liberar uma exceção dentro de um deny geral, a exceção vai **depois**:
  `{ "*": "deny", "**/plans/**": "allow" }`.

O kit já está nessa ordem. Se você acrescentar uma regra, coloque-a no fim.

## Onde acabou o microgerenciamento

Você aparece **três vezes** por feature: aprovar o plano, decidir quando um ciclo de
REWORK sai do trilho (limite: 3), e revisar o diff final. O resto é automático.

## Estrutura

```
~/.config/opencode/
├── opencode.json              # subagent_depth, instructions, permissions
├── AGENTS.md                  # convenções Java universais
├── agents/
│   ├── planner.md             # primary, não edita código
│   ├── builder.md             # subagent, edita e roda mvn
│   ├── code-reviewer.md       # subagent read-only, veredito ACCEPT/REWORK
│   ├── qa-blind.md            # subagent read-only, só sabe a spec
│   └── security-reviewer.md   # subagent read-only, checklist + SAST
├── skills/
│   └── tdd-java/SKILL.md      # RED-GREEN-REFACTOR aplicado a Maven
├── commands/
│   ├── feature.md             # /feature
│   └── review.md              # /review
└── scripts/
    ├── agent-gate.sh          # mvn verify + SAST, usado pelo reviewer
    └── agent-gate.ps1
```

No projeto, opcional: `.agent-gate.sh` (override do gate quando o repo não é Maven puro).
