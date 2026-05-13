---
description: Add a JPA aggregate (root) to an lg5-spring service — domain entity + value-object id + repository port + JPA entity + Spring Data repo + adapter + MapStruct mapper + Liquibase changelog + integration test. Idiomatic per RULE-003/004/015/016.
argument-hint: <service-name> <aggregate-name> <field-spec> [<field-spec>...]
allowed-tools: bash, read, write, edit, glob, grep
---

# /add-jpa-entity

You are creating a brand-new persistent aggregate (root) in an existing
lg5-spring service. This produces the full data-layer stack: domain
aggregate root (Spring-free per RULE-003), a value-object `<Aggregate>Id`
extending `BaseId<UUID>` (RULE-016), an outbound port `<Aggregate>Repository`,
the JPA entity, a `JpaRepository`, the hexagonal adapter, the MapStruct
mapper, and a Liquibase changelog. **Do NOT invent framework classes.**
If a class isn't in `blank-service`, say so explicitly and stop (RULE-018).

This command is typically the **first** step when starting a new aggregate
— follow it with `/add-rest-endpoint` for the HTTP surface and/or
`/add-saga` if the aggregate participates in a saga.

## Inputs

- `<service-name>` — the existing service (e.g., `blank`, `order`, `loyalty`).
- `<aggregate-name>` — CamelCase aggregate root name (e.g., `Customer`,
  `LoyaltyAccount`). Must be unique within the service.
- `<field-spec>` — repeatable. Format: `<name>:<type>[:<constraint>]`.
  Supported `<type>`: `String`, `UUID`, `Long`, `Integer`, `BigDecimal`,
  `Instant`, `LocalDate`, `Boolean`. Supported `<constraint>`: `notnull`,
  `unique`. Example: `name:String:notnull email:String:unique,notnull
  createdAt:Instant:notnull`.

If the user provided fewer arguments than required, ask for the missing
ones BEFORE writing any file. Specifically: refuse to proceed without at
least one `<field-spec>` (an empty aggregate is a smell — even
`blank-service` `Blank.java:7` only persists the id but the user must
opt-in to that explicitly).

## Pre-flight checks

1. **Service shape**: confirm the canonical Maven module tree exists per
   RULE-004 (see `/add-rest-endpoint` pre-flight 1 for the full list).
   Required for this command:
   `<svc>-domain/<svc>-domain-core`, `<svc>-domain/<svc>-application-service`,
   `<svc>-data-access`, `<svc>-container`.
2. **Aggregate uniqueness**: grep for an existing `<Aggregate>.java` under
   `<svc>-domain/<svc>-domain-core/.../domain/entity/`. If found, stop and
   ask whether to modify it instead.
3. **Liquibase setup**: confirm
   `<svc>-data-access/src/main/resources/db/changelog/db.changelog-master.yaml`
   exists. If not, the service does not use Liquibase — stop and ask the
   user to clarify (Flyway is **not** supported by this command).
4. **Schema name**: read the existing
   `db.changelog-master.yaml` + included `ddl-v.0.0.*.yaml` files to detect
   the service's schema name (e.g., `blank` for `blank-service` —
   evidence: `blank-data-access:ddl-v.0.0.1.yaml:7`). Reuse it. Do not
   create a new schema unless the user explicitly asks.
5. **Next changelog version**: scan
   `<svc>-data-access/src/main/resources/db/changelog/ddl-v.*.yaml`,
   pick the highest existing version (e.g., `v.0.0.3`), and use the next
   patch (e.g., `v.0.0.4`).

## What you will create / modify

| File | Module | Action |
|---|---|---|
| `<Aggregate>.java` | `<svc>-domain/<svc>-domain-core/.../domain/entity/` | **create** — `extends AggregateRoot<<Aggregate>Id>`, Spring-free |
| `<Aggregate>Id.java` | `<svc>-domain/<svc>-domain-core/.../domain/valueobject/` | **create** — `extends BaseId<UUID>` (RULE-016) |
| `<Aggregate>DomainException.java` | `<svc>-domain/<svc>-domain-core/.../domain/exception/` | **create** if no existing service-level exception fits — otherwise reuse |
| `<Aggregate>Repository.java` | `<svc>-domain/<svc>-application-service/.../domain/ports/output/repository/` | **create** — output port interface |
| `<Aggregate>Entity.java` | `<svc>-data-access/.../data/entity/` | **create** — `@Entity`, `@Table(schema=…)`, Lombok `@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor` |
| `<Aggregate>JPARepository.java` | `<svc>-data-access/.../data/repository/` | **create** — `extends JpaRepository<<Aggregate>Entity, UUID>` |
| `<Aggregate>RepositoryImpl.java` | `<svc>-data-access/.../data/adapter/` | **create** — `@Component`, implements port, delegates to JPA repo + mapper |
| `<Aggregate>DataAccessMapper.java` | `<svc>-data-access/.../data/mapper/` | **create** — `@Mapper(componentModel = "spring")` |
| `ddl-v.0.0.<next>.yaml` | `<svc>-data-access/src/main/resources/db/changelog/` | **create** — Liquibase changeset for the new table |
| `db.changelog-master.yaml` | same dir | **modify** — append `- include: { file: db/changelog/ddl-v.0.0.<next>.yaml }` |
| `<Aggregate>RepositoryIT.java` | `<svc>-container/src/test/java/.../container/data/` | **create** — extends `Bootstrap`, asserts save+findById round-trip |

