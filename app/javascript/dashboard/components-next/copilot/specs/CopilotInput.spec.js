import { mount, flushPromises } from '@vue/test-utils';
import CopilotInput from '../CopilotInput.vue';

const wrappers = [];

const mountCopilotInput = onSend => {
  const wrapper = mount(CopilotInput, {
    attachTo: document.body,
    props: { onSend },
    global: {
      mocks: { $t: key => key },
    },
  });
  wrappers.push(wrapper);
  return wrapper;
};

describe('CopilotInput', () => {
  afterEach(() => {
    wrappers.forEach(wrapper => wrapper.unmount());
    wrappers.length = 0;
  });

  it('clears the input and keeps focus after a successful send', async () => {
    const onSend = vi.fn().mockResolvedValue(true);
    const wrapper = mountCopilotInput(onSend);
    const textarea = wrapper.find('textarea');

    await textarea.setValue('Hello, how can you help me?');
    textarea.element.focus();
    await wrapper.find('form').trigger('submit');
    await flushPromises();

    expect(onSend).toHaveBeenCalledWith('Hello, how can you help me?');
    expect(textarea.element.value).toBe('');
    expect(document.activeElement).toBe(textarea.element);
  });

  it('preserves the input and focus when send fails', async () => {
    const onSend = vi.fn().mockResolvedValue(false);
    const wrapper = mountCopilotInput(onSend);
    const textarea = wrapper.find('textarea');

    await textarea.setValue('Hello, how can you help me?');
    textarea.element.focus();
    await wrapper.find('form').trigger('submit');
    await flushPromises();

    expect(onSend).toHaveBeenCalledWith('Hello, how can you help me?');
    expect(textarea.element.value).toBe('Hello, how can you help me?');
    expect(document.activeElement).toBe(textarea.element);
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

  it('keeps text pasted while a send is in flight', async () => {
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

    await textarea.setValue('First message');
    button.element.focus();
    await button.trigger('click');

    expect(onSend).toHaveBeenCalledWith('First message');
    expect(textarea.attributes('readonly')).toBeUndefined();
    expect(button.attributes('disabled')).toBeDefined();
    expect(textarea.element.value).toBe('');
    expect(document.activeElement).toBe(textarea.element);

    await textarea.setValue('Pasted follow-up');
    resolveSend(true);
    await flushPromises();

    expect(textarea.element.value).toBe('Pasted follow-up');
    expect(button.attributes('disabled')).toBeUndefined();
  });

  it('puts a failed message back in front of text pasted while it was sending', async () => {
    let resolveSend;
    const onSend = vi.fn(
      () =>
        new Promise(resolve => {
          resolveSend = resolve;
        })
    );
    const wrapper = mountCopilotInput(onSend);
    const textarea = wrapper.find('textarea');

    await textarea.setValue('First message');
    await wrapper.find('form').trigger('submit');
    await textarea.setValue('Pasted follow-up');
    resolveSend(false);
    await flushPromises();

    expect(textarea.element.value).toBe('First message\nPasted follow-up');
  });

  it('allows vertical scrolling when the input reaches its max height', () => {
    const wrapper = mountCopilotInput(vi.fn());
    const textarea = wrapper.find('textarea');

    expect(textarea.classes()).toContain('max-h-[200px]');
    expect(textarea.classes()).toContain('overflow-y-auto');
    expect(textarea.classes()).not.toContain('overflow-hidden');
  });
});
