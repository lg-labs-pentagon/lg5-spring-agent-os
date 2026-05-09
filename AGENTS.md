# AGENTS.md — lg5-spring workspace

This workspace builds microservices on top of the **lg5-spring** framework
(https://github.com/lg-labs-pentagon/lg5-spring) following its hexagonal/DDD/SAGA/Outbox/Kafka conventions.

> This file is the **upstream template**. Consumer repositories that install
> this bundle should copy or merge these rules into their own root-level
> `AGENTS.md`. The skill routing table below assumes skills are installed at
> `.opencode/skills/<name>/` in the consumer repo (the default target of
> `scripts/install-skills.sh`). Adjust the path if your agent expects a
> different location (e.g. `.cursor/rules/`, `.continue/`).

When the user asks anything related to lg5-spring, building services, sagas, outbox, kafka producers/consumers, acceptance tests, or generating new modules, **load the relevant skill first**:

| Topic | Skill to load |
|---|---|
| Overview, module map, recent changes, conventions | `lg5-spring-overview` |
| Scaffolding a brand-new microservice from `blank-service` | `lg5-new-service` |
| Implementing a `SagaStep` orchestration | `lg5-saga` |
| Implementing the Transactional Outbox + scheduler | `lg5-outbox` |
| Kafka producer/consumer + Avro schemas | `lg5-kafka-avro` |
| Acceptance tests (Cucumber + Testcontainers + Wiremock) | `lg5-atdd` |

## Hard rules (always apply)

1. **Stack baseline**: Spring Boot **3.4.2**, Spring Framework **6.2.2**, **JDK 21**, Kotlin **21**, Gradle (framework) / Maven (services). Never propose lower versions.
2. **Parent**: every consumer service inherits from
   ```xml
   <parent>
     <groupId>com.lg5.spring</groupId>
     <artifactId>lg5-spring-parent</artifactId>
     <version>1.0.0-alpha.<git-sha-of-framework></version>
   </parent>
   ```
   The version suffix is the **short git SHA** of the framework commit being consumed. Never invent a version; pull the latest known SHA from the framework repo.
3. **Architecture**: Hexagonal (ports & adapters) + DDD. Domain logic stays in `<svc>-domain-core` and depends on **nothing Spring**. Spring annotations belong in adapters / application-service / container.
4. **Service module shape** (mirror `blank-service`):
   ```
   <svc>-domain/{<svc>-domain-core, <svc>-application-service}
   <svc>-api
   <svc>-data-access
   <svc>-message/{<svc>-message-core, <svc>-message-model}
   <svc>-external          (optional: Feign clients)
   <svc>-container         (only place with @SpringBootApplication + application.yaml)
   <svc>-acceptance-test
   <svc>-support           (docker-compose for local infra)
   ```
5. **No custom framework annotations**: lg5-spring does **not** ship `@LgController` / `@ApplicationService` / etc. Use stock Spring (`@RestController`, `@Component`, `@Configuration`, `@Transactional`, `@Scheduled`, `@KafkaListener`) + Lombok (`@Slf4j`, `@Getter`, `@Setter`, `@Builder`).
6. **REST**: controllers must produce `application/vnd.api.v1+json`.
7. **Kafka payloads must be Avro-typed**: every producer/consumer is generic over `V extends SpecificRecordBase`. Schemas live in `<svc>-message-model/src/main/resources/avro/*.avsc`. Regenerate with `make run-avro-model` (or `make run-kafka-model` in food-ordering-system).
8. **Outbox pattern is mandatory** for every domain event that crosses a service boundary. Outbox JPA entities **must** carry `@Version` (optimistic locking) and an `OutboxStatus` enum field (`STARTED|COMPLETED|FAILED`).
9. **Saga steps**: implement `com.lg5.spring.saga.SagaStep<T>`. Mark the bean `@Component`; `process` and `rollback` are `@Transactional`. Always make them **idempotent** by querying the outbox by `(sagaId, SagaStatus.STARTED)` and returning early if absent.
10. **Kafka listeners** are batch by default (`batch-listener: true`). Catch `OptimisticLockingFailureException` and not-found exceptions as **NO-OP** (do not rethrow) to prevent Kafka redelivery loops.
11. **Outbox schedulers**: implement `com.lg5.spring.outbox.OutboxScheduler`, annotate with `@Scheduled(fixedDelayString = "${<svc>.outbox-scheduler-fixed-rate}")` and gate with `@ConditionalOnProperty(value = "scheduling.enabled", matchIfMissing = true)`.
12. **Test profiles**: integration & ATDD always run with `@ActiveProfiles({"test","local"})`. Extend `Lg5TestBoot` (random port + RestAssured) or `Lg5TestBootPortNone` (NONE web env).
13. **Testcontainers are opt-in**: each `*ContainerCustomConfig` is gated by `testcontainers.<name>.enabled`. The convention is to `@Import(TestContainersLoader.class)` in ATDD `CucumberHooks` extending `Lg5TestBootPortNone`.
14. **Configuration prefixes**:
    - `kafka-config.*`, `kafka-producer-config.*`, `kafka-consumer-config.*` (framework)
    - `<svc>-service.*` (per-service business config)
    - `testcontainers.<name>.enabled`, `application.image.name`, `application.traces.{console,file}.enabled` (ATDD)
    - `third.basic.auth.{username,password}` (Feign basic auth)
15. **Style**:
    - `final` on locals & method parameters by default.
    - Records for DTOs (`ErrorDTO`, `*Command`, `*Response`).
    - Kotlin only for stateless interfaces and `@ConfigurationProperties`.
    - Package layout per concern: `dto/`, `entity/`, `mapper/`, `event/`, `exception/`, `ports/{input,output}/...`, `outbox/{model,scheduler}`, `saga/`.
16. **DDD building blocks** (`AggregateRoot`, `BaseEntity`, `BaseId`, `Money`, `DomainEvent`) come from the **external** `com.labs.lg.pentagon:ddd-common-domain` library, re-exported by `lg5-common-domain`. They are not in the lg5-spring repo.
17. **Build commands** (always prefer Make targets):
    - Framework: `make all-build`, `make publish-local`
    - Service: `make install-skip-test`, `make run-avro-model`, `make docker-up`, `make run-apps`, `make run-acceptance-test`
18. **Reference projects** (clone if missing under `/tmp/lg5-study/`):
    - Framework: https://github.com/lg-labs-pentagon/lg5-spring
    - Real example: https://github.com/lg-labs/food-ordering-system
    - Skeleton: https://github.com/lg-labs/blank-service

## When uncertain

- Cite the canonical source: framework path inside `/tmp/lg5-study/lg5-spring/...` or the real example under `/tmp/lg5-study/food-ordering-system/...`.
- Prefer copying patterns from `food-ordering-system/order-service` (the most complete example: REST + JPA + Kafka producer/consumer + Saga + Outbox + ATDD).
- Never invent framework classes. If a class isn't in the skill files or the cloned repos, say so explicitly.
