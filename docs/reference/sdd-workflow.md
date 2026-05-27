# Spec-Driven Development (SDD)

Spec-Driven Development is the cornerstone of the `lg5-spring-agent-os`. It's a structured workflow that guides features from an idea to production-ready code, ensuring clarity, architectural alignment, and correctness at every stage.

This process is implemented as a series of phases, each orchestrated by a specific slash command and resulting in one or more clear, version-controlled artifacts.

## The Full Workflow

The complete SDD path consists of seven phases, designed for non-trivial features that require careful planning and design.

```
  /sdd-intent    /sdd-specify   /sdd-plan       /sdd-design       /sdd-tasks    /sdd-implement   /sdd-verify
   (optional)
      │              │              │                 │                │              │              │
      ▼              ▼              ▼                 ▼                ▼              ▼              ▼
   intent.md  ►   prd.md     ►  plan.md + adr/  ►  design.md      ►  tasks.md   ►  code + tests ►  verify-report.md
   (why)          (what)         (architecture)    (detailed how)    (atomic)       + commit       (AC ✓/✗)
```

### Phase 0: Intent (`/sdd-intent`)
- **Purpose:** To frame an informal idea into a one-page document.
- **Artifact:** `intent.md`
- **Content:** The problem, the target users, the desired outcome, and what's explicitly out of scope. This phase is optional but recommended for new or complex ideas.

### Phase 1: Specify (`/sdd-specify`)
- **Purpose:** To convert the informal intent into a formal, technology-free functional specification.
- **Artifact:** `prd.md` (Product Requirements Document)
- **Content:** A list of functional requirements (`REQ-NNN`), each with clear acceptance criteria.

### Phase 2: Plan (`/sdd-plan`)
- **Purpose:** To create a high-level technical architecture for the approved PRD.
- **Artifacts:** `plan.md`, `adr/*.md`
- **Content:** The overall module structure, dependency graph, and any necessary Architectural Decision Records (ADRs) that justify key technical choices or deviations from the Constitution.

### Phase 3: Design (`/sdd-design`)
- **Purpose:** To flesh out the detailed technical design based on the plan.
- **Artifacts:** `design.md`, `data-model.md`
- **Content:** Concrete API contracts, database schemas, Avro payloads, JPA entities, and configuration properties.

### Phase 4: Tasks (`/sdd-tasks`)
- **Purpose:** To decompose the detailed design into a list of atomic, executable tasks for the AI agent.
- **Artifact:** `tasks.md`
- **Content:** A list of `TASK-NNN`, each with a clear set of Given/When/Then acceptance criteria, dependencies, and the specific skills or commands to use.

### Phase 5: Implement (`/sdd-implement`)
- **Purpose:** To execute a single task, generate the corresponding code and tests, and commit the result.
- **Artifacts:** Application code, unit/integration tests, a Git commit.
- **Process:** This is a loop. The agent picks up one `TASK-NNN` at a time and implements it.

### Phase 6: Verify (`/sdd-verify`)
- **Purpose:** To ensure the final implementation meets all acceptance criteria defined in the PRD.
- **Artifact:** `verify-report.md`
- **Process:** This mandatory quality gate cross-checks every requirement against test evidence. A red gate blocks the feature from being considered "done."

---

## The Quick Path (`/sdd-quick`)

For trivial changes (e.g., adding a single field, one new endpoint, a minor configuration change), the full 7-phase workflow is overkill. The quick path provides an accelerated route.

```
  /sdd-quick                                                              /sdd-implement   /sdd-verify
      │                                                                          │              │
      ▼                                                                          ▼              ▼
   quick-spec.md  ──────────────────────────────────────────────────────►  code + tests  ►  verify-report.md
```

- **Eligibility:** The `/sdd-quick` command is gated by 10 criteria. It will reject complex changes like new sagas, outboxes, or multi-module epics, routing them to the full path.
- **Process:** It generates a single, compressed `quick-spec.md` that serves as a minimal PRD, Plan, and Task list in one. From there, the workflow jumps directly to `/sdd-implement` and `/sdd-verify`.
