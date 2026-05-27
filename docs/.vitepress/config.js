import { defineConfig } from 'vitepress'

export default defineConfig({
  title: "lg5-spring-agent-os",
  description: "Documentation for the Agent Operating System for lg5-spring.",
  base: '/lg5-spring-agent-os/',
  themeConfig: {
    logo: '/logo.svg', // Assuming we can add a logo later
    nav: [
      { text: 'Guide', link: '/guide/quick-start' },
      { text: 'Reference', link: '/reference/sdd-workflow' },
      { text: 'GitHub', link: 'https://github.com/lg-labs-pentagon/lg5-spring-agent-os' }
    ],

    sidebar: {
      '/guide/': [
        {
          text: 'Guide',
          items: [
            { text: 'Why Agent OS?', link: '/guide/why' },
            { text: 'Quick Start', link: '/guide/quick-start' },
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
    },

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
  }
})
