import { createApp } from 'vue';
import { createI18n } from 'vue-i18n';

import axios from 'axios';
// Global Components
import hljsVuePlugin from '@highlightjs/vue-plugin';

import { plugin, defaultConfig } from '@formkit/vue';
import WootWizard from 'components/ui/Wizard.vue';
import FloatingVue from 'floating-vue';
import WootUiKit from 'dashboard/components';
import App from 'dashboard/App.vue';
import i18nMessages from 'dashboard/i18n';
import createAxios from 'dashboard/helper/APIHelper';

import commonHelpers, { isJSONValid } from 'dashboard/helper/commons';
import { sync } from 'shared/store/createStore';
import { createPinia } from 'pinia';
import router, { initalizeRouter } from 'dashboard/routes';
import store from 'dashboard/store';
import constants from 'dashboard/constants/globals';
import * as Sentry from '@sentry/vue';
import {
  initializeAnalyticsEvents,
  initializeChatwootEvents,
} from 'dashboard/helper/scriptHelpers.js';
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon.vue';
import VueDOMPurifyHTML from 'vue-dompurify-html';
import { domPurifyConfig } from 'shared/helpers/HTMLSanitizer.js';

import { vResizeObserver } from '@vueuse/components';
import { directive as onClickaway } from 'vue3-click-away';

import 'floating-vue/dist/style.css';

const i18n = createI18n({
  legacy: false, // https://github.com/intlify/vue-i18n/issues/1902
  locale: 'en',
  messages: i18nMessages,
});

const pinia = createPinia();

sync(store, router);

const app = createApp(App);
app.use(i18n);
app.use(store);
app.use(pinia);
app.use(router);

// [VITE] Disabled this, need to renable later
if (window.errorLoggingConfig) {
  Sentry.init({
    app,
    dsn: window.errorLoggingConfig,
    denyUrls: [
      // Chrome extensions
      /^chrome:\/\//i,
      /chrome-extension:/i,
      /extensions\//i,

      // Locally saved copies
      /file:\/\//i,

      // Safari extensions.
      /safari-web-extension:/i,
      /safari-extension:/i,
    ],
    integrations: [Sentry.browserTracingIntegration({ router })],
    ignoreErrors: [
      'ResizeObserver loop completed with undelivered notifications',
    ],
  });
}

app.use(VueDOMPurifyHTML, domPurifyConfig);
app.use(WootUiKit);
app.use(
  plugin,
  defaultConfig({
    rules: {
      JSON: ({ value }) => isJSONValid(value),
    },
  })
);
app.use(FloatingVue, {
  instantMove: true,
  arrowOverflow: false,
  disposeTimeout: 5000000,
  // Use the `fixed` strategy so tooltips are positioned relative to the viewport.
  // With the default `absolute` strategy, a hidden tooltip lingers at a stale offset
  // and adds to the page's scroll height, letting the whole dashboard over-scroll.
  // Fixed elements never affect scroll height, so this can't happen.
  themes: {
    tooltip: {
      strategy: 'fixed',
    },
  },
});
app.use(hljsVuePlugin);

app.component('woot-wizard', WootWizard);
app.component('fluent-icon', FluentIcon);

app.directive('resize', vResizeObserver);
app.directive('on-clickaway', onClickaway);

// load common helpers into js
commonHelpers();
window.WootConstants = constants;
window.axios = createAxios(axios);
// [VITE] Disabled this we don't need it, we can use `useEmitter` directly
// app.prototype.$emitter = emitter;

initializeChatwootEvents();
initializeAnalyticsEvents();
initalizeRouter();

// Mount as soon as the DOM is parsed rather than waiting for `window.onload`.
// `onload` only fires after *every* subresource finishes loading, including the
// large global SCSS stylesheet (tailwind + all plugins). Under Docker Desktop's
// `:cached` bind mount that stylesheet cold-compiles in tens of seconds, so
// `onload` could be delayed long enough that the dashboard stays a white page
// with the app never mounting. Vite serves this entry as a deferred module, so
// `#app` already exists in the DOM by the time this runs.
function mountDashboard() {
  app.mount('#app');
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', mountDashboard);
} else {
  mountDashboard();
}