## Steps

For each step, write **one file at a time** and verify before moving on.

### Step 1 — Value-object id (`<Aggregate>Id.java`)

Real evidence: `blank-service:BlankId.java:7-10`.

```java
package <base>.<svc>.service.domain.valueobject;

import com.labs.lg.pentagon.common.domain.valueobject.BaseId;
import java.util.UUID;

public class <Aggregate>Id extends BaseId<UUID> {
    public <Aggregate>Id(UUID value) {
        super(value);
    }
}
```

Per RULE-016 the `BaseId<T>` class comes from `ddd-common-domain` (re-exported
by `lg5-common-domain`). Do NOT redefine it.

### Step 2 — Domain entity (`<Aggregate>.java`)

Real evidence: `blank-service:Blank.java:7-22`. Spring-free (RULE-003).
Constructor sets the id via `super.setId(...)`. Add `validate()` that
throws `<Aggregate>DomainException` on invalid state. Per-field setters
are NOT exposed on the aggregate — mutations go through behavior methods.

```java
package <base>.<svc>.service.domain.entity;

import <base>.<svc>.service.domain.exception.<Aggregate>DomainException;
import <base>.<svc>.service.domain.valueobject.<Aggregate>Id;
import com.labs.lg.pentagon.common.domain.entity.AggregateRoot;

public class <Aggregate> extends AggregateRoot<<Aggregate>Id> {
    private final <Type1> <field1>;
    // ... one final field per <field-spec>

    public <Aggregate>(<Aggregate>Id id, <Type1> <field1>, ...) {
        super.setId(id);
        this.<field1> = <field1>;
    }

    public <Type1> get<Field1>() { return <field1>; }
    // ... one getter per field; NO setters

    public void validate() {
        if (getId() == null) {
            throw new <Aggregate>DomainException("The <Aggregate> is invalid");
        }
        // for each <notnull> field, add a null check
    }
}
```

### Step 3 — Domain exception (`<Aggregate>DomainException.java`)

If the service already has a `<Svc>DomainException` you may reuse it.
Otherwise:

```java
package <base>.<svc>.service.domain.exception;

import com.labs.lg.pentagon.common.domain.exception.DomainException;

public class <Aggregate>DomainException extends DomainException {
    public <Aggregate>DomainException(String message) { super(message); }
    public <Aggregate>DomainException(String message, Throwable cause) { super(message, cause); }
}
```

### Step 4 — Output port (`<Aggregate>Repository.java`)

Real evidence: `blank-service:BlankRepository.java:8-13`.

```java
package <base>.<svc>.service.domain.ports.output.repository;

import <base>.<svc>.service.domain.entity.<Aggregate>;
import java.util.Optional;
import java.util.UUID;

public interface <Aggregate>Repository {
    <Aggregate> create<Aggregate>(<Aggregate> <aggregate>);
    Optional<<Aggregate>> findById(UUID <aggregate>Id);
}
```

Add additional finders only on explicit user request — do not speculate.

### Step 5 — JPA entity (`<Aggregate>Entity.java`)

Real evidence: `blank-service:BlankEntity.java:14-23`. Lombok-driven, no
JPA relationships in v4.2.0 scope.

```java
package <base>.<svc>.service.data.entity;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;
// + java.math.BigDecimal, java.time.Instant etc. as needed per <field-spec>

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "<aggregate-snake-case>", schema = "<schema>")
@Entity
public class <Aggregate>Entity {
    @Id
    private UUID id;

    @Column(name = "<field1-snake>", nullable = <true|false>, unique = <true|false>)
    private <Type1> <field1>;
    // ... one @Column per <field-spec>
}
```

Translate the `<field-spec>` types to JPA columns:
- `String` → `VARCHAR(255)` (or `TEXT` if user specifies `:long`)
- `UUID` → `UUID`
- `Long/Integer` → `BIGINT/INTEGER`
- `BigDecimal` → `NUMERIC(19,4)` (default; user can override later)
- `Instant` → `TIMESTAMP WITH TIME ZONE`
- `LocalDate` → `DATE`
- `Boolean` → `BOOLEAN`

