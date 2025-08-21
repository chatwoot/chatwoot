import { createApp } from 'vue';
import { createI18n } from 'vue-i18n';

import VueDOMPurifyHTML from 'vue-dompurify-html';
import store from '../widget/store';
import App from '../widget/App.vue';
import ActionCableConnector from '../widget/helpers/actionCable';
import i18nMessages from '../widget/i18n';
import router from '../widget/router';
import { directive as onClickaway } from 'vue3-click-away';
import { domPurifyConfig } from '../shared/helpers/HTMLSanitizer';
import { plugin, defaultConfig } from '@formkit/vue';

import {
  startsWithPlus,
  isPhoneNumberValidWithDialCode,
} from 'shared/helpers/Validators';

const i18n = createI18n({
  legacy: false, // https://github.com/intlify/vue-i18n/issues/1902
  locale: 'en',
  messages: i18nMessages,
});

const app = createApp(App);
app.use(i18n);
app.use(store);
app.use(router);
app.use(VueDOMPurifyHTML, domPurifyConfig);
app.directive('on-clickaway', onClickaway);

app.use(
  plugin,
  defaultConfig({
    rules: {
      startsWithPlus: ({ value }) => startsWithPlus(value),
      isValidPhoneNumber: ({ value }) => isPhoneNumberValidWithDialCode(value),
    },
  })
);

// Event Bus
// We can use the useEmitter directly
// Vue.prototype.$emitter = emitter;

// Vue.config.productionTip = false;

window.onload = () => {
  window.WOOT_WIDGET = app.mount('#app');
  window.actionCable = new ActionCableConnector(
    window.WOOT_WIDGET,
    window.chatwootPubsubToken
  );
};
