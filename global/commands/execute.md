---
description: Executa um plano que já existe em .opencode/plans/ — pula o planejamento e vai direto para implementação, gate e revisão. Use quando o plano veio de outra ferramenta (Antigravity, ChatGPT, um colega) ou de uma sessão anterior.
---

Plano: $ARGUMENTS

Se nenhum caminho foi informado, liste os arquivos em `.opencode/plans/` (mais recentes
primeiro) e pergunte qual usar. Nunca invente um plano.

## 0. Conferir o contrato antes de executar
Leia o plano e verifique se ele tem as seções mínimas:

- **Arquivos que podem ser tocados** (lista fechada)
- **Passos** com o comando de verificação de cada um
- **Critérios de aceite** verificáveis por comando ou teste

Faltando alguma, **pare** e diga exatamente o que falta — um plano sem critério de aceite
não tem como ser aceito no fim. Ofereça completar a seção a partir do que está escrito,
e aguarde confirmação.

## 1. Implementar
Invoque `builder` com o caminho do plano. Ele carrega a skill `tdd-java`, escreve o teste
que falha, implementa o mínimo e roda o gate.

## 2. Verificar
- gate determinístico (o builder já roda; confirme a saída)
- `code-reviewer` no diff
- `qa-blind` contra os critérios de aceite
- `security-reviewer` se tocar controller, query, auth, config ou dependência

## 3. Corrigir (máx. 3 ciclos)
REWORK ou NOT READY → devolve os must-fixes ao `builder`, que corrige e roda o gate de
novo. No 3º ciclo sem ACCEPT, pare e escale para mim com a hipótese de causa raiz.

## 4. Entrega
Plano usado · arquivos tocados · gate (comando e saída) · vereditos · o que eu preciso
decidir antes do commit.

Não faça commit nem push.
