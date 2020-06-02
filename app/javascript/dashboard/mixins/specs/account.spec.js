import { shallowMount, createLocalVue } from '@vue/test-utils';
import accountMixin from '../account';
import Vuex from 'vuex';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('accountMixin', () => {
  let getters;
  let store;

  beforeEach(() => {
    getters = {
      getCurrentAccountId: () => 1,
    };

    store = new Vuex.Store({ getters });
  });

  it('set accountId properly', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [accountMixin],
    };
    const wrapper = shallowMount(Component, { store, localVue });
    expect(wrapper.vm.accountId).toBe(1);
  });

  it('returns current url', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [accountMixin],
    };

    const wrapper = shallowMount(Component, { store, localVue });
    expect(wrapper.vm.addAccountScoping('settings/inboxes/new')).toBe(
      '/app/accounts/1/settings/inboxes/new'
    );
  });
});
