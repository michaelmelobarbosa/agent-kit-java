---
name: tdd-java
description: Escreve teste que falha antes do código, em projeto Java com Maven/Gradle e JUnit 5. Use ao implementar qualquer comportamento novo, corrigir bug ou mexer em regra existente.
---

# TDD em Java

RED → GREEN → REFACTOR, com o comando de verificação em cada passo. Não é cerimônia: é
o único mecanismo que prova que o teste testa alguma coisa.

## Passo 0 — localizar o alvo

```bash
ls pom.xml build.gradle 2>/dev/null          # qual build tool
rg -l "class .*Test" src/test | head         # padrão de teste já usado
rg "junit-jupiter|assertj|mockito" pom.xml   # o que já está no projeto
```

Use o que o projeto já tem. **Não adicione dependência de teste** sem pedir.

## Passo 1 — RED (o teste falha pelo motivo certo)

Escreva o teste antes da implementação e rode:

```bash
mvn -q test -Dtest=NomeDaClasseTest
# ou
./mvnw -q test -Dtest=NomeDaClasseTest
```

O teste **tem** que falhar. Se passou de primeira, uma destas três coisas aconteceu:

1. o comportamento já existia — então não havia o que implementar;
2. o teste não exercita o caminho real (mock no lugar errado, asserção fraca);
3. você escreveu implementação antes do teste — apague-a e volte.

Confirme que a falha é a esperada: `Expected X but was Y`, não `NullPointerException`
em setup. Falha por erro de compilação **não conta** como RED válido.

Teste de bug: o primeiro teste é o que **reproduz** o bug relatado, e ele falha antes da
correção. Sem isso, você não sabe se consertou.

## Passo 2 — GREEN (o mínimo)

Implemente só o necessário para aquele teste passar. Rode de novo:

```bash
mvn -q test -Dtest=NomeDaClasseTest
```

Agora sim, verde. Não aproveite para "já que estou aqui": código não pedido por teste vai
em outro passo, com o próprio teste.

## Passo 3 — REFACTOR (com a rede no lugar)

Refatore sabendo que o verde é sua proteção. Rode a classe de novo depois. Refatoração que
exige mudar asserção é mudança de comportamento, não refatoração — volte ao passo 1.

## Passo 4 — suíte inteira

```bash
mvn -q -DskipITs verify
```

Teste que passa sozinho e quebra na suíte é acoplamento escondido (estado estático, banco
compartilhado, ordem). Conserte a causa, não a ordem do teste.

## Formato do teste

```java
@Test
@DisplayName("deve retornar 404 quando o atleta não existe")
void deve_retornar_404_quando_atleta_nao_existe() {
    // arrange — o estado mínimo
    // act     — uma chamada
    // assert  — o comportamento observável
}
```

## Regras que evitam teste de mentira

- **Uma asserção de comportamento por teste.** Várias asserções do mesmo comportamento, ok.
- **`assertThat(...).isEqualTo(...)`** (AssertJ) em vez de `assertEquals` quando a mensagem
  de falha importa.
- **Proibido**: `assertTrue(true)`, `@Disabled` sem ticket, catch vazio, `Thread.sleep`,
  teste que depende de ordem ou de dado deixado por outro teste.
- **Mock é para a borda** (repositório, cliente HTTP, clock). Se você mocka o próprio
  objeto que está testando, o teste não testa nada.
- **Teste de integração** (`@SpringBootTest`) só quando o que se quer provar é a cola:
  query, transação, serialização, segurança. Regra de negócio se prova sem Spring.
- **Nome** descreve o comportamento, não o método: `deve_rejeitar_cpf_duplicado`, não
  `testSalvar2`.

## Quando o teste é difícil de escrever

Teste difícil é diagnóstico, não obstáculo: significa acoplamento alto ou dependência
escondida. Conserte o desenho — injeção de `Clock`, extração de colaborador, interface na
borda — em vez de testar por reflexão ou pular.

Referência detalhada do stack: `references/junit5-stack.md`.
