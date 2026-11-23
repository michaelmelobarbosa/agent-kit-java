# Stack de teste — JUnit 5 · AssertJ · Mockito

## Dependências (já presentes em projeto Spring Boot)

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-test</artifactId>
  <scope>test</scope>
</dependency>
```

Traz JUnit 5, AssertJ, Mockito, Hamcrest, JSONassert, Spring Test.

## Unitário puro (sem Spring)

```java
@ExtendWith(MockitoExtension.class)
class AtletaServiceTest {

    @Mock AtletaRepository repository;
    @InjectMocks AtletaService service;

    @Test
    void deve_lancar_excecao_quando_cpf_ja_existe() {
        var existente = AtletaFixture.valido();
        when(repository.findByCpf(existente.getCpf())).thenReturn(Optional.of(existente));

        assertThatThrownBy(() -> service.criar(AtletaFixture.novo()))
            .isInstanceOf(CpfDuplicadoException.class)
            .hasMessageContaining("CPF");
    }
}
```

`@Mock` + `@InjectMocks` para o alvo; `when/thenReturn` para stub; **`verify`** só quando
a interação é o comportamento (ex.: garantiu que não salvou).

## Integração de fatia (mais rápido que `@SpringBootTest` inteiro)

```java
@WebMvcTest(AtletaController.class)
class AtletaControllerTest { ... }          // só a camada web, service mockado

@DataJpaTest
class AtletaRepositoryTest { ... }          // só JPA, H2, transação revertida

@SpringBootTest(webEnvironment = RANDOM_PORT)
class FluxoAtletaIT { ... }                 // integração real — use com parcimônia
```

## Asserções que dão bom diagnóstico

```java
assertThat(resultado)
    .extracting(AtletaDTO::nome)
    .isEqualTo("Michael");

assertThat(lista).hasSize(3).extracting(AtletaDTO::id).containsExactly(1L, 2L, 3L);

assertThatThrownBy(() -> service.buscar(99L))
    .isInstanceOf(AtletaNaoEncontradoException.class);
```

Prefira encadeado e específico a `isTrue()`/`isNotNull()`. Mensagem de falha é o que você
vai ler às 23h.

## Tempo e aleatoriedade

```java
class ServicoTest {
    private final Clock clock = Clock.fixed(Instant.parse("2026-11-22T12:00:00Z"), ZoneOffset.UTC);
}
```

`LocalDate.now()` / `Instant.now()` direto no código é o que torna teste instável. Injete
`Clock`. Para id/aleatório, injete gerador; não mocke estático se puder desenhar melhor.

## Segurança em teste

```java
@WithMockUser(roles = "ADMIN")
@Test void deve_permitir_admin() { ... }
```

Teste de autorização é requisito, não extra: um endpoint novo sem teste de "usuário sem
permissão recebe 403" é uma porta sem tranca.

## Comandos

```bash
mvn -q test                                  # tudo unitário
mvn -q test -Dtest=AtletaServiceTest         # uma classe
mvn -q test -Dtest=AtletaServiceTest#deve_x  # um método
mvn -q -DskipITs verify                      # gate (unitário + checks estáticos)
mvn -q verify -Pit                           # mutação, se o perfil existir
```

`-DfailIfNoTests=false` quando filtrar por nome e a classe ainda não existir (fase RED).
