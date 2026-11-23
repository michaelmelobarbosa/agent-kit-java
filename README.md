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
| `global/commands/` | `/feature`, `/execute` e `/review` |
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

## Modelos: por que o kit vem sem `model`

**Nenhum agente do kit tem modelo fixo.** Isso é deliberado, mas tem consequência — e é
a primeira coisa que você provavelmente vai querer mudar.

Como o OpenCode resolve a ausência do campo:

- **primary** sem `model` → usa o modelo globalmente configurado no `opencode.json`;
- **subagent** sem `model` → usa o modelo do **primário que o chamou**.

Na prática, hoje: o `planner` roda no seu modelo padrão, chama o `builder` que herda esse
mesmo modelo, e o `code-reviewer` idem. **Um modelo faz os cinco papéis.** Funciona, mas
joga fora duas coisas que motivaram o desenho: roteamento por custo e independência do
revisor.

### O mapeamento que eu recomendo

| Papel | Perfil | Por quê |
|---|---|---|
| `planner` | modelo forte | interpreta ambiguidade, decide escopo — o lugar mais caro de errar |
| `builder` | modelo barato/rápido | é volume: escrever teste, implementar, rodar comando |
| `qa-blind` | modelo barato | executa e lê saída, não julga arquitetura |
| `code-reviewer` | **outro vendor** | quem avalia o próprio trabalho é otimista; mesma família compartilha ponto cego |
| `security-reviewer` | **outro vendor** | idem, e é onde o ponto cego custa mais |

Os `.md` já trazem a sugestão como **comentário** (`# model: ...`), justamente para não
quebrar o carregamento se o id não existir na sua conta. Para ativar, descomente e
confirme o identificador com `/models` dentro do OpenCode — id de modelo muda de mês em
mês, e um `model` inválido faz o agente falhar.

### Revisão cross-vendor: três caminhos

O `opencode go` é uma assinatura de modelos abertos curados. O Antigravity é outro
**harness**, não um provider do OpenCode — então "revisor de outro vendor" não sai de
graça só porque você usa os dois no T3 Code. Três opções, da mais forte à mais fraca:

1. **Adicionar um provider ao OpenCode** (Google/Gemini via API key, OpenCode Zen, ou
   GitHub Copilot). Aí `code-reviewer` e `security-reviewer` apontam para outro vendor e o
   fluxo inteiro acontece em uma sessão.
2. **Revisar no Antigravity**, em thread separada do T3 Code: você roda o `/review` lá,
   colando `git diff` + caminho do plano. O kit continua igual; só o passo de revisão sai
   do OpenCode. É o arranjo que mais aparece nos relatos de quem faz isso na prática.
3. **Mesmo vendor, sessão nova** (o que você tem hoje sem configurar nada): melhor que
   revisar na mesma conversa, pior que trocar de família. Não é teatro, mas não é a
   independência que o desenho promete.

### Custo de pano de fundo

O OpenCode roda tarefas pequenas (gerar título de sessão, por exemplo) num modelo
barato. Para não vazar para um default remoto, fixe no `opencode.json`:

```jsonc
"small_model": "opencode-go/<modelo-barato>"
```

(Se preferir manter comentário no arquivo, renomeie para `opencode.jsonc` — `opencode.json`
não aceita `//`.)

## Dois harnesses: o artefato é a ponte (caminho recomendado)

Se seus melhores modelos estão num harness e os mais baratos em outro, a divisão natural é
**planejar no caro, executar no barato, revisar no caro**. Isso funciona — mas não por
chamada de modelo para modelo.

O impedimento não é "vendor diferente": é **harness diferente**. Um subagente do OpenCode é
uma sessão dentro do runtime do OpenCode; o Antigravity é outro runtime. Nenhum dos dois
expõe o outro como ferramenta.

### Como fazer, sem tocar em credencial

O contrato entre os dois é **um arquivo markdown**. Nada de token compartilhado, nada de
subprocesso:

```bash
# 1) no Antigravity: peça o plano (use o prompt abaixo) e salve em
#    .opencode/plans/<slug>.md
# 2) aqui no OpenCode:
opencode
> /execute .opencode/plans/<slug>.md
# 3) se quiser o review adversarial no Antigravity: cole `git diff` + o plano lá
```

O comando `/execute` pula o planejamento, confere se o plano tem as seções mínimas,
manda o `builder` implementar com TDD, roda o gate e aciona os revisores.

Template do plano: [`project-template/.opencode/plans/_TEMPLATE.md`](project-template/.opencode/plans/_TEMPLATE.md).

### Prompt para o harness de planejamento

Cole no agy (ou em qualquer modelo de fronteira):

```
Você é o planejador. Investigue o repositório antes de perguntar.
Escreva o plano em markdown com EXATAMENTE estas seções:
Contexto, Contrato, Arquivos que podem ser tocados (lista fechada), Passos
(cada passo com o comando de verificação), Critérios de aceite (verificáveis
por comando ou teste), Riscos, Fora de escopo.
Não escreva código. Responda somente com o markdown do plano.

Feature: <descreva aqui>
```

### Por que este caminho e não acoplar os dois

- **Zero risco de conta**: cada harness roda na superfície para a qual você paga. O que
  costuma gerar bloqueio é reutilizar sessão/token de um produto dentro de outro — mover
  um `.md` não é isso.
- **Auditável**: o plano é versionável, revisável e sobrevive à sessão.
- **Desacoplado**: atualizar um harness não quebra o outro.

### As alternativas, e o que cada uma custa

| Ponte | Como funciona | Risco / custo |
|---|---|---|
| **Artefato** (recomendada) | plano `.md` e `git diff` são o contrato; você troca de harness entre etapas | manual; precisa de disciplina de arquivo |
| **Provider extra num harness só** | adicionar o provider do modelo de fronteira ao OpenCode e rotear por `model` | exige **API key legítima** (AI Studio/Vertex). Nunca reaproveitar a sessão do produto |
| **CLI cruzada** | um harness roda o outro como subprocesso (`agy ...`, `opencode run "..."`) | sem contexto compartilhado; ver `scripts/sandwich.py` |
| **SDK** | orquestrar os dois de um script (o Antigravity tem SDK Python) | exige escrever o orquestrador |

`scripts/sandwich.py` implementa a ponte por CLI, para quando você quiser automatizar o
ciclo em vez de trocar de janela. É opcional e não é necessário para o fluxo acima:

```bash
CHEAP_MODEL=opencode-go/deepseek-v4.1-flash \
python3 scripts/sandwich.py "adicionar GET /atletas/{id} com 404"
```

Ele pede o plano ao `agy`, mostra para aprovar, executa no `opencode run --agent builder`,
roda o gate, e devolve `plano + diff` ao `agy` para review adversarial (ACCEPT encerra,
REWORK volta ao builder, até 3 ciclos). As flags headless do `agy` variam por versão:
confirme com `agy --help` e ajuste `AGY_HEADLESS`. Se o gate devolver `3`, ele aborta em vez
de fingir que validou.

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
│   ├── feature.md             # /feature  (planeja + executa)
│   ├── execute.md             # /execute  (plano já pronto, de outro harness)
│   └── review.md              # /review
└── scripts/
    ├── agent-gate.sh          # mvn verify + SAST, usado pelo reviewer
    └── agent-gate.ps1
```

No projeto, opcional: `.agent-gate.sh` (override do gate quando o repo não é Maven puro)
e `.opencode/plans/` (onde os planos vivem — o template está em `project-template/`).
