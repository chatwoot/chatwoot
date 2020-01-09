import Vue from 'vue';
import Vuelidate from 'vuelidate';
import store from '../widget/store';
import App from '../widget/App.vue';
import router from '../widget/router';
import ActionCableConnector from '../widget/helpers/actionCable';

Vue.use(Vuelidate);

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
