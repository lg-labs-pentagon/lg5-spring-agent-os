# Quick Start

Get up and running with `lg5-spring-agent-os` in your microservice repository. This guide will walk you through integrating the Agent OS so you can start leveraging its capabilities.

## Prerequisites

- A Java microservice project based on the `lg5-spring` framework.
- Git initialized in your repository.
- An AI-powered coding assistant (e.g., OpenCode) configured in your environment.

## Integration Steps

The bundle is consumed as a **Git submodule** mounted at `.agent-os/` in your consumer repository. The submodule itself is the source of truth—artifacts are **not** copied. An installation script materializes a `.opencode/` directory of relative symlinks that point back into `.agent-os/`, which is what your agent actually loads at runtime.

### 1. Add the Submodule

Navigate to the root of your microservice repository and run the following command to add the Agent OS bundle as a submodule.

```bash
git submodule add -b main git@github.com:lg-labs-pentagon/lg5-spring-agent-os.git .agent-os
```

This command tracks the `main` branch, which is suitable for development. For production, you should pin to a specific release tag.

### 2. Pin to a Specific Version (Recommended)

To ensure stability, check out a specific, tagged release. You can find the latest release version on the [GitHub repository's releases page](https://github.com/lg-labs-pentagon/lg5-spring-agent-os/releases).

```bash
# Example for version v1.0.0
git -C .agent-os checkout v1.0.0
```

### 3. Run the Installation Script

The installation script wires the Agent OS into your local development environment by creating the necessary symlinks inside the `.opencode/` directory.

```bash
.agent-os/scripts/install.sh
```

This script is idempotent, meaning you can safely run it multiple times. It will also add the `.opencode/` directory to your `.gitignore` file to prevent the generated links from being committed.

### 4. Commit the Integration

Once the submodule is added and the installation script has been run, commit the changes to your repository. This records the Agent OS version your service depends on.

```bash
git add .gitmodules .agent-os .gitignore
git commit -m "chore(agent-os): [LG-89] Integrate lg5-spring-agent-os"
```
*Note: We've included the ticket number `LG-89` as requested for this documentation work.*

### 5. Post-Clone Setup for Teammates

After a fresh clone of your repository, other developers will need to initialize the submodule. Instruct them to run:

```bash
# Initialize and fetch all submodules
git submodule update --init --recursive

# Re-create the symlinks for the agent
.agent-os/scripts/install.sh
```

## What's Next?

Your agent is now equipped with the full `lg5-spring-agent-os`!

You can now start using the Spec-Driven Development workflow. Try asking your agent:

`Can you orchestrate the '001-loyalty-ledger' spec?`

Or, for a new feature:

`I want to create a new feature. Can you create an intent for 'user-profile-management' using /sdd-intent?`

Explore the **Reference** sections to see the full list of available commands, skills, and rules.
