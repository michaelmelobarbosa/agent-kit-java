---
description: Inicia uma feature no fluxo completo — plano, aprovação, implementação, gate, review.
---

Feature: $ARGUMENTS

Execute o fluxo abaixo **na ordem**, parando nos pontos marcados como gate.

## 1. Plano (agora)
Invoque o agente `planner` passando a descrição acima. Ele deve:
- investigar o repositório antes de perguntar;
- fazer no máximo 3 perguntas, cada uma com recomendação;
- escrever o plano em `.opencode/plans/`.

Depois peça ao `code-reviewer` para criticar o plano (escopo, critério de aceite
verificável, risco não tratado) e faça o planner incorporar.

**PARE AQUI.** Mostre o caminho do plano e as must-fixes que sobraram. Aguarde meu "ok".

## 2. Implementação (só depois do meu ok)
Invoque `builder` com o caminho do plano. Ele carrega a skill `tdd-java`, escreve o teste
que falha, implementa, e roda o gate.

## 3. Verificação (automático, em sequência)
- `code-reviewer` no diff → ACCEPT ou REWORK.
- `qa-blind` contra os critérios de aceite do plano → READY ou NOT READY.
- `security-reviewer` **se** o plano tocar controller, query, autenticação, configuração ou dependência.

## 4. Ciclo de correção (automático, limite 3)
REWORK ou NOT READY → devolva os must-fixes ao `builder`, que corrige e roda o gate de
novo. Repita até ACCEPT ou até o 3º ciclo.

No 3º ciclo sem ACCEPT, **pare** e me mostre: o que o builder tentou, o must-fix que
persiste, e sua hipótese da causa raiz. Não tente um 4º ciclo sozinho.

## 5. Entrega
Relatório final, nesta ordem:
1. Plano (caminho) e desvios aceitos.
2. Arquivos tocados.
3. Gate: comando e saída literal.
4. Veredito do reviewer e do QA.
5. O que eu preciso decidir antes do commit.

**Não faça commit nem push.** O merge é meu.
