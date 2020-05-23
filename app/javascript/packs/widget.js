import Vue from 'vue';
import Vuelidate from 'vuelidate';
import VueI18n from 'vue-i18n';
import store from '../widget/store';
import App from '../widget/App.vue';
import router from '../widget/router';
import ActionCableConnector from '../widget/helpers/actionCable';
import { translations } from '../widget/i18n';

Vue.use(VueI18n);
Vue.use(Vuelidate);

export const i18n = new VueI18n({
  locale: 'en',
  fallbackLocale: 'en',
  messages: translations,
});

Vue.config.productionTip = false;
window.onload = () => {
  window.WOOT_WIDGET = new Vue({
    i18n,
    router,
    store,
    render: h => h(App),
  }).$mount('#app');

  window.actionCable = new ActionCableConnector(
    window.WOOT_WIDGET,
    window.chatwootPubsubToken
  );
};