### Step 6 — Spring Data JPA repository (`<Aggregate>JPARepository.java`)

Real evidence: `blank-service:BlankJPARepository.java:9-11`.

```java
package <base>.<svc>.service.data.repository;

import <base>.<svc>.service.data.entity.<Aggregate>Entity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.UUID;

@Repository
public interface <Aggregate>JPARepository extends JpaRepository<<Aggregate>Entity, UUID> {
}
```

### Step 7 — Hexagonal adapter (`<Aggregate>RepositoryImpl.java`)

Real evidence: `blank-service:BlankRepositoryImpl.java:12-33`.

```java
package <base>.<svc>.service.data.adapter;

import <base>.<svc>.service.data.mapper.<Aggregate>DataAccessMapper;
import <base>.<svc>.service.data.repository.<Aggregate>JPARepository;
import <base>.<svc>.service.domain.entity.<Aggregate>;
import <base>.<svc>.service.domain.ports.output.repository.<Aggregate>Repository;
import org.springframework.stereotype.Component;
import java.util.Optional;
import java.util.UUID;

@Component
public class <Aggregate>RepositoryImpl implements <Aggregate>Repository {
    private final <Aggregate>JPARepository repository;
    private final <Aggregate>DataAccessMapper <aggregate>DataAccessMapper;

    public <Aggregate>RepositoryImpl(<Aggregate>JPARepository repository,
                                     <Aggregate>DataAccessMapper <aggregate>DataAccessMapper) {
        this.repository = repository;
        this.<aggregate>DataAccessMapper = <aggregate>DataAccessMapper;
    }

    @Override
    public <Aggregate> create<Aggregate>(<Aggregate> <aggregate>) {
        return <aggregate>DataAccessMapper.<aggregate>EntityTo<Aggregate>(
                repository.save(<aggregate>DataAccessMapper.<aggregate>To<Aggregate>Entity(<aggregate>)));
    }

    @Override
    public Optional<<Aggregate>> findById(UUID <aggregate>Id) {
        return repository.findById(<aggregate>Id)
                .map(<aggregate>DataAccessMapper::<aggregate>EntityTo<Aggregate>);
    }
}
```

### Step 8 — MapStruct mapper (`<Aggregate>DataAccessMapper.java`)

Real evidence: `blank-service:BlankDataAccessMapper.java:12-22`. The
`default <Aggregate>Id map(UUID value)` is what unwraps the VO on read.

```java
package <base>.<svc>.service.data.mapper;

import <base>.<svc>.service.data.entity.<Aggregate>Entity;
import <base>.<svc>.service.domain.entity.<Aggregate>;
import <base>.<svc>.service.domain.valueobject.<Aggregate>Id;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import java.util.UUID;

@Mapper(componentModel = "spring")
public interface <Aggregate>DataAccessMapper {

    <Aggregate> <aggregate>EntityTo<Aggregate>(<Aggregate>Entity entity);

    @Mapping(target = "id", source = "<aggregate>.id.value")
    <Aggregate>Entity <aggregate>To<Aggregate>Entity(<Aggregate> <aggregate>);

    default <Aggregate>Id map(UUID value) {
        return new <Aggregate>Id(value);
    }
}
```

For each non-id field, MapStruct will auto-wire by name match between the
domain entity getter and the JPA `@Setter`. No extra `@Mapping` needed
unless field names differ.

### Step 9 — Liquibase changelog (`ddl-v.0.0.<next>.yaml`)

Real evidence: `blank-service:ddl-v.0.0.1.yaml:8-34`. **Do NOT** add a
schema-create changeset — assume the schema already exists from a prior
migration (pre-flight 4 confirmed this).

```yaml
databaseChangeLog:
  - changeSet:
      id: 01_<aggregate-snake>_create_<aggregate-snake>_table
      author: lg
      changes:
        - createTable:
            schemaName: <schema>
            tableName: <aggregate-snake>
            columns:
              - column:
                  name: id
                  type: UUID
                  constraints:
                    primaryKey: true
                    nullable: false
              # one - column block per <field-spec>, e.g.:
              - column:
                  name: <field1-snake>
                  type: <SQL-type-from-table-above>
                  constraints:
                    nullable: <true|false>
                    unique: <true|false>     # only if :unique
```

### Step 10 — Wire into master changelog

Append to `db.changelog-master.yaml`:

```yaml
  - include:
      file: db/changelog/ddl-v.0.0.<next>.yaml
```

Real evidence for the format: `blank-service:db.changelog-master.yaml:2-3`.

### Step 11 — Integration test (`<Aggregate>RepositoryIT.java`)

