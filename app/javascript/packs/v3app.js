import Vue from 'vue';
import VueI18n from 'vue-i18n';
import VueRouter from 'vue-router';
import Vuelidate from 'vuelidate';
import i18n from 'dashboard/i18n';
import * as Sentry from '@sentry/vue';
import { Integrations } from '@sentry/tracing';
import {
  initializeAnalyticsEvents,
  initializeChatwootEvents,
} from 'dashboard/helper/scriptHelpers';
import AnalyticsPlugin from 'dashboard/helper/AnalyticsHelper/plugin';
import App from '../v3/App.vue';
import router, { initalizeRouter } from '../v3/views/index';
import store from '../v3/store';
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon';

Vue.config.env = process.env;

if (window.errorLoggingConfig) {
  Sentry.init({
    Vue,
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
    integrations: [new Integrations.BrowserTracing()],
    ignoreErrors: [
      'ResizeObserver loop completed with undelivered notifications',
    ],
  });
}

Vue.use(VueRouter);
Vue.use(VueI18n);
Vue.use(Vuelidate);
Vue.use(AnalyticsPlugin);
Vue.component('fluent-icon', FluentIcon);

const i18nConfig = new VueI18n({ locale: 'en', messages: i18n });

window.bus = new Vue();
initializeChatwootEvents();
initializeAnalyticsEvents();
initalizeRouter();
window.onload = () => {
  new Vue({
    router,
    store,
    i18n: i18nConfig,
    components: { App },
    template: '<App/>',
  }).$mount('#app');
};
