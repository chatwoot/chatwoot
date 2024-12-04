import { defineConfig } from 'vite';
import ruby from 'vite-plugin-ruby';
import vue from '@vitejs/plugin-vue';
import baseConfig from './vite.config.base';
import { mergeConfig } from 'vite';

const vueOptions = {
  template: {
    compilerOptions: {
      isCustomElement: tag => ['ninja-keys'].includes(tag),
    },
  },
};

const defaultConfig = defineConfig({
  plugins: [ruby(), vue(vueOptions)],
  build: {
    rollupOptions: {
      output: {
        inlineDynamicImports: false,
      },
    },
  },
});

export default mergeConfig(baseConfig, defaultConfig);
