---
description: Add a new REST endpoint (POST/GET/PUT/DELETE) to an lg5-spring service — controller method + DTO records + service port method + impl handler + MapStruct mapper updates + OpenAPI fragment + integration test. Idiomatic per RULE-003/004/005/006/012/015.
argument-hint: <service-name> <http-method> <path> <operation-id> [--existing-controller <name>]
allowed-tools: bash, read, write, edit, glob, grep
---

# /add-rest-endpoint

You are adding a single REST endpoint to an existing lg5-spring microservice.
The endpoint is a thin adapter (RULE-003) that delegates to an
`<svc>ApplicationService` input port. **Do NOT invent framework classes.**
If a class isn't in `blank-service` or `food-ordering-system/order-service`,
say so explicitly and stop (RULE-018).

This command is intended to be invoked from inside `/sdd-implement` against
a specific `TASK-NNN` whose acceptance criteria call for a REST endpoint.
It can also be invoked standalone for ad-hoc work.

## Inputs

- `<service-name>` — the existing service (e.g., `blank`, `order`, `loyalty`).
  Must follow the 8-module shape (RULE-004).
- `<http-method>` — one of `POST`, `GET`, `PUT`, `DELETE`. Lowercase or
  uppercase, both accepted.
- `<path>` — the URL path relative to the service base, e.g., `/blank` for
  collection-level or `/blank/{id}` for resource-level.
- `<operation-id>` — camelCase OpenAPI operationId, e.g., `addBlank`,
  `getBlankById`, `updateBlank`, `deleteBlank`. Must be unique in the
  service's `openapi.yaml`.
- `--existing-controller <name>` — optional. If provided, append the method
  to that controller class. If omitted, **use the aggregate's existing
  controller** (`<Aggregate>Controller`) — never create a new controller
  for an additional method on the same aggregate.

If the user provided fewer arguments than required, ask for the missing
ones BEFORE writing any file.

## Pre-flight checks

1. **Service shape**: confirm the canonical Maven module tree exists:
   `<svc>-api/`, `<svc>-container/`, `<svc>-data-access/`, `<svc>-support/`,
   `<svc>-acceptance-test/`,
   `<svc>-domain/{<svc>-domain-core, <svc>-application-service}/`,
   `<svc>-message/{<svc>-message-core, <svc>-message-model}/`,
   and (optional) `<svc>-external/`. Note the nested aggregator POMs
   `<svc>-domain` and `<svc>-message`. If any required module is missing,
   this is not a lg5-spring service — stop and recommend `/scaffold-service`
   first. Confirmed evidence: `blank-service/` root, RULE-004.
2. **Application service port**: locate
   `<svc>-domain/<svc>-application-service/.../domain/ports/input/service/<Aggregate>ApplicationService.java`.
   If it does not exist, the aggregate is not bootstrapped — stop and
   recommend creating the aggregate first (use `/add-jpa-entity` for the
   data layer and create the domain entity by hand).
3. **Existing OpenAPI spec**: locate
   `<svc>-api/src/main/resources/spec/openapi.yaml`. If absent, the service
   is misconfigured — stop and recommend `/scaffold-service`.
4. **operationId uniqueness**: grep `operationId: <operation-id>` in
   `openapi.yaml`. If it already exists, stop and ask for a different name.
5. **Path uniqueness**: if the `<http-method> <path>` pair is already
   declared under `paths:`, stop and ask whether to overwrite.

## What you will create / modify

Always created together (companion files per the REST adapter pattern):

| File | Module | Action |
|---|---|---|
| `<Aggregate>Controller.java` | `<svc>-api/.../api/rest/` | **modify** — append the new handler method |
| `<Verb><Aggregate>Command.java` or `<Verb><Aggregate>Query.java` (record) | `<svc>-domain/<svc>-application-service/.../domain/dto/<verb>/` | **create** — `@Builder record` with `@NotNull` fields. For GET, the DTO may be omitted if all inputs are path/query params. |
| `<Verb><Aggregate>Response.java` (record) | same package | **create** unless DELETE returns `204 No Content` |
| `<Aggregate>ApplicationService.java` | `<svc>-domain/<svc>-application-service/.../domain/ports/input/service/` | **modify** — add the method signature with `@Valid` |
| `<Aggregate>ApplicationServiceImpl.java` | `<svc>-domain/<svc>-application-service/.../domain/` | **modify** — implement the method, delegate to a fresh `<Verb>CommandHandler` |
| `<Verb><Aggregate>CommandHandler.java` | `<svc>-domain/<svc>-application-service/.../domain/` | **create** — `@Component` with `@Transactional` if mutating |
| `<Aggregate>DataMapper.java` | `<svc>-domain/<svc>-application-service/.../domain/mapper/` | **modify** — add MapStruct methods for new DTOs ↔ domain |
| `openapi.yaml` | `<svc>-api/src/main/resources/spec/` | **modify** — append a `paths.<path>.<method>:` block + schemas under `components.schemas` |
| `<Verb><Aggregate>IT.java` | `<svc>-container/src/test/java/.../container/api/` | **create** — extends `Bootstrap` (which extends `Lg5TestBoot` per RULE-012); RestAssured against the random port |

