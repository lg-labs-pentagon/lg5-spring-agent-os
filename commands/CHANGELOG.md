# Changelog — lg5-spring-agent-os commands bundle

All notable changes to the **commands** artifact set are documented here.
Uses [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[SemVer 2.0.0](https://semver.org/spec/v2.0.0.html).

## [0.1.0] — 2026-05-09
### Added
- `/scaffold-service` — bootstrap a new microservice from `blank-service`.
- `/add-saga` — add an end-to-end SagaStep (publisher + listener + outbox + scheduler).
- `/add-outbox` — add a Transactional Outbox (entity + DDL + helper + scheduler) for one event type.
- `/add-kafka-listener` — add a batch Kafka listener with NO-OP exception
  handling per RULE-010.
### Notes
- Validated against `lg5-spring` SHA `cbb6783`.
- Commands are written for OpenCode's slash-command format (YAML frontmatter
  with `description`, `argument-hint`, `allowed-tools`); they should be
  portable to Claude Code and Cursor with minor adaptation.
