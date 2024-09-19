import DateSeparator from '../DateSeparator.vue';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import VueI18n from 'vue-i18n';
import darkModeMixin from 'widget/mixins/darkModeMixin.js';
const localVue = createLocalVue();
import i18n from 'dashboard/i18n';
localVue.use(Vuex);
localVue.use(VueI18n);

const i18nConfig = new VueI18n({
  locale: 'en',
  messages: i18n,
});

describe('dateSeparator', () => {
  let store = null;
  let actions = null;
  let modules = null;
  let dateSeparator = null;

  beforeEach(() => {
    actions = {};

    modules = {
      auth: {
        getters: {
          'appConfig/darkMode': () => 'light',
        },
      },
    };
    store = new Vuex.Store({
      actions,
      modules,
    });

    dateSeparator = shallowMount(DateSeparator, {
      store,
      localVue,
      propsData: { date: 'Nov 18, 2019' },
      mocks: { $t: msg => msg },
      i18n: i18nConfig,
      mixins: [darkModeMixin],
    });
  });

  it('date separator snapshot', () => {
    expect(dateSeparator.vm).toBeTruthy();
    expect(dateSeparator.element).toMatchSnapshot();
  });
});
