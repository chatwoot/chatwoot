import { defineConfig } from 'vite';
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

const testConfig = defineConfig({
  plugins: [vue(vueOptions)],
});

export default mergeConfig(baseConfig, testConfig);
