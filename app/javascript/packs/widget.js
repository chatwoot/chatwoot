import Vue from 'vue';
import VueI18n from 'vue-i18n';
import VueDOMPurifyHTML from 'vue-dompurify-html';
import VueFormulate from '@braid/vue-formulate';
import store from '../widget/store';
import App from '../widget/App.vue';
import ActionCableConnector from '../widget/helpers/actionCable';
import i18n from '../widget/i18n';
import {
  startsWithPlus,
  isPhoneNumberValidWithDialCode,
} from 'shared/helpers/Validators';
import router from '../widget/router';
import { directive as onClickaway } from 'vue-clickaway';
import { emitter } from 'shared/helpers/mitt';
import { domPurifyConfig } from '../shared/helpers/HTMLSanitizer';
const PhoneInput = () => import('../widget/components/Form/PhoneInput');

Vue.use(VueI18n);

Vue.use(VueDOMPurifyHTML, domPurifyConfig);
Vue.directive('on-clickaway', onClickaway);

const i18nConfig = new VueI18n({
  locale: 'en',
  messages: i18n,
});
Vue.use(VueFormulate, {
  library: {
    phoneInput: {
      classification: 'number',
      component: PhoneInput,
      slotProps: {
        component: ['placeholder', 'hasErrorInPhoneInput'],
      },
    },
  },
  rules: {
    startsWithPlus: ({ value }) => startsWithPlus(value),
    isValidPhoneNumber: ({ value }) => isPhoneNumberValidWithDialCode(value),
  },
  classes: {
    outer: 'mb-2 wrapper',
    error: 'text-red-400 mt-2 text-xs leading-3 font-medium',
  },
});
// Event Bus
Vue.prototype.$emitter = emitter;

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
