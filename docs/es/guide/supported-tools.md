# Herramientas Soportadas

El ecosistema de `lg5-spring-agent-os` está diseñado para ser flexible y extensible. Actualmente, la principal herramienta soportada para interactuar con los agentes es:

## OpenCode

[OpenCode](https://opencode.ai/) es un entorno de desarrollo interactivo en la línea de comandos (CLI) que permite a los desarrolladores colaborar con agentes de inteligencia artificial para realizar tareas de ingeniería de software.

### Características Clave

- **Interacción en Lenguaje Natural**: Comunícate con los agentes usando prompts en lenguaje natural.
- **Acceso a Herramientas**: Los agentes pueden utilizar herramientas como `bash`, `grep`, `read`, `write`, y `edit` para entender y modificar tu código.
- **Flujos de Trabajo de SDD**: Integra el [Desarrollo Dirigido por Especificaciones (Spec-Driven Development)](/es/reference/sdd-workflow.html) para un ciclo de vida de desarrollo estructurado.
- **Seguridad**: Proporciona un entorno seguro donde las operaciones potencialmente peligrosas requieren confirmación del usuario.

## Otras Herramientas

Aunque OpenCode es la herramienta principal, la arquitectura de agentes está desacoplada y podría integrarse con otros clientes en el futuro, como:

- Bots de chat en plataformas como Slack o Discord.
- Extensiones de IDE (Visual Studio Code, IntelliJ).
- Interfaces web personalizadas.
