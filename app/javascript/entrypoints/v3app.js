import { createApp } from 'vue';
import { createI18n } from 'vue-i18n';

import i18nMessages from 'dashboard/i18n';
import * as Sentry from '@sentry/vue';
import {
  initializeAnalyticsEvents,
  initializeChatwootEvents,
} from 'dashboard/helper/scriptHelpers';
import App from '../v3/App.vue';
import router, { initalizeRouter } from '../v3/views/index';
import store from '../v3/store';
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon.vue';
// import { emitter } from '../shared/helpers/mitt';

// [VITE] This was added in https://github.com/chatwoot/chatwoot/commit/b57063a8b83c86819bd285f481298d7cd38ad50e
// Commenting it out for Vite migration
// Vue.config.env = process.env;

const i18n = createI18n({
  legacy: false, // https://github.com/intlify/vue-i18n/issues/1902
  locale: 'en',
  messages: i18nMessages,
});

const app = createApp(App);
app.use(i18n);
app.use(store);
app.use(router);

// Vue.use(VueRouter);
// Vue.use(VueI18n);
// Vue.prototype.$emitter = emitter;
app.component('fluent-icon', FluentIcon);

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

initializeChatwootEvents();
initializeAnalyticsEvents();
initalizeRouter();

window.onload = () => {
  app.mount('#app');
};
