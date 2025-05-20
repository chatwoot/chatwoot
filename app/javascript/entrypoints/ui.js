import { createApp } from 'vue';

import '../dashboard/assets/scss/app.scss';
import 'vue-multiselect/dist/vue-multiselect.css';
import 'floating-vue/dist/style.css';
// import tailwindStyles from '../dashboard/assets/scss/_woot.scss?inline';

import VueDOMPurifyHTML from 'vue-dompurify-html';
import WootUiKit from 'dashboard/components';
import { domPurifyConfig } from '../shared/helpers/HTMLSanitizer.js';

import store from '../dashboard/store';
import constants from '../dashboard/constants/globals';
import axios from 'axios';
import createAxios from '../ui/axios';
import commonHelpers from '../dashboard/helper/commons';
import vueActionCable from '../dashboard/helper/actionCable';

import MessageList from '../ui/MessageList.vue';
import en from '../dashboard/i18n/locale/en';
import { createI18n } from 'vue-i18n';

const i18n = createI18n({
  legacy: false,
  locale: 'en',
  messages: {
    en,
  },
});

export const init = async () => {
  commonHelpers();
  // eslint-disable-next-line no-underscore-dangle
  window.__CHATWOOT_STORE__ = store;
  window.WootConstants = constants;
  window.axios = createAxios(axios);

  return store.dispatch('setUser').then(() => {
    const app = createApp(MessageList);

    app.use(store);
    app.use(i18n);
    app.use(WootUiKit);
    app.use(VueDOMPurifyHTML, domPurifyConfig);
    // eslint-disable-next-line no-underscore-dangle
    vueActionCable.init(store, window.__PUBSUB_TOKEN__);

    app.mount('#app');
  });
};

if (typeof window.chatwootCallback === 'function') {
  window.chatwootCallback(init);
} else {
  init();
}