## Steps

Summarize before/after for each file as you go (file path + 5-line context
diff). Do not batch — write one file at a time and verify it before
moving on.

### Step 1 — DTOs (`<svc>-domain/<svc>-application-service/.../domain/dto/<verb>/`)

Canonical shape (real evidence from `blank-service:CreateBlankCommand.java`):

```java
@Builder
public record <Verb><Aggregate>Command(@NotNull <Type> <field>, ...) {
}
```

Map HTTP method → verb folder:
- `POST` → `create/` → `Create<Aggregate>Command` + `Create<Aggregate>Response`
- `GET` (by id) → `get/` → no Command needed (use path param); `Get<Aggregate>Response`
- `GET` (collection) → `list/` → `List<Aggregate>Query` + `List<Aggregate>Response`
- `PUT` → `update/` → `Update<Aggregate>Command` + `Update<Aggregate>Response`
- `DELETE` → `delete/` → no DTOs (use path param, return `204`)

Use `jakarta.validation.constraints.*` (`@NotNull`, `@NotBlank`, `@Size`,
`@Email`, etc.) per the aggregate's field semantics. Lombok `@Builder` is
mandatory.

### Step 2 — Service port (`<Aggregate>ApplicationService.java`)

Add the method signature. Real evidence from
`blank-service:BlankApplicationService.java:8`:

```java
public interface <Aggregate>ApplicationService {
    // existing methods …
    <Verb><Aggregate>Response <verb><Aggregate>(@Valid <Verb><Aggregate>Command command);
    // for GET by id:
    Get<Aggregate>Response get<Aggregate>(UUID <aggregate>Id);
    // for DELETE:
    void delete<Aggregate>(UUID <aggregate>Id);
}
```

`@Valid` on the argument is what activates bean validation (because the
impl class is annotated `@Validated`).

### Step 3 — Command handler (`<Verb><Aggregate>CommandHandler.java`)

One handler per use case (food-ordering-system convention). `@Component`,
constructor-injected dependencies, `@Transactional` if it mutates state.
Inject the output port (`<Aggregate>Repository`) and the mapper:

```java
@Slf4j
@Component
public class <Verb><Aggregate>CommandHandler {
    private final <Aggregate>Repository <aggregate>Repository;
    private final <Aggregate>DataMapper <aggregate>DataMapper;

    public <Verb><Aggregate>CommandHandler(<Aggregate>Repository <aggregate>Repository,
                                           <Aggregate>DataMapper <aggregate>DataMapper) {
        this.<aggregate>Repository = <aggregate>Repository;
        this.<aggregate>DataMapper = <aggregate>DataMapper;
    }

    @Transactional
    public <Verb><Aggregate>Response handle(<Verb><Aggregate>Command command) {
        final <Aggregate> aggregate = <aggregate>DataMapper.commandTo<Aggregate>(command);
        final <Aggregate> persisted = <aggregate>Repository.create<Aggregate>(aggregate);
        log.info("<Aggregate> {} created via REST", persisted.getId().getValue());
        return <aggregate>DataMapper.<aggregate>To<Verb>Response(persisted);
    }
}
```

For GET, no `@Transactional` and no command — `handle(UUID id)`.

### Step 4 — Service impl (`<Aggregate>ApplicationServiceImpl.java`)

Wire the new handler in via constructor injection and forward the call:

```java
@Slf4j
@Service
@Validated
class <Aggregate>ApplicationServiceImpl implements <Aggregate>ApplicationService {
    private final <Verb><Aggregate>CommandHandler <verb><Aggregate>CommandHandler;
    // existing handlers …

    @Override
    public <Verb><Aggregate>Response <verb><Aggregate>(<Verb><Aggregate>Command command) {
        return <verb><Aggregate>CommandHandler.handle(command);
    }
}
```

Impl is **package-private** (no `public` keyword on the class) — only the
interface is exposed.

### Step 5 — Mapper (`<Aggregate>DataMapper.java`)

Add the MapStruct methods. The mapper is `@Mapper(componentModel = "spring")`.
For value-object wrapping (e.g., `BlankId(UUID)`), reuse the existing
`default` method or add one:

```java
@Mapping(target = "id", source = "id", qualifiedByName = "toAggregateId")
<Aggregate> commandTo<Aggregate>(<Verb><Aggregate>Command command);

<Verb><Aggregate>Response <aggregate>To<Verb>Response(<Aggregate> aggregate);
```

### Step 6 — Controller (`<Aggregate>Controller.java`)

Append the handler method. Real evidence from
`blank-service:BlankController.java:27-35`:

```java
@<HttpMethod>Mapping(<"/{id}" if path-param>)
public ResponseEntity<<Verb><Aggregate>Response> <operationId>(
        <@PathVariable UUID id, > <@RequestBody @Valid <Verb><Aggregate>Command command>) {
    log.info("<Verb> <aggregate> via REST: {}", <id-or-command-field>);
    final <Verb><Aggregate>Response response = <aggregate>ApplicationService.<verb><Aggregate>(<id-or-command>);
    return ResponseEntity.<status>().<headers>.body(response);
}
```