Test class is **package-private**, extends `Bootstrap` (RULE-012). Asserts
save+findById round-trip:

```java
class <Aggregate>RepositoryIT extends Bootstrap {

    @Autowired
    private <Aggregate>Repository <aggregate>Repository;

    @Test
    void it_should_save_and_find_<aggregate>_by_id() {
        // given
        final var id = new <Aggregate>Id(UUID.randomUUID());
        final var <aggregate> = new <Aggregate>(id, <field1-sample-value>, ...);
        // when
        <aggregate>Repository.create<Aggregate>(<aggregate>);
        final var found = <aggregate>Repository.findById(id.getValue());
        // then
        assertThat(found).isPresent();
        assertThat(found.get().get<Field1>()).isEqualTo(<field1-sample-value>);
    }
}
```

### Step 12 — Sanity build

Run `make install-skip-test` from the service root. Common failures:
- MapStruct can't find the `<Aggregate>Id map(UUID)` helper → check the
  `default` method is in the same interface.
- Liquibase rejects the changelog → run `make run-apps` locally and read
  the container logs; typical cause is a duplicate changeset id.

### Step 13 — Final report

Summarize:
- 8 files created (paths + role)
- 1 file modified (`db.changelog-master.yaml`)
- the table DDL preview (so the user can sanity-check column types)
- next manual step: typically add domain behavior methods to
  `<Aggregate>.java` (this command only generates the skeleton with
  getters), and wire a use case via `/add-rest-endpoint`.

## Anti-patterns to avoid

- **Do NOT** put Spring annotations on the domain entity or value object
  (RULE-003). The aggregate root is plain Java + `AggregateRoot<T>`.
- **Do NOT** put JPA annotations on the domain entity. JPA lives ONLY
  in `<Aggregate>Entity` under `<svc>-data-access/.../data/entity/`
  (RULE-003).
- **Do NOT** create a Spring-Data-style domain entity with `@Entity` on
  `<Aggregate>` itself — that violates the hexagonal boundary.
- **Do NOT** use Liquibase XML format — the project standard is YAML
  (evidence: `blank-service:db.changelog-master.yaml`).
- **Do NOT** create a new schema. Reuse the service's existing one.
- **Do NOT** add `@OneToMany` / `@ManyToOne` / `@Embedded` / `@Enumerated`
  in v4.2.0 — these require manual modeling. Stop and ask the user to
  add them by hand.
- **Do NOT** add Postgres-native ENUM columns. Use `VARCHAR(64)` + a
  domain enum if the user explicitly asks; otherwise stop.
- **Do NOT** skip `@Version` if the aggregate participates in an outbox
  pattern (RULE-008) — but in scope for v4.2.0 this command does NOT
  create outbox-style aggregates; use `/add-saga` or `/add-outbox` for
  those.
- **Do NOT** generate a Spring Data query method by speculating (e.g.,
  `findByEmail`) — only add finders the user explicitly requested.
- **Do NOT** invent framework classes. `BaseId<T>`, `AggregateRoot<T>`,
  `DomainException` are real — locate them in
  `/tmp/lg5-study/lg5-spring/ddd-common-domain/` before referencing.

## References

- Skill: `lg5-new-service` (where each file goes in the module tree).
- Skill: `food-ordering-system` (real aggregates — `CustomerEntity`,
  `OrderEntity`, `RestaurantEntity` under `order-data-access/`).
- Reference (this consumer): `blank-service:Blank.java`,
  `blank-service:BlankId.java`,
  `blank-service:BlankRepository.java`,
  `blank-service:BlankEntity.java`,
  `blank-service:BlankJPARepository.java`,
  `blank-service:BlankRepositoryImpl.java`,
  `blank-service:BlankDataAccessMapper.java`,
  `blank-service:ddl-v.0.0.1.yaml`,
  `blank-service:db.changelog-master.yaml`.
- Rules: RULE-003 (hexagonal — domain is Spring/JPA free),
  RULE-004 (module shape), RULE-015 (final fields),
  RULE-016 (DDD blocks from `ddd-common-domain`),
  RULE-018 (cite canonical sources).

## Out of scope

- Aggregates with child entities (`@OneToMany`, `@ManyToOne`) — manual.
- Aggregates using native Postgres ENUM types — manual.
- Aggregates with `@Embedded` value-object columns — manual.
- Outbox-pattern aggregates (those have `@Version` + `OutboxStatus` +
  status enum + payload jsonb) — use `/add-outbox`.
- Aggregates with optimistic locking via `@Version` (general case) —
  add manually after generation.
- Custom Spring Data query methods (`findByXxx`, `@Query`) — add by hand.
- Flyway-based services — this command is Liquibase-only.
