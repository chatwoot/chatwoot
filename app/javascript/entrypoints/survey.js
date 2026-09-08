import { createApp } from 'vue';
import { createI18n } from 'vue-i18n';
import VueDOMPurifyHTML from 'vue-dompurify-html';
import store from '../survey/store';
import i18nMessages from '../survey/i18n';
import App from '../survey/App.vue';
import { domPurifyConfig } from '../shared/helpers/HTMLSanitizer';

const app = createApp(App);
const i18n = createI18n({
  locale: 'en',
  messages: i18nMessages,
});

app.use(i18n);
app.use(store);
app.use(VueDOMPurifyHTML, domPurifyConfig);

window.onload = () => {
  window.WOOT_SURVEY = app.mount('#app');
};
