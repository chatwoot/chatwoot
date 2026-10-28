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

const CheckboxStub = {
  props: ['modelValue', 'disabled'],
  emits: ['update:modelValue'],
  template:
    '<input type="checkbox" class="preference" :checked="modelValue" :disabled="disabled" @click="$emit(\'update:modelValue\', !modelValue)" />',
};

const mountStatus = ({
  availability = 'online',
  hasVoiceInbox = true,
  acceptsConversations = true,
  acceptsCalls = true,
}) => {
  const dispatch = vi.fn();
  const store = createStore({
    getters: {
      getCurrentUserAvailability: () => availability,
      getCurrentAccountId: () => 1,
      getCurrentUserAutoOffline: () => true,
      getCurrentUserAcceptsConversations: () => acceptsConversations,
      getCurrentUserAcceptsCalls: () => acceptsCalls,
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
        ToggleSwitch: true,
        Checkbox: CheckboxStub,
      },
    },
  });

  return { wrapper, dispatch };
};

describe('SidebarProfileMenuStatus', () => {
  beforeEach(() => {
    impersonation.isImpersonating.value = false;
  });

  it('shows the conversations and calls choices when online with a voice inbox', () => {
    const { wrapper } = mountStatus({});

    expect(wrapper.text()).toContain('Receive conversations');
    expect(wrapper.text()).toContain('Receive voice calls');
  });

  it('shows no choices or paused note without a voice inbox', () => {
    const { wrapper } = mountStatus({ hasVoiceInbox: false });

    expect(wrapper.text()).not.toContain('Receive conversations');
    expect(wrapper.text()).not.toContain('Receive voice calls');
    expect(wrapper.text()).not.toContain("You won't get new conversations");
  });

  it('shows a paused note instead of the choices when not online', () => {
    const { wrapper } = mountStatus({ availability: 'busy' });

    expect(wrapper.text()).not.toContain('Receive conversations');
    expect(wrapper.text()).toContain(
      "You won't get new conversations or calls until you're back Online."
    );
  });

  it('keeps the only checked choice from being unchecked', () => {
    const { wrapper } = mountStatus({ acceptsCalls: false });
    const [conversations, calls] = wrapper.findAll('.preference');

    expect(conversations.element.disabled).toBe(true);
    expect(calls.element.disabled).toBe(false);
  });

  it('saves the calls preference when its checkbox changes', async () => {
    const { wrapper, dispatch } = mountStatus({});

    await wrapper.findAll('.preference')[1].trigger('click');

    expect(dispatch).toHaveBeenCalledWith('updateWorkPreferences', {
      accountId: 1,
      accepts_calls: false,
    });
  });

  it('does not save a preference while impersonating', async () => {
    impersonation.isImpersonating.value = true;
    const { wrapper, dispatch } = mountStatus({});

    await wrapper.findAll('.preference')[1].trigger('click');

    expect(dispatch).not.toHaveBeenCalledWith(
      'updateWorkPreferences',
      expect.anything()
    );
    expect(useAlert).toHaveBeenCalledWith(
      'Cannot change availability while impersonating a user'
    );
  });
});
