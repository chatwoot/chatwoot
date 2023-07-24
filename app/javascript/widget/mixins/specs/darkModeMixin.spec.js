import { shallowMount, createLocalVue } from '@vue/test-utils';
import darkModeMixin from '../darkModeMixin';
import Vuex from 'vuex';
const localVue = createLocalVue();
localVue.use(Vuex);

const darkModeValues = ['light', 'auto'];

describe('darkModeMixin', () => {
  let getters;
  let store;
  beforeEach(() => {
    getters = {
      'appConfig/darkMode': () => darkModeValues[0],
    };
    store = new Vuex.Store({ getters });
  });

  it('if light theme', () => {
    const Component = {
      render() {},
      mixins: [darkModeMixin],
    };
    const wrapper = shallowMount(Component, { store, localVue });
    expect(wrapper.vm.$dm('bg-100', 'bg-600')).toBe('bg-100');
  });

  it('if auto theme', () => {
    getters = {
      'appConfig/darkMode': () => darkModeValues[2],
    };
    store = new Vuex.Store({ getters });

    const Component = {
      render() {},
      mixins: [darkModeMixin],
    };
    const wrapper = shallowMount(Component, { store, localVue });
    expect(wrapper.vm.$dm('bg-100', 'bg-600')).toBe('bg-100 bg-600');
  });
});
