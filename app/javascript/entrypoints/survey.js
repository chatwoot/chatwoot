import { createApp } from 'vue';
import { createI18n } from 'vue-i18n';
import store from '../survey/store';
import i18nMessages from '../survey/i18n';
import App from '../survey/App.vue';
import * as Sentry from '@sentry/vue';

const app = createApp(App);

Sentry.init({
  app,
  dsn: 'https://db65c8821fe1ce0f7315a1d36895cc5d@o4509088540262400.ingest.de.sentry.io/4510198682615888',
  sendDefaultPii: true,
  tracesSampleRate: 0.2,
  ignoreErrors: [
    'ResizeObserver loop completed with undelivered notifications',
  ],
});

const i18n = createI18n({
  locale: 'en',
  messages: i18nMessages,
});

app.use(i18n);
app.use(store);

window.onload = () => {
  window.WOOT_SURVEY = app.mount('#app');
};
