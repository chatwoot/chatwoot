import { defineCustomElement } from 'vue';

import '../dashboard/assets/scss/app.scss';
import 'vue-multiselect/dist/vue-multiselect.css';
import 'floating-vue/dist/style.css';

import store from 'dashboard/store';
import constants from 'dashboard/constants/globals';
import axios from 'axios';
import createAxios from 'dashboard/helper/APIHelper';
import commonHelpers from 'dashboard/helper/commons';

import ChatButton from '../ui/ChatButton.vue';
import WootInput from '../dashboard/components-next/input/Input.vue';

commonHelpers();
window.WootConstants = constants;
window.axios = createAxios(axios);

export const buttonElement = defineCustomElement(ChatButton);
export const inputElement = defineCustomElement(WootInput);

// eslint-disable-next-line no-underscore-dangle
window.__CHATWOOT_STORE__ = store;
customElements.define('woot-button', buttonElement);
customElements.define('woot-input', inputElement);

export { store, ChatButton };
