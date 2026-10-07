import { config } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import FloatingVue from 'floating-vue';

// No messages: loading them here would pull 2537 locale files into every spec.
// Specs asserting on translated copy should use withFullI18n from vitest.i18n.
const i18n = createI18n({
  legacy: false,
  locale: 'en',
  messages: {},
  missingWarn: false,
  fallbackWarn: false,
});

config.global.plugins = [i18n, FloatingVue];
config.global.stubs = {
  WootModal: { template: '<div><slot/></div>' },
  WootModalHeader: { template: '<div><slot/></div>' },
  NextButton: { template: '<button><slot/></button>' },
};
