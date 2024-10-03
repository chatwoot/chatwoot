import { config } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import i18nMessages from 'dashboard/i18n';

const i18n = createI18n({
  locale: 'en',
  messages: i18nMessages,
});

config.global.plugins = [i18n];
