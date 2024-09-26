import { defineConfig } from 'histoire';
import { HstVue } from '@histoire/plugin-vue';

export default defineConfig({
  plugins: [HstVue()],
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
});
