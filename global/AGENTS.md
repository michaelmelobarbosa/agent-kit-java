# Convenções globais — Java / Spring Boot

Vale para **todo** projeto Java neste ambiente. Regra específica de repositório vive no
`AGENTS.md` do projeto e sobrescreve esta.

## Idioma

- Código, nomes de classe, método, commit e comentário técnico: **inglês**.
- Explicação para o usuário e mensagem de erro de negócio: **português**.

## Java

- **Java 17+ como piso**; use o que o `pom.xml`/`build.gradle` declarar, nunca migre por conta própria.
- `record` para DTO e value object imutável. Classe só quando há estado mutável.
- **Injeção por construtor**, campo `final`. `@Autowired` em campo é proibido.
- `Optional` para retorno que pode ser vazio; `null` não é contrato.
- Exceção de negócio é classe própria, com mensagem para o usuário final. `RuntimeException` genérica não.
- Sem `System.out` / `printStackTrace`. Use o logger da aplicação.
- `var` só quando o tipo está óbvio na mesma linha.
- Stream quando cabe em uma expressão legível; loop quando o stream vira monolito.

## Spring

- Controller **só** orquestra: recebe DTO, chama service, devolve DTO. Regra de negócio no service.
- Entidade JPA nunca é corpo de resposta. Sempre DTO de saída.
- `@Transactional` no service, nunca no controller; e só onde há escrita ou leitura que precisa de consistência.
- Validação de entrada com Bean Validation no DTO, não com `if` no service.
- `@RestControllerAdvice` centraliza erro. Exceção vazando para o cliente é bug.
- Configuração por `@ConfigurationProperties`, não `@Value` espalhado.
- Nada de `ddl-auto: update` em código que vai para produção. Migração é Flyway.

## Banco

- Migração versionada: `V<timestamp>__<descricao>.sql`. Migração aplicada **nunca** é editada — cria-se outra.
- Índice para coluna de filtro e de FK. Sem índice "depois, se precisar".
- Repository não vaza para controller.

## Testes

- JUnit 5 + AssertJ + Mockito. Um comportamento por teste.
- Nome do teste diz o comportamento: `deve_retornar_404_quando_atleta_nao_existe`.
- Teste unitário não sobe contexto Spring. `@SpringBootTest` só para integração real.
- Sem `Thread.sleep`, sem dependência de ordem, sem estado compartilhado entre testes.
- Teste que não falha quando o código quebra não é teste.

## Qualidade e gate

- O gate do ambiente é `~/.config/opencode/scripts/agent-gate.sh` (ou `agent-gate.ps1`).
  Em repo com `.agent-gate.sh` na raiz, esse script tem precedência.
- Nenhum agente faz `git commit`, `git push` ou `git add`. Isso é do humano.
- Não adicione dependência sem pedir. Não desabilite regra de lint/checkstyle para "passar".

## Como agentes trabalham aqui

1. Feature não trivial começa no `planner`, com plano em `.opencode/plans/`.
2. Implementação é do `builder`, teste antes do código (skill `tdd-java`).
3. Antes do commit: `code-reviewer` (código/plano) e `qa-blind` (comportamento contra a
   spec). Mudança que toca controller, query, auth, config ou dependência também passa
   pelo `security-reviewer`.
4. Veredito REWORK volta para o `builder`. Três ciclos sem ACCEPT → escala para o humano.
