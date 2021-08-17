import { addDecorator } from '@storybook/vue';
import Vue from 'vue';
import Vuex from 'vuex';
import VueI18n from 'vue-i18n';
import Vuelidate from 'vuelidate';
import Multiselect from 'vue-multiselect';

import WootUiKit from '../app/javascript/dashboard/components';
import i18n from '../app/javascript/dashboard/i18n';

import '../app/javascript/dashboard/assets/scss/storybook.scss';

Vue.use(VueI18n);
Vue.use(Vuelidate);
Vue.use(WootUiKit);
Vue.use(Vuex);
Vue.component('multiselect', Multiselect);

const store = new Vuex.Store({});
const i18nConfig = new VueI18n({
  locale: 'en',
  messages: i18n,
});

addDecorator(() => ({
  template: '<story/>',
  i18n: i18nConfig,
  store,
  beforeCreate: function() {
    this.$root._i18n = this.$i18n;
  },
}));

export const parameters = {
  actions: { argTypesRegex: '^on[A-Z].*' },
  controls: {
    matchers: {
      color: /(background|color)$/i,
      date: /Date$/,
    },
  },
};
