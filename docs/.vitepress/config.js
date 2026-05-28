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
          { text: 'Getting Started', link: '/guide/why' },
          { text: 'Workflows', link: '/guide/sdd/' },
          { text: 'Reference', link: '/reference/constitution' },
        ],
        sidebar: {
          '/guide/': [
            {
              text: 'Getting Started',
              items: [
                { text: 'Why Agent OS?', link: '/guide/why' },
                { text: 'Quick Start', link: '/guide/quick-start' },
                { text: 'Agent Architecture', link: '/guide/agent-architecture' },
              ]
            },
            {
              text: 'Workflows',
              items: [
                { text: 'Spec-Driven Development', link: '/guide/sdd/' },
                { text: 'Full Workflow', link: '/guide/sdd/full-workflow' },
                { text: 'Quick Path', link: '/guide/sdd/quick-path' },
              ]
            }
          ],
          '/reference/': [
            {
              text: 'Reference',
              items: [
                { text: 'The Constitution', link: '/reference/constitution' },
                { text: 'Supported Tools', link: '/reference/supported-tools' },
                { text: 'Skills', link: '/reference/skills' },
                { text: 'Commands', link: '/reference/commands' },
                { text: 'Subagents', link: '/reference/subagents' },
              ]
            }
          ]
        }
      }
    }
  }
})
