---
layout: home

hero:
  name: "lg5-spring-agent-os"
  text: "Your AI-Powered Co-Developer"
  tagline: An agent operating system for building robust, convention-driven microservices on the lg5-spring framework. Let your AI agent do the heavy lifting.
  image:
    src: /logo.svg
    alt: AgentOS
  actions:
    - theme: brand
      text: Get Started
      link: /guide/quick-start
    - theme: alt
      text: View on GitHub
      link: https://github.com/lg-labs-pentagon/lg5-spring-agent-os

features:
  - title: Spec-Driven Development
    icon: 📝
    details: Follow a rigorous, spec-anchored workflow from idea to implementation, ensuring features are built as intended.
    link: /reference/sdd-workflow
  - title: Constitutional Guardrails
    icon: 📜
    details: Build with confidence. 15 immutable rules enforce architectural integrity and best practices, preventing common pitfalls.
    link: /reference/constitution
  - title: Autonomous Tooling
    icon: 🤖
    details: Leverage a rich ecosystem of Skills, Commands, and Subagents that empower your AI to autonomously scaffold, build, and test.
    link: /guide/agent-architecture
  - title: Extensible & Composable
    icon: 🧩
    details: Designed to be modular, allowing teams to adopt, customize, and extend the system with their own rules and skills.
    link: /reference/skills
---

<script setup>
import { data } from './github.data.js'
</script>

<div style="text-align: center; margin-top: 20px;">
  <h3>Latest Version: {{ data.latestVersion }}</h3>
</div>
