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

  it('ignores a duplicate submit while a send is in flight', async () => {
    let resolveSend;
    const onSend = vi.fn(
      () =>
        new Promise(resolve => {
          resolveSend = resolve;
        })
    );
    const wrapper = mountCopilotInput(onSend);
    const textarea = wrapper.find('textarea');
    const form = wrapper.find('form');

    await textarea.setValue('Hello, how can you help me?');
    await form.trigger('submit');
    await form.trigger('submit');

    expect(onSend).toHaveBeenCalledTimes(1);

    resolveSend(true);
    await flushPromises();
  });

  it('prevents edits while a send is in flight', async () => {
    let resolveSend;
    const onSend = vi.fn(
      () =>
        new Promise(resolve => {
          resolveSend = resolve;
        })
    );
    const wrapper = mountCopilotInput(onSend);
    const textarea = wrapper.find('textarea');
    const button = wrapper.find('button');

    await textarea.setValue('Keep this message');
    await wrapper.find('form').trigger('submit');

    expect(textarea.attributes('disabled')).toBeDefined();
    expect(button.attributes('disabled')).toBeDefined();
    expect(textarea.element.value).toBe('Keep this message');

    resolveSend(false);
    await flushPromises();

    expect(textarea.attributes('disabled')).toBeUndefined();
    expect(button.attributes('disabled')).toBeUndefined();
    expect(textarea.element.value).toBe('Keep this message');
  });
});
