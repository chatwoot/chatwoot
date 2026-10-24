import { mount } from '@vue/test-utils';
import { createStore } from 'vuex';
import { withFullI18n } from 'test-i18n';
import { useAlert } from 'dashboard/composables';
import SidebarProfileMenuStatus from '../SidebarProfileMenuStatus.vue';

withFullI18n();

const impersonation = vi.hoisted(() => ({ isImpersonating: { value: false } }));

vi.mock('dashboard/composables/useImpersonation', () => ({
  useImpersonation: () => impersonation,
}));

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

const ToggleSwitchStub = {
  props: ['modelValue'],
  emits: ['update:modelValue'],
  template:
    '<button class="toggle" @click="$emit(\'update:modelValue\', !modelValue)" />',
};

const mountStatus = ({ availability = 'online', hasVoiceInbox = true }) => {
  const dispatch = vi.fn();
  const store = createStore({
    getters: {
      getCurrentUserAvailability: () => availability,
      getCurrentAccountId: () => 1,
      getCurrentUserAutoOffline: () => true,
      getCurrentUserAcceptsConversations: () => true,
      getCurrentUserAcceptsCalls: () => true,
    },
  });
  store.dispatch = dispatch;

  const wrapper = mount(SidebarProfileMenuStatus, {
    props: { hasVoiceInbox },
    global: {
      plugins: [store],
      stubs: {
        DropdownSection: { template: '<div><slot /></div>' },
        DropdownContainer: { template: '<div />' },
        DropdownItem: { template: '<div class="item"><slot /></div>' },
        Icon: true,
        ToggleSwitch: ToggleSwitchStub,
      },
    },
  });

  return { wrapper, dispatch };
};

describe('SidebarProfileMenuStatus', () => {
  beforeEach(() => {
    impersonation.isImpersonating.value = false;
  });

  it('shows the conversations and calls toggles when online with a voice inbox', () => {
    const { wrapper } = mountStatus({});

    expect(wrapper.text()).toContain('Receive conversations');
    expect(wrapper.text()).toContain('Receive calls');
  });

  it('hides the calls toggle without a voice inbox', () => {
    const { wrapper } = mountStatus({ hasVoiceInbox: false });

    expect(wrapper.text()).toContain('Receive conversations');
    expect(wrapper.text()).not.toContain('Receive calls');
  });

  it('shows a paused note instead of the toggles when not online', () => {
    const { wrapper } = mountStatus({ availability: 'busy' });

    expect(wrapper.text()).not.toContain('Receive conversations');
    expect(wrapper.text()).toContain(
      "You won't get new conversations or calls until you're back Online."
    );
  });

  it('mentions only conversations in the paused note without a voice inbox', () => {
    const { wrapper } = mountStatus({
      availability: 'offline',
      hasVoiceInbox: false,
    });

    expect(wrapper.text()).toContain(
      "You won't get new conversations until you're back Online."
    );
  });

  it('saves the calls preference when its toggle changes', async () => {
    const { wrapper, dispatch } = mountStatus({});

    await wrapper.findAll('.toggle')[1].trigger('click');

    expect(dispatch).toHaveBeenCalledWith('updateWorkPreferences', {
      accountId: 1,
      accepts_calls: false,
    });
  });

  it('does not save a preference while impersonating', async () => {
    impersonation.isImpersonating.value = true;
    const { wrapper, dispatch } = mountStatus({});

    await wrapper.findAll('.toggle')[1].trigger('click');

    expect(dispatch).not.toHaveBeenCalledWith(
      'updateWorkPreferences',
      expect.anything()
    );
    expect(useAlert).toHaveBeenCalledWith(
      'Cannot change availability while impersonating a user'
    );
  });
});
