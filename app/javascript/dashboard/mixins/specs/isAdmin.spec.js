import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import isAdminMixin from '../isAdmin';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('isAdminMixin', () => {
  let getters;
  let store;

  beforeEach(() => {
    getters = {
      getCurrentRole: () => 'administrator',
    };

    store = new Vuex.Store({ getters });
  });
  it('set accountId properly', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [isAdminMixin],
    };
    const wrapper = shallowMount(Component, { store, localVue });
    expect(wrapper.vm.isAdmin).toBe(true);
  });
});
