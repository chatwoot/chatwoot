import { mount, flushPromises } from '@vue/test-utils';
import CopilotInput from '../CopilotInput.vue';

const mountCopilotInput = onSend =>
  mount(CopilotInput, {
    props: { onSend },
    global: {
      mocks: { $t: key => key },
    },
  });

describe('CopilotInput', () => {
  it('clears the input after a successful send', async () => {
    const onSend = vi.fn().mockResolvedValue(true);
    const wrapper = mountCopilotInput(onSend);
    const textarea = wrapper.find('textarea');

    await textarea.setValue('Hello, how can you help me?');
    await wrapper.find('form').trigger('submit');
    await flushPromises();

    expect(onSend).toHaveBeenCalledWith('Hello, how can you help me?');
    expect(textarea.element.value).toBe('');
  });

  it('preserves the input when send fails', async () => {
    const onSend = vi.fn().mockResolvedValue(false);
    const wrapper = mountCopilotInput(onSend);
    const textarea = wrapper.find('textarea');

    await textarea.setValue('Hello, how can you help me?');
    await wrapper.find('form').trigger('submit');
    await flushPromises();

    expect(onSend).toHaveBeenCalledWith('Hello, how can you help me?');
    expect(textarea.element.value).toBe('Hello, how can you help me?');
  });
});
