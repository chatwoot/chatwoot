import { createApp, h } from 'vue';
import { createI18n } from 'vue-i18n';
import vuetify from 'weave/plugins/vuetify';

const i18n = createI18n({
  legacy: false,
  locale: 'en_GB',
  fallbackLocale: 'en',
  messages: { en: {} },
});

const Root = { render: () => h('div', 'Weave Admin Portal') };

window.onload = () => {
  const el = document.querySelector('#app');
  if (!el) return;
  const app = createApp(Root);
  app.use(i18n);
  app.use(vuetify);
  app.mount('#app');
};

