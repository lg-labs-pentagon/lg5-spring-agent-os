# Skills

Skills are deep, on-demand recipes that provide the agent with expert knowledge for a specific domain. When a user's request or an implementation task touches on one of these topics, the corresponding skill is loaded into the agent's context, giving it the precise instructions needed to generate correct and idiomatic code.

Below is the catalog of skills available in the `lg5-spring-agent-os`.

| Skill | Description |
|:---|:---|
| `lg5-spring-overview` | Provides a general overview of the lg5-spring framework, module map, recent changes, and core conventions. |
| `lg5-new-service` | Contains the recipe for scaffolding a brand-new microservice from the `blank-service` template, ensuring it adheres to RULE-004. |
| `lg5-saga` | Guides the implementation of a `SagaStep<T>` orchestration, including the processor, rollback logic, and transactional boundaries per RULE-009. |
| `lg5-outbox` | Details the implementation of the Transactional Outbox pattern, including the outbox entity, repository, scheduler, and event publishing logic, as required by RULE-008 and RULE-011. |
| `lg5-kafka-avro` | Provides instructions for creating Kafka producers and consumers, defining Avro schemas for payloads (RULE-007), and handling batch listening patterns (RULE-010). |
| `lg5-atdd` | Contains the patterns for writing Acceptance Test-Driven Development (ATDD) scenarios using Cucumber, Testcontainers, and Wiremock, following the conventions of RULE-012 and RULE-013. |
| `food-ordering-system` | A special skill that allows the agent to ground its answers and patterns against a real-world, complete reference application, providing concrete examples of all architectural rules. |
| `lg5-github-actions` | Guides the setup of a canonical GitHub Actions CI pipeline, including the composite action for Maven credentials. |
| `lg5-api-docs` | Contains the templates and process for generating and publishing OpenAPI (Swagger UI) and AsyncAPI (Studio) documentation sites. |
| `lg5-allure-report` | Provides the necessary wiring to integrate Allure Report with Cucumber 7 and the JUnit Platform for rich test reports. |
| `lg5-vitepress-docs`| Offers a unified documentation site solution using VitePress, including CI jobs for previews and deployment to Firebase/Pages. |
