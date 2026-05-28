# Why "Agent OS"?

This project follows the emerging convention of treating context artifacts as a unified **operating layer** for AI agents — analogous to how a traditional OS bundles a kernel, shell, utilities, and drivers.

The term "Agent Operating System" reflects the core mission: to provide an AI coding agent with everything it needs to be a productive, autonomous, and reliable co-developer within a specific technical ecosystem.

### The Core Components

An Agent OS is more than just a collection of prompts. It's a structured system of artifacts that work together:

- **The Constitution (`rules/`):** The "kernel." These are the immutable laws of the ecosystem. They are non-negotiable architectural and technical constraints that ensure every piece of generated code is safe, compliant, and consistent.

- **Skills (`skills/`):** The "drivers." These provide the agent with deep, on-demand knowledge for specific domains. When the agent needs to implement a Kafka listener or a transactional outbox, it loads the relevant skill to get a perfect, idiomatic recipe.

- **Commands (`commands/`):** The "shell utilities." These are repeatable, high-level workflows that the agent (or a user) can invoke. They orchestrate complex actions like scaffolding a new service (`/scaffold-service`) or decomposing a feature into tasks (`/sdd-tasks`).

- **Subagents (`subagents/`):** The "specialized processes." These are expert agents delegated to perform specific functions within the workflow, such as reviewing code against the constitution (`lg5-code-reviewer`) or planning the technical implementation of a feature (`sdd-planner`).

- **Specifications (`specs/`):** The "filesystem and user space." This is where the work happens. The SDD (Spec-Driven Development) workflow artifacts—PRDs, plans, tasks—are the files the agent reads and writes to, turning human intent into machine-executable code.

By bundling these components into a versioned, validated, and easily consumable package, `lg5-spring-agent-os` ensures that every developer and every AI agent is building on the same foundation, speaking the same language, and following the same rules.
