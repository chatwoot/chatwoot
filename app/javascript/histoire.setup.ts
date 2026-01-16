import './design-system/histoire.scss';
import { defineSetupVue3 } from '@histoire/plugin-vue';
import dashboardI18n from 'dashboard/i18n';
import widgetI18n from 'widget/i18n';
import { createI18n } from 'vue-i18n';
import { vResizeObserver } from '@vueuse/components';
import store from 'dashboard/store';
import FloatingVue from 'floating-vue';
import VueDOMPurifyHTML from 'vue-dompurify-html';
import { domPurifyConfig } from 'shared/helpers/HTMLSanitizer.js';
import { directive as onClickaway } from 'vue3-click-away';

function mergeMessages(...sources) {
  return sources.reduce((acc, src) => {
    Object.keys(src).forEach(key => {
      if (
        acc[key] &&
        typeof acc[key] === 'object' &&
        typeof src[key] === 'object'
      ) {
        acc[key] = mergeMessages(acc[key], src[key]);
      } else {
        acc[key] = src[key];
      }
    });
    return acc;
  }, {});
}

const i18n = createI18n({
  legacy: false, // https://github.com/intlify/vue-i18n/issues/1902
  locale: 'en',
  messages: mergeMessages(
    structuredClone(dashboardI18n),
    structuredClone(widgetI18n)
  ),
});

export const setupVue3 = defineSetupVue3(({ app }) => {
  app.use(store);
  app.use(i18n);
  app.use(FloatingVue, {
    instantMove: true,
    arrowOverflow: false,
    disposeTimeout: 5000000,
  });

  app.directive('resize', vResizeObserver);
  app.use(VueDOMPurifyHTML, domPurifyConfig);
  app.directive('on-clickaway', onClickaway);
});
