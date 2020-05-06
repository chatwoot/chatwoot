import { createWrapper } from '@vue/test-utils';
import accountMixin from '../account';
import Vue from 'vue';

jest.mock('../../api/auth', () => ({
  getCurrentUser: () => ({ account_id: 1 }),
}));

describe('accountMixin', () => {
  test('set accountId properly', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [accountMixin],
    };
    const Constructor = Vue.extend(Component);
    const vm = new Constructor().$mount();
    const wrapper = createWrapper(vm);
    expect(wrapper.vm.accountId).toBe(1);
  });

  test('returns current url', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [accountMixin],
    };
    const Constructor = Vue.extend(Component);
    const vm = new Constructor().$mount();
    const wrapper = createWrapper(vm);
    expect(wrapper.vm.addAccountScoping('settings/inboxes/new')).toBe(
      '/app/accounts/1/settings/inboxes/new'
    );
  });
});
