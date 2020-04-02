import Vue from 'vue';
import Vuelidate from 'vuelidate';
import VueI18n from 'vue-i18n';
import store from '../widget/store';
import App from '../widget/App.vue';
import router from '../widget/router';
import ActionCableConnector from '../widget/helpers/actionCable';
import i18n from '../widget/i18n';

Vue.use(VueI18n);
Vue.use(Vuelidate);

Vue.config.lang = 'en';
Object.keys(i18n).forEach(lang => {
  Vue.locale(lang, i18n[lang]);
});

Vue.config.productionTip = false;
window.onload = () => {
  window.WOOT_WIDGET = new Vue({
    router,
    store,
    render: h => h(App),
  }).$mount('#app');

  window.actionCable = new ActionCableConnector(
    window.WOOT_WIDGET,
    window.chatwootPubsubToken
  );
};
