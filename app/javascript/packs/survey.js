import Vue from 'vue';
import Vuelidate from 'vuelidate';
import VueI18n from 'vue-i18n';
import App from '../survey/App.vue';
import i18n from '../survey/i18n';
import store from '../survey/store';

Vue.use(VueI18n);
Vue.use(Vuelidate);

const i18nConfig = new VueI18n({
  locale: 'en',
  messages: i18n,
});

// Event Bus
window.bus = new Vue();

Vue.config.productionTip = false;

window.onload = () => {
  window.WOOT_SURVEY = new Vue({
    i18n: i18nConfig,
    store,
    render: h => h(App),
  }).$mount('#app');
};
