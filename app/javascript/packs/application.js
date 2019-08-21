/* eslint no-console: 0 */
/* eslint-env browser */
/* eslint-disable no-new */
/* Vue Core */

import Vue from 'vue';
import VueI18n from 'vue-i18n';
import VueRouter from 'vue-router';
import axios from 'axios';
// Global Components
import Multiselect from 'vue-multiselect';
import WootSwitch from 'components/ui/Switch';
import WootWizard from 'components/ui/Wizard';
import { sync } from 'vuex-router-sync';
import Vuelidate from 'vuelidate';
import VTooltip from 'v-tooltip';

import WootUiKit from '../src/components';
import App from '../src/App';
import i18n from '../src/i18n';
import createAxios from '../src/helper/APIHelper';
import commonHelpers from '../src/helper/commons';
import router from '../src/routes';
import store from '../src/store';
import vuePusher from '../src/helper/pusher';
import constants from '../src/constants';

Vue.config.env = process.env;

Vue.use(VueRouter);
Vue.use(VueI18n);
Vue.use(WootUiKit);
Vue.use(Vuelidate);
Vue.use(VTooltip);

Vue.component('multiselect', Multiselect);
Vue.component('woot-switch', WootSwitch);
Vue.component('woot-wizard', WootWizard);

Object.keys(i18n).forEach(lang => {
  Vue.locale(lang, i18n[lang]);
});

Vue.config.lang = 'en';
sync(store, router);
// load common helpers into js
commonHelpers();

window.WootConstants = constants;
window.axios = createAxios(axios);
window.bus = new Vue();
window.onload = () => {
  window.WOOT = new Vue({
    router,
    store,
    template: '<App/>',
    components: { App },
  }).$mount('#app');
};
window.pusher = vuePusher.init();
