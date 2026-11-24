import { mount, flushPromises } from '@vue/test-utils';
import TagInput from '../TagInput.vue';
import RecipientsInput from 'dashboard/components-next/NewConversation/components/RecipientsInput.vue';

vi.mock('dashboard/components-next/dropdown-menu/DropdownMenu.vue', () => ({
  default: { template: '<div />' },
}));

const mountInput = (props = {}) =>
  mount(TagInput, {
    props: { modelValue: [], type: 'email', allowCreate: true, ...props },
  });

const paste = async (wrapper, text) => {
  await wrapper.find('input').trigger('paste', {
    clipboardData: { getData: () => text },
  });
  await flushPromises();
};

const tagValues = wrapper =>
  wrapper.findAll('span.truncate').map(tag => tag.text());

describe('TagInput email lists', () => {
  it.each(['To:', 'Cc:', 'Bcc:'])(
    'updates the shared recipient field model for %s',
    async label => {
      const wrapper = mount(RecipientsInput, {
        props: { label, modelValue: ['existing@example.com'] },
      });

      await paste(wrapper, 'first@example.com; second@example.com');

      expect(wrapper.emitted('update:modelValue').at(-1)).toEqual([
        ['existing@example.com', 'first@example.com', 'second@example.com'],
      ]);
    }
  );

  it.each([
    'first@example.com; second@example.com',
    'first@example.com second@example.com',
    'first@example.com\nsecond@example.com',
    'first@example.com\u00a0second@example.com',
    'first@example.com\u0085second@example.com',
    'first@example.com, second @ example.com',
  ])('turns a pasted list into recipient tags: %s', async value => {
    const wrapper = mountInput();

    await paste(wrapper, value);

    expect(tagValues(wrapper)).toEqual([
      'first@example.com',
      'second@example.com',
    ]);
    expect(wrapper.find('input').element.value).toBe('');
    expect(wrapper.emitted('add')).toEqual([
      [{ value: 'first@example.com', action: 'create' }],
      [{ value: 'second@example.com', action: 'create' }],
    ]);
  });

  it('adds a list on Enter while preserving existing recipients', async () => {
    const wrapper = mountInput({ modelValue: ['existing@example.com'] });
    await wrapper
      .find('input')
      .setValue('first@example.com; second@example.com');

    await wrapper.find('input').trigger('keydown', { key: 'Enter' });
    await flushPromises();

    expect(tagValues(wrapper)).toEqual([
      'existing@example.com',
      'first@example.com',
      'second@example.com',
    ]);
  });

  it('keeps a malformed whitespace-delimited list on Enter', async () => {
    const wrapper = mountInput();
    const input = wrapper.find('input');
    await input.setValue('invalid second@example.com');
    await input.trigger('keydown', { key: 'Enter' });
    await flushPromises();

    expect(wrapper.emitted('add')).toBeUndefined();
    expect(input.element.value).toBe('invalid second@example.com');
  });

  it('uses a semicolon keypress to finish an email tag', async () => {
    const wrapper = mountInput();
    await wrapper.find('input').setValue('first@example.com');

    await wrapper.find('input').trigger('keydown', { key: ';' });
    await flushPromises();

    expect(tagValues(wrapper)).toEqual(['first@example.com']);
  });

  it.each([';', ','])(
    'lets the browser insert %s when the recipient cannot be added',
    async key => {
      const wrapper = mountInput();
      const input = wrapper.find('input');
      await input.setValue('invalid');
      const event = new KeyboardEvent('keydown', {
        key,
        bubbles: true,
        cancelable: true,
      });

      input.element.dispatchEvent(event);
      await flushPromises();

      expect(event.defaultPrevented).toBe(false);
      expect(wrapper.emitted('add')).toBeUndefined();
    }
  );

  it('keeps invalid pasted addresses for correction without adding a partial list', async () => {
    const wrapper = mountInput();

    await paste(wrapper, 'first@example.com; invalid');

    expect(tagValues(wrapper)).toEqual([]);
    expect(wrapper.emitted('add')).toBeUndefined();
    expect(wrapper.find('input').element.value).toBe(
      'first@example.com; invalid'
    );

    await wrapper
      .find('input')
      .setValue('first@example.com; second@example.com');
    await wrapper.find('input').trigger('keydown', { key: 'Enter' });
    await flushPromises();

    expect(tagValues(wrapper)).toEqual([
      'first@example.com',
      'second@example.com',
    ]);
    expect(wrapper.find('input').element.value).toBe('');
  });

  it('preserves text around the current paste selection', async () => {
    const wrapper = mountInput();
    const input = wrapper.find('input');
    await input.setValue('first@example.com; replace; third@example.com');
    input.element.setSelectionRange(19, 26);

    await paste(wrapper, 'second@example.com; fourth@example.com');

    expect(tagValues(wrapper)).toEqual([
      'first@example.com',
      'second@example.com',
      'fourth@example.com',
      'third@example.com',
    ]);
  });

  it.each([{ type: 'text' }, { type: 'tel' }, { mode: 'single' }])(
    'keeps non-recipient-list modes unchanged: %s',
    async props => {
      const wrapper = mountInput(props);
      await wrapper
        .find('input')
        .setValue('first@example.com; second@example.com');

      await paste(wrapper, 'third@example.com; fourth@example.com');

      expect(tagValues(wrapper)).toEqual([]);
      expect(wrapper.emitted('add')).toBeUndefined();
      expect(wrapper.find('input').element.value).toBe(
        'first@example.com; second@example.com'
      );
    }
  );

  it('emits recipient removals without mutating the supplied model', async () => {
    const modelValue = ['first@example.com', 'second@example.com'];
    const wrapper = mountInput({ modelValue });

    await wrapper.find('span.cursor-pointer').trigger('click');

    expect(wrapper.emitted('update:modelValue')).toEqual([
      [['second@example.com']],
    ]);
    expect(modelValue).toEqual(['first@example.com', 'second@example.com']);
    expect(tagValues(wrapper)).toEqual(['second@example.com']);
  });

  it.each([
    [{ type: 'text' }, 'tag;name'],
    [{ type: 'tel' }, '+14155552671'],
    [{ mode: 'single' }, 'first@example.com'],
  ])(
    'still adds individual values in other modes: %s',
    async (props, value) => {
      const wrapper = mountInput(props);
      await wrapper.find('input').setValue(value);

      await wrapper.find('input').trigger('keydown', { key: 'Enter' });
      await flushPromises();

      expect(wrapper.emitted('update:modelValue')).toEqual([[[value]]]);
      expect(tagValues(wrapper)).toEqual([value]);
    }
  );
});
