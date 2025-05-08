import { defineCustomElement } from 'vue';
import { createI18n } from 'vue-i18n';

import '../dashboard/assets/scss/app.scss';
import 'vue-multiselect/dist/vue-multiselect.css';
import 'floating-vue/dist/style.css';
// Import Tailwind styles - we'll use these in the shadow DOM
import tailwindStyles from '../dashboard/assets/scss/_woot.scss?inline';

import store from 'dashboard/store';
import constants from 'dashboard/constants/globals';
import axios from 'axios';
import createAxios from 'dashboard/helper/APIHelper';
import commonHelpers from 'dashboard/helper/commons';
import i18nMessages from 'dashboard/i18n';

import WootButton from '../dashboard/components-next/button/Button.vue';
import WootInput from '../dashboard/components-next/input/Input.vue';
import WootMessage from '../dashboard/components-next/message/Message.vue';

const i18n = createI18n({
  legacy: false,
  locale: 'en',
  messages: i18nMessages,
});

const ceOptions = {
  configureApp(app) {
    app.use(i18n);
    app.use(store);
  },
  // Include tailwind styles in the shadow DOM of each custom element
  styles: [tailwindStyles],
};

commonHelpers();
window.WootConstants = constants;
window.axios = createAxios(axios);

export const buttonElement = defineCustomElement(WootButton, ceOptions);
export const inputElement = defineCustomElement(WootInput, ceOptions);
export const messageElement = defineCustomElement(WootMessage, ceOptions);

// eslint-disable-next-line no-underscore-dangle
window.__CHATWOOT_STORE__ = store;
customElements.define('woot-button', buttonElement);
customElements.define('woot-input', inputElement);
customElements.define('woot-message', messageElement);
