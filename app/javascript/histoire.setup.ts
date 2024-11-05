import './design-system/histoire.scss';
import { defineSetupVue3 } from '@histoire/plugin-vue';
import i18nMessages from 'dashboard/i18n';
import { createI18n } from 'vue-i18n';

const i18n = createI18n({
  legacy: false, // https://github.com/intlify/vue-i18n/issues/1902
  locale: 'en',
  messages: i18nMessages,
});

export const setupVue3 = defineSetupVue3(({ app }) => {
  app.use(i18n);
});
