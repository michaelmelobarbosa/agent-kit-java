# <feature>

<!--
Contrato de plano. Quem escreve pode ser o planner do OpenCode, o agy, ou você.
Quem lê é o builder — e ele depende destas seções. O que faltar, ele para e pede.
Apague os comentários ao preencher.
-->

## Contexto
Por que isso existe. 2–4 linhas. Sem adjetivo, sem "vale ressaltar".

## Contrato
O que entra, o que sai, o que acontece em erro. Endpoints, DTOs, status HTTP.
Em mudança interna: o antes/depois do comportamento observável.

## Arquivos que podem ser tocados
Lista fechada — o builder não sai daqui sem justificar.

- `src/main/java/...`
- `src/test/java/...`

## Passos
1. **Teste que falha** — o que ele prova · verificação: `mvn -q test -Dtest=<Classe>`
2. **Implementação mínima** · verificação: mesmo comando, agora verde
3. **Refatoração permitida** (opcional) · verificação: `mvn -q -DskipITs verify`

## Critérios de aceite
Verificáveis por comando ou teste. "Funciona bem" não é critério.

- [ ] `GET /recurso/{id}` existente retorna 200 com o corpo esperado
- [ ] id inexistente retorna 404 com a mensagem padrão
- [ ] `mvn -q -DskipITs verify` passa

## Riscos
O que pode quebrar e o que fazer se quebrar.

## Fora de escopo
O que este plano deliberadamente não faz.