Status codes (idiomatic for this skeleton):
- `POST` → `202 Accepted` + `Location: /<aggregate>/<id>` header (async via outbox)
- `GET` → `200 OK`
- `PUT` → `200 OK` (or `204` if no body)
- `DELETE` → `204 No Content`, no body

The class-level `@RequestMapping(value = "/<aggregate>", produces = "application/vnd.api.v1+json")`
already supplies the media type per RULE-006 — do NOT re-declare on the
method.

### Step 7 — OpenAPI spec (`openapi.yaml`)

Append under `paths:` (single monolithic file is the canonical layout —
see `blank-service:openapi.yaml`):

```yaml
paths:
  <path>:
    <method>:
      tags: [<aggregate>]
      summary: <one-line summary>
      operationId: <operationId>
      parameters:                # if path/query params
        - name: <id>
          in: path
          required: true
          schema: { type: string, format: uuid }
      requestBody:               # if POST/PUT
        $ref: '#/components/requestBodies/<Verb><Aggregate>'
      responses:
        '<expected-status>':
          description: <description>
          content:
            application/vnd.api.v1+json:
              schema:
                $ref: '#/components/schemas/<Verb><Aggregate>Response'
        '400': { description: Invalid input }
        '404': { description: Not found }       # for GET/PUT/DELETE
        '422': { description: Validation exception }
```

Under `components.schemas:` add the request and response schemas mirroring
the Java records.

### Step 8 — Integration test (`<Verb><Aggregate>IT.java`)

Real evidence from `blank-service:BlankCreatorIT.java:27-59`. Test class is
**package-private**, extends `Bootstrap` (RULE-012):

```java
class <Verb><Aggregate>IT extends Bootstrap {

    @Test
    void it_should_<verb>_a_<aggregate>_using_api() {
        // given
        final var command = new <Verb><Aggregate>Command(UUID.randomUUID(), <other-fields>);
        // when
        final Response response = given(requestSpecification)
                .body(command)
                .when()
                .<httpMethod>("<path>");
        // then
        response.then().statusCode(HttpStatus.<expected>.value());
    }
}
```

For path params, replace `<path>` with the literal:
`.get("/<aggregate>/" + id)`.

### Step 9 — Sanity build

Run `make install-skip-test` from the service root. If it fails on
compilation, fix the issue (typically: missing import in mapper, missing
@Builder, or a typo in the OpenAPI schema $ref).

### Step 10 — Final report

Summarize:
- files created (paths + role)
- files modified (paths + 1-line description of what changed)
- the curl command the user can run against the local app to verify
- next manual step if any (typically: implement the domain logic inside
  the handler if it's more than a CRUD passthrough)

## Anti-patterns to avoid

- **Do NOT** create a new `<Aggregate>Controller` for a method on an
  existing aggregate — append to the existing one (RULE-004).
- **Do NOT** put `produces = "application/vnd.api.v1+json"` on the method
  — it's on the class via `@RequestMapping` (RULE-006).
- **Do NOT** put `@Validated` on the controller — it goes on the
  `<Aggregate>ApplicationServiceImpl` class (where `@Valid` arguments
  trigger validation).
- **Do NOT** invent a `lg5-spring` annotation — only stock Spring
  (`@RestController`, `@PostMapping`, `@PathVariable`, `@RequestBody`,
  `ResponseEntity`) + Lombok + Jakarta Validation (RULE-005).
- **Do NOT** put DTOs in `<svc>-api` — they live in
  `<svc>-domain/<svc>-application-service/.../domain/dto/<verb>/` (RULE-003).
- **Do NOT** make the impl class `public` — package-private (only the
  interface is exposed across modules).
- **Do NOT** use Jackson `@JsonProperty` on DTOs — record component names
  are already snake-case-compatible via Spring's default config.
- **Do NOT** skip the IT — every new endpoint gets one (RULE-012).
- **Do NOT** modify `<svc>-domain-core` from this command — that module is
  Spring-free; if you need a new aggregate, use `/add-jpa-entity` first
  which creates the domain entity, then come back here.

## References

- Skill: `lg5-new-service` (where each file goes in the 8-module shape).
- Skill: `food-ordering-system` (real REST endpoint patterns from
  `order-service/order-api/`).
- Reference (this consumer): `blank-service:BlankController.java`,
  `blank-service:BlankApplicationServiceImpl.java`,
  `blank-service:BlankCreatorIT.java`,
  `blank-service:openapi.yaml`.
- Rules: RULE-003 (hexagonal boundary), RULE-004 (module shape),
  RULE-005 (stock annotations), RULE-006 (media type),
  RULE-012 (IT base class), RULE-015 (records + final).

## Out of scope

- File upload endpoints (`multipart/form-data`) — manual.
- WebSocket / SSE — manual.
- API versioning bump (`v1` → `v2`) — manual; this command always uses the
  service's existing media-type version.
- Endpoints that produce/consume non-JSON — manual.
- Aggregate-less endpoints (e.g., `/health/foo`) — manual; this command
  assumes a 1:1 with an existing aggregate.
