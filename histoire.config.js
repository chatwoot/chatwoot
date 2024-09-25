import { defineConfig } from 'histoire'

export default defineConfig({
  vite: {
    server: {
      port: 6179,
    },
  },
  viteIgnorePlugins: ['vite-plugin-ruby'],
  defaultStoryProps: {
    icon: 'carbon:cube',
    iconColor: '#1F93FF',
    layout: {
      type: 'grid',
      width: '80%',
    },
  },
  tree: {
    groups: [
      {
        id: 'top',
        title: '',
      },
      {
        id: 'components',
        title: 'Components',
        include: () => true,
      },
    ],
  },
})
