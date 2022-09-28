import Vue from 'vue';
import Vuelidate from 'vuelidate';
import VueI18n from 'vue-i18n';
import VueDOMPurifyHTML from 'vue-dompurify-html';
import VueFormulate from '@braid/vue-formulate';
import store from '../widget/store';
import App from '../widget/App.vue';
import ActionCableConnector from '../widget/helpers/actionCable';
import i18n from '../widget/i18n';
import { isPhoneE164OrEmpty } from 'shared/helpers/Validators';
import router from '../widget/router';
import { domPurifyConfig } from '../shared/helpers/HTMLSanitizer';
Vue.use(VueI18n);
Vue.use(Vuelidate);
Vue.use(VueDOMPurifyHTML, domPurifyConfig);

const i18nConfig = new VueI18n({
  locale: 'en',
  messages: i18n,
});
Vue.use(VueFormulate, {
  rules: {
    isPhoneE164OrEmpty: ({ value }) => isPhoneE164OrEmpty(value),
  },
  classes: {
    outer: 'mb-4 wrapper',
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
