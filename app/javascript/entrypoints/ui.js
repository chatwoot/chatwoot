import { defineCustomElement } from 'vue';

import '../dashboard/assets/scss/app.scss';
import 'vue-multiselect/dist/vue-multiselect.css';
import 'floating-vue/dist/style.css';
// Import Tailwind styles - we'll use these in the shadow DOM
import tailwindStyles from '../dashboard/assets/scss/_woot.scss?inline';

import VueDOMPurifyHTML from 'vue-dompurify-html';
import { domPurifyConfig } from '../shared/helpers/HTMLSanitizer.js';

import store from '../dashboard/store';
import constants from '../dashboard/constants/globals';
import axios from 'axios';
import createAxios from '../ui/axios';
import commonHelpers from '../dashboard/helper/commons';
import vueActionCable from '../dashboard/helper/actionCable';

import MessageList from '../ui/MessageList.vue';
import i18nMessages from '../dashboard/i18n';
import { createI18n, I18nInjectionKey } from 'vue-i18n';

const i18n = createI18n({
  legacy: false,
  locale: 'en',
  messages: i18nMessages,
});

const ceOptions = {
  configureApp(app) {
    app.use(store);
    app.use(i18n);
    app.use(VueDOMPurifyHTML, domPurifyConfig);
    // eslint-disable-next-line no-underscore-dangle
    vueActionCable.init(store, window.__PUBSUB_TOKEN__);
    // I18n has to be injected inside that can be picked
    // up by the compononent, the API stays the same, just use `useI18n`
    // https://vue-i18n.intlify.dev/guide/advanced/wc
    // Adding this link for my goldfish brain
    app.provide(I18nInjectionKey, i18n);
  },
  // Include tailwind styles in the shadow DOM of each custom element
  styles: [tailwindStyles],
};

commonHelpers();
window.WootConstants = constants;
window.axios = createAxios(axios);

export const messageListElement = defineCustomElement(MessageList, ceOptions);

// eslint-disable-next-line no-underscore-dangle
window.__CHATWOOT_STORE__ = store;
customElements.define('woot-message-list', messageListElement);
