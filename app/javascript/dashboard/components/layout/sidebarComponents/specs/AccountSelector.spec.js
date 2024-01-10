import AccountSelector from '../AccountSelector';
import { createLocalVue, mount } from '@vue/test-utils';
import Vuex from 'vuex';
import VueI18n from 'vue-i18n';

import i18n from 'dashboard/i18n';
import WootModal from 'dashboard/components/Modal';
import WootModalHeader from 'dashboard/components/ModalHeader';
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon';

const localVue = createLocalVue();
localVue.component('woot-modal', WootModal);
localVue.component('woot-modal-header', WootModalHeader);
localVue.component('fluent-icon', FluentIcon);

localVue.use(Vuex);
localVue.use(VueI18n);

const i18nConfig = new VueI18n({
  locale: 'en',
  messages: i18n,
});

describe('accountSelctor', () => {
  let accountSelector = null;
  const currentUser = {
    accounts: [
      {
        id: 1,
        name: 'Chatwoot',
        role: 'administrator',
      },
      {
        id: 2,
        name: 'GitX',
        role: 'agent',
      },
    ],
  };

  let actions = null;
  let modules = null;

  beforeEach(() => {
    actions = {};
    modules = {
      auth: {
        getters: {
          getCurrentAccountId: () => 1,
          getCurrentUser: () => currentUser,
        },
      },
      globalConfig: {
        getters: {
          'globalConfig/get': () => ({ createNewAccountFromDashboard: false }),
        },
      },
    };

    let store = new Vuex.Store({ actions, modules });
    accountSelector = mount(AccountSelector, {
      store,
      localVue,
      i18n: i18nConfig,
      propsData: { showAccountModal: true },
      stubs: { WootButton: { template: '<button />' } },
    });
  });

  it('title and sub title exist', () => {
    const headerComponent = accountSelector.findComponent(WootModalHeader);
    const title = headerComponent.findComponent({ ref: 'modalHeaderTitle' });
    expect(title.text()).toBe('Switch Account');
    const content = headerComponent.findComponent({
      ref: 'modalHeaderContent',
    });
    expect(content.text()).toBe('Select an account from the following list');
  });

  it('first account item is checked', () => {
    const selectedAccountCheckmark = accountSelector.find(
      '#account-1 > button > svg'
    );
    expect(selectedAccountCheckmark.exists()).toBe(true);

    const otherAccountCheckmark = accountSelector.find(
      '#account-2 > button > svg'
    );
    expect(otherAccountCheckmark.exists()).toBe(true);
  });
});
