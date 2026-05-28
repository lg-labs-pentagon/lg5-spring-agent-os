# Commands

Commands are the primary interface for driving the Spec-Driven Development (SDD) workflow and invoking repeatable, automated code generation tasks. They are typically used as slash commands (e.g., `/sdd-specify`) within the agent's chat interface.

There are two categories of commands: **SDD Orchestrators** and **Building Blocks**.

## SDD Orchestrators

These commands move a feature from one phase of the SDD workflow to the next. They are designed to be called in sequence to manage the lifecycle of a feature specification.

| Command | Phase | Description |
|:---|:---|:---|
| `/sdd-intent <slug> "<idea>"` | 0 (Optional) | Frames an informal idea into a structured, one-page `intent.md`. |
| `/sdd-specify <slug> "<desc>"` | 1 | Converts an informal prompt or an approved intent into a formal, technology-free `prd.md`. |
| `/sdd-plan <NNN-slug>` | 2 | Generates a high-level technical `plan.md` and architectural ADRs from an approved PRD. |
| `/sdd-design <NNN-slug>` | 3 | Generates a detailed `design.md` and `data-model.md` with concrete contracts, schemas, and configurations. |
| `/sdd-tasks <NNN-slug>` | 4 | Decomposes a detailed design into atomic, executable `TASK-NNN` for the agent. |
| `/sdd-implement <TASK-NNN>` | 5 | Executes a single task by generating the necessary code and tests, and creates a commit. This is the main implementation loop. |
| `/sdd-verify <NNN-slug>` | 6 | A mandatory quality gate that cross-checks all requirements against test evidence, producing a final `verify-report.md`. |
| `/sdd-orchestrate [<NNN-slug>]` | Meta | A read-only helper that inspects the state of a spec and recommends the next logical command to run. |
| `/sdd-quick <slug> "<desc>"` | Quick Path | A fast-track for trivial changes, generating a compressed `quick-spec.md` and jumping directly to implementation. |

## Building Blocks

These commands are typically invoked during the `/sdd-implement` phase to generate specific, standards-compliant code artifacts.

| Command | Description |
|:---|:---|
| `/scaffold-service` | Scaffolds a complete 8-module microservice skeleton from the `blank-service` template, compliant with RULE-004. |
| `/add-saga` | Adds a complete `SagaStep` orchestration end-to-end, including the publisher, listener, outbox entry, and scheduler. |
| `/add-outbox` | Adds a Transactional Outbox for a specific event type, including the entity, DDL, helper, and scheduler, compliant with RULE-008. |
| `/add-kafka-listener` | Adds an idempotent, batch-processing Kafka listener, compliant with RULE-010. |
| `/add-rest-endpoint` | Generates a full REST endpoint, including the controller method, DTOs, service port, handler, mapper, and an integration test, compliant with RULE-003, RULE-005, and RULE-006. |
| `/add-jpa-entity` | Generates a complete JPA aggregate, including the domain entity, repository, JPA entity, mappers, Liquibase changelog, and an integration test, compliant with RULE-003 and RULE-016. |
| `/scaffold-ci-cd` | Installs the canonical CI/CD pipeline (GitHub Actions) into a service. |
| `/scaffold-docs` | Installs the unified VitePress documentation site into a service. |
