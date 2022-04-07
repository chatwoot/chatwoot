import Vue from 'vue';
import Vuelidate from 'vuelidate';
import VueI18n from 'vue-i18n';
import VueDOMPurifyHTML from 'vue-dompurify-html';
import store from '../widget/store';
import App from '../widget/App.vue';
import ActionCableConnector from '../widget/helpers/actionCable';
import i18n from '../widget/i18n';

import router from '../widget/router';
Vue.use(VueI18n);
Vue.use(Vuelidate);
Vue.use(VueDOMPurifyHTML);

const i18nConfig = new VueI18n({
  locale: 'en',
  messages: i18n,
});

// Event Bus
window.bus = new Vue();

Vue.config.productionTip = false;

window.onload = () => {
  window.WOOT_WIDGET = new Vue({
    router,
    store,
    i18n: i18nConfig,
    render: h => h(App),
  }).$mount('#app');

  window.actionCable = new ActionCableConnector(
    window.WOOT_WIDGET,
    window.chatwootPubsubToken
  );
};
