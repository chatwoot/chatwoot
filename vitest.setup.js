import { config } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import enMessages from 'dashboard/i18n/locale/en';
import FloatingVue from 'floating-vue';

const i18n = createI18n({
  legacy: false, // https://github.com/intlify/vue-i18n/issues/1902
  locale: 'en',
  messages: { en: enMessages },
});

config.global.plugins = [i18n, FloatingVue];
config.global.stubs = {
  WootModal: { template: '<div><slot/></div>' },
  WootModalHeader: { template: '<div><slot/></div>' },
  WootButton: { template: '<button><slot/></button>' },
};
