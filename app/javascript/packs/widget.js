import Vue from 'vue';
import Vuelidate from 'vuelidate';
import VueI18n from 'vue-i18n';
import store from '../widget/store';
import App from '../widget/App.vue';
import ActionCableConnector from '../widget/helpers/actionCable';
import { getAlertAudio } from 'shared/helpers/AudioNotificationHelper';
import i18n from '../widget/i18n';

import router from '../widget/router';
Vue.use(VueI18n);
Vue.use(Vuelidate);

const i18nConfig = new VueI18n({
  locale: 'en',
  messages: i18n,
});

// Event Bus
window.bus = new Vue();

Vue.config.productionTip = false;

const events = [
  'click',
  'touchstart',
  'touchend',
  'touchmove',
  'mousedown',
  'keydown',
  'mousemove',
  'mouseover',
];

const body = window.parent.document.body;

let getAudio = () => {
  getAlertAudio().then(
    events.forEach(e => {
      body.removeEventListener(e, getAudio, false);
    })
  );
};

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

  window.playAudioAlert = () => {};

  events.forEach(e => {
    body.addEventListener(e, getAudio, false);
  });
};
