import { shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';

import DateSeparator from '../DateSeparator.vue';

describe('DateSeparator', () => {
  let store = null;
  let actions = null;
  let modules = null;
  let dateSeparator = null;

  beforeEach(() => {
    actions = {};

    modules = {
      auth: {
        namespaced: true,
        getters: {
          'appConfig/darkMode': () => 'light',
        },
      },
    };

    store = createStore({
      modules,
      actions,
    });

    dateSeparator = shallowMount(DateSeparator, {
      global: {
        plugins: [store],
        mocks: {
          $t: msg => msg, // Mocking $t function for translations
        },
      },
      props: {
        date: 'Nov 18, 2019',
      },
    });
  });

  it('date separator snapshot', () => {
    expect(dateSeparator.vm).toBeTruthy();
    expect(dateSeparator.element).toMatchSnapshot();
  });
});
