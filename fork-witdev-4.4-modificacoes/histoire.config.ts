import { defineConfig } from 'histoire';
import { HstVue } from '@histoire/plugin-vue';

export default defineConfig({
  setupFile: './histoire.setup.ts',
  plugins: [HstVue()],
  vite: {
    server: {
      port: 6179,
    },
  },
  viteIgnorePlugins: ['vite-plugin-ruby'],
  theme: {
    darkClass: 'dark',
    title: '@chatwoot/design',
    logo: {
      square: './design-system/images/logo-thumbnail.svg',
      light: './design-system/images/logo.png',
      dark: './design-system/images/logo-dark.png',
    },
  },
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
