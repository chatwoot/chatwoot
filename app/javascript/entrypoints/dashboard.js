import { createApp } from 'vue';
import { createI18n } from 'vue-i18n';

import axios from 'axios';
// Global Components
import hljs from 'highlight.js';
import Multiselect from 'vue-multiselect';
// import VueFormulate from '@braid/vue-formulate';
import WootSwitch from 'components/ui/Switch.vue';
import WootWizard from 'components/ui/Wizard.vue';
import { sync } from 'vuex-router-sync';
import VTooltip from 'v-tooltip';
import WootUiKit from 'dashboard/components';
import App from 'dashboard/App.vue';
import i18nMessages from 'dashboard/i18n';
import createAxios from 'dashboard/helper/APIHelper';
// import { emitter } from '../shared/helpers/mitt';

// import commonHelpers, { isJSONValid } from 'dashboard/helper/commons';
import commonHelpers from 'dashboard/helper/commons';
import router, { initalizeRouter } from 'dashboard/routes';
import store from 'dashboard/store';
import constants from 'dashboard/constants/globals';
// import * as Sentry from '@sentry/vue';
import 'vue-easytable/libs/theme-default/index.css';
// import { Integrations } from '@sentry/tracing';
import {
  initializeAnalyticsEvents,
  initializeChatwootEvents,
} from 'dashboard/helper/scriptHelpers.js';
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon.vue';
import VueDOMPurifyHTML from 'vue-dompurify-html';
import { domPurifyConfig } from 'shared/helpers/HTMLSanitizer.js';

import resizeDirective from 'dashboard/helper/directives/resize.js';
import { directive as onClickaway } from 'vue3-click-away';

const i18n = createI18n({
  legacy: false, // https://github.com/intlify/vue-i18n/issues/1902
  locale: 'en',
  messages: i18nMessages,
});

const app = createApp(App);
app.use(i18n);
app.use(store);
app.use(router);

// This is used in dashboard/helper/actionCable.js
// Since `app` is not available, we make a "fake" app with $store property
window.WOOT_STORE = store;

// [VITE] Disabled this, need to renable later
// if (window.errorLoggingConfig) {
//   Sentry.init({
//     Vue,
//     dsn: window.errorLoggingConfig,
//     denyUrls: [
//       // Chrome extensions
//       /^chrome:\/\//i,
//       /chrome-extension:/i,
//       /extensions\//i,

//       // Locally saved copies
//       /file:\/\//i,

//       // Safari extensions.
//       /safari-web-extension:/i,
//       /safari-extension:/i,
//     ],
//     integrations: [new Integrations.BrowserTracing()],
//     ignoreErrors: [
//       'ResizeObserver loop completed with undelivered notifications',
//     ],
//   });
// }

app.use(VueDOMPurifyHTML, domPurifyConfig);
app.use(WootUiKit);
// app.use(VueFormulate, {
//   rules: {
//     JSON: ({ value }) => isJSONValid(value),
//   },
// });
app.use(VTooltip, {
  defaultHtml: false,
});
app.use(hljs.vuePlugin);

app.component('multiselect', Multiselect);
app.component('woot-switch', WootSwitch);
app.component('woot-wizard', WootWizard);
app.component('fluent-icon', FluentIcon);

app.directive('resize', resizeDirective);
app.directive('on-clickaway', onClickaway);

sync(store, router);
// load common helpers into js
commonHelpers();

window.WootConstants = constants;
window.axios = createAxios(axios);
// [VITE] Disabled this, need to renable later
// app.prototype.$emitter = emitter;

initializeChatwootEvents();
initializeAnalyticsEvents();
initalizeRouter();

window.onload = () => {
  app.mount('#app');
};

window.addEventListener('load', () => {
  window.playAudioAlert = () => {};
});
