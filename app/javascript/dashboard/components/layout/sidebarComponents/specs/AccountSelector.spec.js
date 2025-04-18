import { mount } from '@vue/test-utils';
import { createStore } from 'vuex';
import AccountSelector from '../AccountSelector.vue';
import WootModal from 'dashboard/components/Modal.vue';
import WootModalHeader from 'dashboard/components/ModalHeader.vue';
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon.vue';

const store = createStore({
  modules: {
    auth: {
      namespaced: false,
      getters: {
        getCurrentAccountId: () => 1,
        getCurrentUser: () => ({
          accounts: [
            { id: 1, name: 'Chatwoot', role: 'administrator' },
            { id: 2, name: 'GitX', role: 'agent' },
          ],
        }),
      },
    },
    globalConfig: {
      namespaced: true,
      getters: {
        get: () => ({ createNewAccountFromDashboard: false }),
      },
    },
  },
});

describe('AccountSelector', () => {
  let accountSelector = null;

  beforeEach(() => {
    accountSelector = mount(AccountSelector, {
      global: {
        plugins: [store],
        components: {
          'woot-modal': WootModal,
          'woot-modal-header': WootModalHeader,
          'fluent-icon': FluentIcon,
        },
        stubs: {
          // override global stub
          WootModalHeader: false,
        },
      },
      props: { showAccountModal: true },
    });
  });

  it('title and sub title exist', () => {
    const headerComponent = accountSelector.findComponent(WootModalHeader);
    const title = headerComponent.find('[data-test-id="modal-header-title"]');
    expect(title.text()).toBe('Switch account');
    const content = headerComponent.find(
      '[data-test-id="modal-header-content"]'
    );
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
