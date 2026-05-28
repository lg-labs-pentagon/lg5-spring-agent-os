# Supported Tools

The `lg5-spring-agent-os` ecosystem is designed to be flexible and extensible. Currently, the main supported tool for interacting with agents is:

## OpenCode

[OpenCode](https://opencode.ai/) is an interactive command-line interface (CLI) development environment that allows developers to collaborate with AI agents to perform software engineering tasks.

### Key Features

- **Natural Language Interaction**: Communicate with agents using natural language prompts.
- **Tool Access**: Agents can use tools like `bash`, `grep`, `read`, `write`, and `edit` to understand and modify your code.
- **SDD Workflows**: Integrates [Spec-Driven Development](/reference/sdd-workflow.html) for a structured development lifecycle.
- **Security**: Provides a secure environment where potentially dangerous operations require user confirmation.

## Other Tools

Although OpenCode is the main tool, the agent architecture is decoupled and could be integrated with other clients in the future, such as:

- Chat bots on platforms like Slack or Discord.
- IDE extensions (Visual Studio Code, IntelliJ).
- Custom web interfaces.
