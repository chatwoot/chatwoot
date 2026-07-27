import { createApp } from 'vue';
import { createPinia } from 'pinia';
import { createI18n } from 'vue-i18n';
import VueDOMPurifyHTML from 'vue-dompurify-html';
import { domPurifyConfig } from 'shared/helpers/HTMLSanitizer';
import App from 'widget-v2/App.vue';
import router from 'widget-v2/router';
import { messages } from 'widget-v2/i18n';
import { connectCable } from 'widget-v2/helpers/cable';
import 'widget-v2/assets/styles/widget-v2.scss';

const i18n = createI18n({
  legacy: false,
  locale: 'en',
  fallbackLocale: 'en',
  messages,
});

const app = createApp(App);
app.use(createPinia());
app.use(i18n);
app.use(router);
app.use(VueDOMPurifyHTML, domPurifyConfig);

window.onload = () => {
  app.mount('#app');
  if (window.chatwootPubsubToken) {
    window.chatwootCable = connectCable(window.chatwootPubsubToken);
  }
};
