import { config } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import i18nMessages from 'dashboard/i18n';
import FloatingVue from 'floating-vue';

/**
 * Replaces the empty i18n instance from the global setup with the real
 * messages. Call it at the top of the spec, outside of hooks.
 * See vitest.setup.js.
 */
export function withFullI18n(locale = 'en') {
  const i18n = createI18n({
    legacy: false,
    locale,
    messages: i18nMessages,
  });

  config.global.plugins = [i18n, FloatingVue];

  return i18n;
}
