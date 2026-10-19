import { mount } from '@vue/test-utils';
import EmailOptions from '../EmailOptions.vue';
import RecipientsInput from '../RecipientsInput.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const contacts = [{ id: 1, name: 'Jane', email: 'jane@example.com' }];

const mountOptions = (props = {}) =>
  mount(EmailOptions, {
    props: {
      contacts,
      subject: 'Hello',
      ccEmails: 'a@example.com, b@example.com',
      bccEmails: '',
      ...props,
    },
    global: { stubs: { InlineInput: true, TagInput: true } },
  });

describe('EmailOptions', () => {
  it('renders the cc recipients row from the comma separated string', () => {
    const wrapper = mountOptions();
    const rows = wrapper.findAllComponents(RecipientsInput);

    expect(rows).toHaveLength(1);
    expect(rows[0].props()).toMatchObject({
      modelValue: ['a@example.com', 'b@example.com'],
      contacts,
    });
  });

  it('emits the cc emails back as a comma separated string', async () => {
    const wrapper = mountOptions();

    await wrapper
      .findComponent(RecipientsInput)
      .vm.$emit('update:modelValue', ['c@example.com', 'd@example.com']);

    expect(wrapper.emitted('update:ccEmails')).toEqual([
      ['c@example.com,d@example.com'],
    ]);
  });

  it('forwards cc search and dropdown events', async () => {
    const wrapper = mountOptions();
    const cc = wrapper.findComponent(RecipientsInput);

    await cc.vm.$emit('input', 'ja');
    await cc.vm.$emit('onClickOutside');

    expect(wrapper.emitted('searchCcEmails')).toEqual([['ja']]);
    expect(wrapper.emitted('updateDropdown')).toEqual([['cc', false]]);
  });

  it('reveals the bcc row on demand and wires it up', async () => {
    const wrapper = mountOptions({ bccEmails: 'x@example.com' });

    await wrapper.findComponent(Button).trigger('click');
    const rows = wrapper.findAllComponents(RecipientsInput);

    expect(rows).toHaveLength(2);
    expect(rows[1].props()).toMatchObject({
      modelValue: ['x@example.com'],
      focusOnMount: true,
    });

    await rows[1].vm.$emit('update:modelValue', ['y@example.com']);
    await rows[1].vm.$emit('input', 'y');
    await rows[1].vm.$emit('onClickOutside');

    expect(wrapper.emitted('update:bccEmails')).toEqual([['y@example.com']]);
    expect(wrapper.emitted('searchBccEmails')).toEqual([['y']]);
    expect(wrapper.emitted('updateDropdown')).toEqual([['bcc', false]]);
  });
});
