import Vue from 'vue';
import Vuelidate from 'vuelidate';
import VueI18n from 'vue-i18n';
import App from '../service/App.vue';
import i18n from '../service/i18n';

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
  window.WOOT_SERVICE = new Vue({
    i18n: i18nConfig,
    render: h => h(App),
  }).$mount('#app');
};
