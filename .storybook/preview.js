import { addDecorator } from '@storybook/vue';
import Vue from 'vue';
import VueI18n from 'vue-i18n';

import WootUiKit from '../app/javascript/dashboard/components';
import i18n from '../app/javascript/dashboard/i18n';
import store from '../app/javascript/dashboard/store';

import '../app/javascript/dashboard/assets/scss/storybook.scss';

Vue.use(VueI18n);
Vue.use(WootUiKit);
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
