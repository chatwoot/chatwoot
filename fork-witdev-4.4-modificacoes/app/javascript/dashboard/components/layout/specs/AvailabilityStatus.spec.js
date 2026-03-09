import { mount } from '@vue/test-utils';
import { createStore } from 'vuex';
import AvailabilityStatus from '../AvailabilityStatus.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';
import WootDropdownHeader from 'shared/components/ui/dropdown/DropdownHeader.vue';
import WootDropdownDivider from 'shared/components/ui/dropdown/DropdownDivider.vue';
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon.vue';

describe('AvailabilityStatus', () => {
  const currentAvailability = 'online';
  const currentAccountId = '1';
  const currentUserAutoOffline = false;
  let store = null;
  let actions = null;

  beforeEach(() => {
    actions = {
      updateAvailability: vi.fn(() => Promise.resolve()),
    };

    store = createStore({
      modules: {
        auth: {
          namespaced: false,
          getters: {
            getCurrentUserAvailability: () => currentAvailability,
            getCurrentAccountId: () => currentAccountId,
            getCurrentUserAutoOffline: () => currentUserAutoOffline,
          },
        },
      },
      actions,
    });
  });

  it('dispatches an action when user changes status', async () => {
    const wrapper = mount(AvailabilityStatus, {
      global: {
        plugins: [store],
        components: {
          NextButton,
          WootDropdownItem,
          WootDropdownMenu,
          WootDropdownHeader,
          WootDropdownDivider,
          FluentIcon,
        },
        stubs: {
          WootSwitch: { template: '<button />' },
        },
      },
    });

    // Ensure that the dropdown menu is opened
    await wrapper.vm.openStatusMenu();

    // Simulate the user clicking the 3rd button (offline status)
    const buttons = wrapper.findAll('.status-change--dropdown-button');
    expect(buttons.length).toBeGreaterThan(0); // Ensure buttons exist

    await buttons[2].trigger('click');

    expect(actions.updateAvailability).toHaveBeenCalledTimes(1);
    expect(actions.updateAvailability.mock.calls[0][1]).toEqual({
      availability: 'offline',
      account_id: currentAccountId,
    });
  });
});
