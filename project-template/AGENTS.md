# AGENTS.md — <nome-do-projeto>

Específico deste repositório. O que é universal de Java/Spring já está no global
(`~/.config/opencode/AGENTS.md`) — não repita aqui.

## Build e gate

- Build: Maven (`./mvnw` disponível: sim/não)
- Gate do projeto: `.agent-gate.sh` (se existir) ou o global
- Testes: `mvn -q test` · classe única: `mvn -q test -Dtest=<Classe>`
- Base de dados de teste: <H2 / Testcontainers / MySQL local>

## Mapa do código

| Pacote | Responsabilidade |
|---|---|
| `br.com.<org>.<app>.<dominio>` | controller / service / repository / dto do domínio |
| `...common` | config, segurança, exceção, util |
| `...integration` | cliente externo |

Regra de dependência: `controller → service → repository`. Nunca o contrário, nunca
repository no controller.

## Convenções locais

- Migrações em `src/main/resources/db/migration`, padrão `V<timestamp>__<nome>.sql`.
- <regra de negócio que vale sempre: ex. "todo atleta pertence a exatamente uma modalidade">
- <o que é proibido neste repo: ex. "não adicionar dependência sem abrir issue">

## Comandos úteis

```bash
<mvnw> spring-boot:run          # subir local
<mvnw> -q -DskipITs verify      # gate
```

## Fora de escopo para agentes

- Não alterar `pom.xml` (versão de dependência) sem aprovação humana.
- Não tocar em `<diretório sensível: scripts de deploy, CI, etc.>` sem pedir.
- Não reescrever histórico git.
