# Escolha de modelo por etapa

Duas decisões diferentes, que as pessoas confundem:

- **No OpenCode**, modelo é **configuração** (`model:` no frontmatter do agente). Fica
  versionado e vale para sempre.
- **No Antigravity**, modelo é **escolha de sessão** (você seleciona ao abrir). Não há
  arquivo para editar — há hábito a criar.

No fluxo por artefato, isso significa: **só três agentes precisam de `model:`** — `builder`,
`qa-blind` e `explore`. `planner`, `code-reviewer` e `security-reviewer` rodam no agy e não
têm configuração nenhuma no kit.

## A regra econômica

> **Volume de saída → modelo barato. Entrada grande + julgamento → modelo de fronteira.**

O custo de uma etapa é dominado por quem **produz** token:

| Etapa | Perfil de token | Tier ideal |
|---|---|---|
| Planejar | saída média, julgamento alto | **fronteira** |
| Implementar (código + testes) | **saída alta**, julgamento médio | **barato** |
| Rodar e ler saída de teste | entrada média, julgamento baixo | **barato** |
| Review adversarial | **entrada alta** (plano + diff), julgamento alto | **fronteira** |
| Security review | entrada alta, julgamento alto em autorização | **fronteira** |

Por isso o arranjo "planeja caro, executa barato, revisa caro" é o economicamente correto —
não é só preferência.

## Mapeamento recomendado

### Lado OpenCode (configuração)

| Agente | Tier | Sugestão (confirmar id em `/models`) | Por quê |
|---|---|---|---|
| `builder` | barato/rápido | `opencode-go/deepseek-v4.1-flash` | é saída de código, o maior volume da sessão |
| `qa-blind` | barato | mesmo do builder | executa comando e lê saída; não julga arquitetura |
| `explore` | barato | mesmo do builder | varredura de arquivos, devolve resumo |
| `planner` | — | não usado neste fluxo | planeja no agy |
| `code-reviewer` | — | não usado neste fluxo | revisa no agy |
| `security-reviewer` | — | não usado neste fluxo | revisa no agy |

Se você optar por rodar review **dentro** do OpenCode (fluxo de uma janela só), aí sim:
`code-reviewer` e `security-reviewer` recebem o modelo mais forte da assinatura e,
idealmente, de **outra família** que a do `builder`.

### Lado Antigravity (escolha de sessão)

| Sessão | Tier | Critério |
|---|---|---|
| Plano | o mais forte disponível | é onde erro custa mais caro, e a saída é curta |
| Review adversarial | o mais forte disponível | entrada grande + julgamento; é o gate de qualidade |
| Crítica do plano (se fizer) | médio já basta | revisar um plano é mais barato que escrevê-lo |

### Pano de fundo

```jsonc
// no opencode.json — evita cair num default remoto
"small_model": "opencode-go/<barato>"
```

## Política de escalonamento (importante)

Modelo barato no `builder` erra de um jeito específico: repete o mesmo erro de compilação,
"conserta" quebrando outro teste, ou inventa API que não existe. A regra que evita queimar
ciclos:

1. **Mesmo erro no gate duas vezes** → não insista no terceiro ciclo com o mesmo modelo.
   Escale **aquela correção** para o modelo forte e mantenha o barato no resto.
2. **Falha de compilação** é sinal de tier baixo demais para o contexto, não de plano ruim.
3. **Falha de comportamento** (teste passa, comportamento errado) é sinal de plano ruim —
   volte ao planejamento, não ao executor.

## Revisão só quando paga

Rodar review adversarial em toda mudança é caro e vira ruído. Filtro prático:

| Tamanho da mudança | Review |
|---|---|
| < ~50 linhas de diff, sem tocar auth/query/config | gate + você lendo o diff |
| ~50–300 linhas | review adversarial em 1 rodada |
| > 300 linhas, ou toca segurança/dinheiro/migração | review adversarial + security, obrigatório |

## Como fixar (quando tiver os ids)

```yaml
# global/agents/builder.md
mode: subagent
model: opencode-go/deepseek-v4.1-flash

# global/agents/qa-blind.md
mode: subagent
model: opencode-go/deepseek-v4.1-flash
```

Um `model` com id inexistente faz o agente falhar — por isso os campos vêm comentados no
kit e a confirmação é `opencode` → `/models`.
