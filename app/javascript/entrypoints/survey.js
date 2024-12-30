import { createApp } from 'vue';
import { createI18n } from 'vue-i18n';
import store from '../survey/store';
import enMessages from 'survey/i18n/locale/en.json';
import App from '../survey/App.vue';

const app = createApp(App);
const i18n = createI18n({
  legacy: false, // https://github.com/intlify/vue-i18n/issues/1902
  locale: 'en',
  messages: { en: enMessages },
});

app.use(i18n);
app.use(store);

window.onload = () => {
  window.WOOT_SURVEY = app.mount('#app');
};
