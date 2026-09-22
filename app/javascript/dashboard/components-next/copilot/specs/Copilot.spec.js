import { shallowMount, flushPromises } from '@vue/test-utils';
import Copilot from '../Copilot.vue';
import CopilotInput from '../CopilotInput.vue';
import CopilotHistory from '../CopilotHistory.vue';
import ToggleCopilotAssistant from '../ToggleCopilotAssistant.vue';

vi.mock('dashboard/composables', () => ({ useTrack: vi.fn() }));
vi.mock('dashboard/composables/useUISettings', () => ({
  useUISettings: () => ({ updateUISettings: vi.fn() }),
}));

const mountCopilot = (props = {}) =>
  shallowMount(Copilot, {
    props: { onSendMessage: vi.fn().mockResolvedValue(true), ...props },
    global: {
      stubs: {
        CopilotInput: false,
        Button: { props: ['label'], template: '<button>{{ label }}</button>' },
      },
    },
  });
const clickButton = (wrapper, label) =>
  wrapper
    .findAll('button')
    .find(button => button.text() === `CAPTAIN.COPILOT.${label}`)
    .trigger('click');

describe('Copilot session UI', () => {
  it('keeps the legacy empty state and hides the V2 session controls with the flag off', () => {
    const wrapper = mountCopilot();
    expect(wrapper.findComponent(CopilotInput).exists()).toBe(false);
    expect(wrapper.findComponent(ToggleCopilotAssistant).exists()).toBe(false);
    expect(wrapper.text()).not.toContain('CAPTAIN.COPILOT.NEW_CHAT');
    wrapper.unmount();
  });

  it.each(
    [[], [{ id: 7 }], [{ id: 7 }, { id: 8 }]].map(assistants => ({
      assistants,
    }))
  )(
    'allows optional assistant selection and chat with %j',
    ({ assistants }) => {
      const wrapper = mountCopilot({ v2Enabled: true, assistants });
      expect(wrapper.findComponent(CopilotInput).exists()).toBe(true);
      expect(
        wrapper.findComponent(ToggleCopilotAssistant).props('allowNone')
      ).toBe(true);
      wrapper.unmount();
    }
  );

  it('keeps the draft while viewing history and clears it for a new session', async () => {
    const wrapper = mountCopilot({ v2Enabled: true });
    await wrapper.find('textarea').setValue('Unsent draft');
    await clickButton(wrapper, 'HISTORY');
    expect(wrapper.findComponent(CopilotHistory).exists()).toBe(true);
    await clickButton(wrapper, 'HISTORY');
    expect(wrapper.find('textarea').element.value).toBe('Unsent draft');
    await clickButton(wrapper, 'NEW_CHAT');
    expect(wrapper.emitted('reset')).toHaveLength(1);
    await wrapper.setProps({ sessionKey: 1 });
    expect(wrapper.find('textarea').element.value).toBe('');
    wrapper.unmount();
  });

  it('does not let an old send erase the next session draft', async () => {
    let finish;
    const wrapper = mountCopilot({
      v2Enabled: true,
      onSendMessage: () =>
        new Promise(resolve => {
          finish = resolve;
        }),
    });
    await wrapper.find('textarea').setValue('First chat');
    await wrapper.find('form').trigger('submit');
    await wrapper.setProps({ sessionKey: 1 });
    await wrapper.find('textarea').setValue('Next chat draft');
    finish(true);
    await flushPromises();
    expect(wrapper.find('textarea').element.value).toBe('Next chat draft');
    wrapper.unmount();
  });

  it.each(['messagesLoading', 'messagesError'])(
    'prevents composing while %s and allows it after recovery',
    async flag => {
      const wrapper = mountCopilot({ v2Enabled: true, [flag]: true });
      expect(wrapper.find('textarea').attributes('disabled')).toBeDefined();
      await wrapper.setProps({ [flag]: false });
      expect(wrapper.find('textarea').attributes('disabled')).toBeUndefined();
      wrapper.unmount();
    }
  );

  it('fixes the assistant on a resumed session and disables unavailable execution', () => {
    const wrapper = mountCopilot({
      v2Enabled: true,
      selectedThread: { id: 1, execution_availability: { available: false } },
      activeAssistant: { id: 7, name: 'Support' },
    });
    expect(wrapper.findComponent(ToggleCopilotAssistant).exists()).toBe(false);
    expect(wrapper.text()).toContain('Support');
    expect(wrapper.find('textarea').attributes('disabled')).toBeDefined();
    wrapper.unmount();
  });
});
