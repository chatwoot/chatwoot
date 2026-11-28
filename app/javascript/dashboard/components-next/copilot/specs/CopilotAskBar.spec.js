import { ref } from 'vue';
import { mount } from '@vue/test-utils';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';

import CopilotAskBar from '../CopilotAskBar.vue';

const testState = vi.hoisted(() => ({ openCopilot: vi.fn(), push: vi.fn() }));

vi.mock('vue-router', () => ({
  useRouter: () => ({ push: testState.push }),
}));
vi.mock('dashboard/composables/useCopilotDot', () => ({
  useCopilotDot: () => ({ openCopilot: testState.openCopilot }),
}));
vi.mock('dashboard/composables/useCopilotPrompts', () => ({
  useCopilotPrompts: () => ({
    prompts: ref([{ key: 'WAITING_ON_ME', label: 'Waiting on me?' }]),
    selectPrompt: key => `Prompt for ${key}`,
  }),
}));

const mountComponent = () =>
  mount(CopilotAskBar, {
    props: { source: 'empty_state' },
    global: { mocks: { $t: key => key }, directives: { tooltip: {} } },
  });

describe('CopilotAskBar', () => {
  const asked = vi.fn();

  beforeEach(() => {
    testState.openCopilot.mockReset();
    testState.push.mockReset();
    asked.mockReset();
    emitter.on(BUS_EVENTS.ASK_COPILOT, asked);
  });

  afterEach(() => {
    emitter.off(BUS_EVENTS.ASK_COPILOT, asked);
  });

  it('asks Copilot the typed question and clears the bar', async () => {
    const wrapper = mountComponent();
    const input = wrapper.find('input');

    await input.setValue('Which conversations need my reply?');
    await wrapper.find('form').trigger('submit');

    expect(testState.openCopilot).toHaveBeenCalledWith('empty_state');
    expect(asked).toHaveBeenCalledWith('Which conversations need my reply?');
    expect(input.element.value).toBe('');
  });

  it('asks Copilot a starter question', async () => {
    const wrapper = mountComponent();

    const starter = wrapper
      .findAll('button')
      .find(button => button.text() === 'Waiting on me?');

    await starter.trigger('click');

    expect(testState.openCopilot).toHaveBeenCalledWith('empty_state');
    expect(asked).toHaveBeenCalledWith('Prompt for WAITING_ON_ME');
  });

  it('opens Copilot full screen without asking anything', async () => {
    const wrapper = mountComponent();

    await wrapper
      .find('button[aria-label="CAPTAIN.COPILOT.OPEN"]')
      .trigger('click');

    expect(testState.openCopilot).toHaveBeenCalledWith('empty_state');
    expect(testState.push).toHaveBeenCalledWith({ name: 'copilot_index' });
    expect(asked).not.toHaveBeenCalled();
  });
});
