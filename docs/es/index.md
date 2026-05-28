---
layout: home

hero:
  name: "lg5-spring-agent-os"
  text: "Tu Co-desarrollador Potenciado por IA"
  tagline: Un sistema operativo de agentes para construir microservicios robustos y basados en convenciones sobre el framework lg5-spring. Deja que tu agente de IA haga el trabajo pesado.
  image:
    src: /logo.svg
    alt: AgentOS
  actions:
    - theme: brand
      text: Empezar
      link: /es/guide/quick-start
    - theme: alt
      text: View on GitHub
      link: https://github.com/lg-labs-pentagon/lg5-spring-agent-os

features:
  - title: Desarrollo Dirigido por Especificaciones
    icon: 📝
    details: Sigue un flujo de trabajo riguroso y anclado a especificaciones, desde la idea hasta la implementación, asegurando que las funcionalidades se construyan según lo previsto.
  - title: Barandillas Constitucionales
    icon: 📜
    details: Construye con confianza. 15 reglas inmutables refuerzan la integridad arquitectónica y las mejores prácticas, previniendo errores comunes.
  - title: Herramientas Autónomas
    icon: 🤖
    details: Aprovecha un rico ecosistema de Habilidades, Comandos y Subagentes que empoderan a tu IA para estructurar, construir y probar de forma autónoma.
  - title: Extensible y Componible
    icon: 🧩
    details: Diseñado para ser modular, permitiendo a los equipos adoptar, personalizar y extender el sistema con sus propias reglas y habilidades.
---

<script setup>
import { useData } from 'vitepress'
const { theme } = useData()
</script>

<div style="text-align: center; margin-top: 20px;">
  <h3>Latest Version: {{ theme.latestVersion }}</h3>
</div>
