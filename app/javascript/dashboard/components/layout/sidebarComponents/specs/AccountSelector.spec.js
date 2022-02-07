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
  const accountId = 1;
  const globalConfig = { createNewAccountFromDashboard: false };
  let store = null;
  let actions = null;
  let modules = null;

  beforeEach(() => {
    actions = {};
    modules = {
      auth: {
        getters: {
          getCurrentAccountId: () => accountId,
          getCurrentUser: () => currentUser,
        },
      },
      globalConfig: {
        getters: {
          'globalConfig/get': () => globalConfig,
        },
      },
    };

    store = new Vuex.Store({
      actions,
      modules,
    });
    accountSelector = mount(AccountSelector, {
      store,
      localVue,
      i18n: i18nConfig,
      propsData: {
        showAccountModal: true,
      },
    });
  });

  it('title and sub title exist', () => {
    const headerComponent = accountSelector.findComponent(WootModalHeader);
    const topBar = headerComponent.find('.page-top-bar');
    const titleComponent = topBar.find('.page-sub-title');
    expect(titleComponent.text()).toBe('Switch Account');
    const subTitleComponent = topBar.find('p');
    expect(subTitleComponent.text()).toBe(
      'Select an account from the following list'
    );
  });

  it('first account item is checked', () => {
    const accountFirstItem = accountSelector.find('.account-selector svg');
    expect(accountFirstItem.exists()).toBe(true);
  });
});
