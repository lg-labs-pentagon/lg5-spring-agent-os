# Subagents

Subagents are specialized, autonomous agents that are invoked by the primary agent to perform specific, well-defined tasks. They are the "workers" in the Agent OS, each with a dedicated role.

You can invoke them directly via `@<name>` in the chat, but they are most often dispatched automatically by the `/sdd-*` commands.

## Primary Agents (Orchestrators)

In addition to subagents, the bundle provides **Primary Agents** that can be selected directly in the OpenCode agent cycle (via the **Tab** key). These agents act as top-level orchestrators for the development workflow.

| Agent | Purpose | Mode |
|:---|:---|:---|
| `sdd` | **Main SDD Orchestrator**. Inspects project state, recommends next phases, and coordinates the full 7-phase flow. | `primary` |
| `quick` | **Quick-path Specialist**. Handles trivial changes in a single step, bypassing design/tasks phases for maximum agility. | `primary` |

## SDD Phase Specialists

This group of agents is responsible for executing the phases of the Spec-Driven Development workflow. There is a one-to-one mapping between each SDD orchestrator command and its corresponding specialist subagent.

| Subagent | Pairs with | Purpose |
|:---|:---|:---|
| `sdd-intender` | `/sdd-intent` | Converts a raw idea into a structured `intent.md`. |
| `sdd-specifier` | `/sdd-specify` | Authors the functional `prd.md` from an intent or prompt. |
| `sdd-planner` | `/sdd-plan` | Authors the technical `plan.md` and ADRs from a PRD. |
| `sdd-designer` | `/sdd-design` | Authors the detailed `design.md` and `data-model.md`. |
| `sdd-tasker` | `/sdd-tasks` | Decomposes a design into an atomic `tasks.md` file. |
| `sdd-implementer` | `/sdd-implement` | Executes a single `TASK-NNN` to produce code and tests. |
| `sdd-verifier` | `/sdd-verify` | Executes the final verification checks and produces the `verify-report.md`. |
| `sdd-orchestrator`| `/sdd-orchestrate`| A read-only agent that inspects spec state and provides guidance. |
| `sdd-quicker` | `/sdd-quick` | Manages the "quick path" workflow for trivial changes. |

## Cross-Cutting Specialists

These specialists handle concerns that apply across multiple phases of the development lifecycle. They are often invoked manually with an `@` mention for ad-hoc tasks or automatically during the implementation phase.

| Subagent | Purpose |
|:---|:---|
| `lg5-code-reviewer` | Reviews code diffs against the 18 constitutional and advisory rules, citing violations by `RULE-ID`. This is a critical component of the pre-commit quality gate. |
| `lg5-test-generator`| Generates scaffolds for Integration Tests (IT) and Acceptance Tests (ATDD), ensuring they follow the patterns required by RULE-012 and RULE-013. |
| `lg5-ci-cd-engineer`| A specialist for all things related to Continuous Integration and Delivery. It uses the CI/CD skills to manage GitHub Actions, API documentation publishing, and test reporting. |
