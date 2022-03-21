import Vue from 'vue';
import Vuelidate from 'vuelidate';
import VueI18n from 'vue-i18n';
import VueFormulate from '@braid/vue-formulate';
import store from '../widget/store';
import App from '../widget/App.vue';
import ActionCableConnector from '../widget/helpers/actionCable';
import i18n from '../widget/i18n';
import { isPhoneE164OrEmpty } from 'shared/helpers/Validators';
import router from '../widget/router';
Vue.use(VueI18n);
Vue.use(Vuelidate);

const i18nConfig = new VueI18n({
  locale: 'en',
  messages: i18n,
});
Vue.use(VueFormulate, {
  rules: {
    isPhoneE164OrEmpty: ({ value }) => isPhoneE164OrEmpty(value),
  },
  classes: {
    outer: 'mb-4',
    input(context) {
      const { hasErrors } = context;
      if (!hasErrors) {
        return 'mt-2 border rounded w-full py-2 px-3 text-slate-700 leading-tight outline-none border-black-200 hover:border-black-300 focus:border-black-300';
      }
      return 'mt-2 border rounded w-full py-2 px-3 text-slate-700 leading-tight outline-none border-red-200 hover:border-red-300 focus:border-red-300';
    },
    label(context) {
      const { hasErrors } = context;
      if (!hasErrors) {
        return 'text-xs font-medium text-black-800';
      }
      return 'text-xs font-medium text-red-400';
    },
    error: 'text-red-400 mt-2 text-xs font-medium',
  },
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
