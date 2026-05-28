import { defineConfig } from 'vitepress'

export default defineConfig({
  title: "lg5-spring-agent-os",
  description: "Documentation for the Agent Operating System for lg5-spring.",
  base: '/lg5-spring-agent-os/',
  
  themeConfig: {
    logo: { light: '/logo-light.svg', dark: '/logo-dark.svg' },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/lg-labs-pentagon/lg5-spring-agent-os' }
    ],
    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2026-present'
    },
    search: {
      provider: 'local'
    }
  },

  locales: {
    root: {
      label: 'English',
      lang: 'en',
      themeConfig: {
        nav: [
          { text: 'Guide', link: '/guide/quick-start' },
          { text: 'Reference', link: '/reference/sdd-workflow' },
        ],
        sidebar: {
          '/guide/': [
            {
              text: 'Guide',
              items: [
                { text: 'Why Agent OS?', link: '/guide/why' },
                { text: 'Quick Start', link: '/guide/quick-start' },
                { text: 'Agent Architecture', link: '/guide/agent-architecture' },
                { text: 'Supported Tools', link: '/guide/supported-tools' },
              ]
            }
          ],
          '/reference/': [
            {
              text: 'Reference',
              items: [
                { text: 'Spec-Driven Development (SDD)', link: '/reference/sdd-workflow' },
                { text: 'The Constitution', link: '/reference/constitution' },
                { text: 'Skills', link: '/reference/skills' },
                { text: 'Commands', link: '/reference/commands' },
                { text: 'Subagents', link: '/reference/subagents' },
              ]
            }
          ]
        }
      }
    },
    es: {
      label: 'Español',
      lang: 'es',
      link: '/es/',
      themeConfig: {
        nav: [
          { text: 'Guía', link: '/es/guide/quick-start' },
          { text: 'Referencia', link: '/es/reference/sdd-workflow' },
        ],
        sidebar: {
          '/es/guide/': [
            {
              text: 'Guía',
              items: [
                { text: '¿Por qué Agent OS?', link: '/es/guide/why' },
                { text: 'Inicio Rápido', link: '/es/guide/quick-start' },
                { text: 'Arquitectura de Agentes', link: '/es/guide/agent-architecture' },
                { text: 'Herramientas Soportadas', link: '/es/guide/supported-tools' },
              ]
            }
          ],
          '/es/reference/': [
            {
              text: 'Referencia',
              items: [
                { text: 'Desarrollo Dirigido por Especificaciones (SDD)', link: '/es/reference/sdd-workflow' },
                { text: 'La Constitución', link: '/es/reference/constitution' },
                { text: 'Habilidades', link: '/es/reference/skills' },
                { text: 'Comandos', link: '/es/reference/commands' },
                { text: 'Subagentes', link: '/es/reference/subagents' },
              ]
            }
          ]
        }
      }
    }
  }
})
