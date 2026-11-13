import { mount } from '@vue/test-utils';
import RecipientsInput from '../RecipientsInput.vue';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';

const contacts = [
  { id: 1, name: 'Jane', email: 'jane@example.com' },
  { id: 2, name: 'No Email', email: null },
  { id: 3, name: 'John', email: 'john@example.com' },
];

const mountInput = (props = {}, options = {}) =>
  mount(RecipientsInput, {
    props: { label: 'To:', ...props },
    global: { stubs: { TagInput: true } },
    ...options,
  });

describe('RecipientsInput', () => {
  it('renders the label and passes the input props through', () => {
    const wrapper = mountInput({
      placeholder: 'Search',
      showDropdown: true,
      isLoading: true,
      focusOnMount: true,
      modelValue: ['jane@example.com'],
    });
    const tagInput = wrapper.findComponent(TagInput);

    expect(wrapper.find('label').text()).toBe('To:');
    expect(tagInput.props()).toMatchObject({
      placeholder: 'Search',
      showDropdown: true,
      isLoading: true,
      focusOnMount: true,
      allowCreate: true,
      type: 'email',
      modelValue: ['jane@example.com'],
    });
  });

  it('turns contacts with an email into menu items', () => {
    const wrapper = mountInput({ contacts });

    expect(wrapper.findComponent(TagInput).props('menuItems')).toEqual([
      {
        id: 1,
        label: 'jane@example.com',
        email: 'jane@example.com',
        thumbnail: { name: 'Jane', src: '' },
        value: 1,
        action: 'email',
      },
      {
        id: 3,
        label: 'john@example.com',
        email: 'john@example.com',
        thumbnail: { name: 'John', src: '' },
        value: 3,
        action: 'email',
      },
    ]);
  });

  it('forwards model updates, search input and click outside', async () => {
    const wrapper = mountInput();
    const tagInput = wrapper.findComponent(TagInput);
    const event = { target: { value: 'ja' } };

    await tagInput.vm.$emit('update:modelValue', ['jane@example.com']);
    await tagInput.vm.$emit('input', event);
    await tagInput.vm.$emit('onClickOutside');

    expect(wrapper.emitted('update:modelValue')).toEqual([
      [['jane@example.com']],
    ]);
    expect(wrapper.emitted('input')).toEqual([[event]]);
    expect(wrapper.emitted('onClickOutside')).toHaveLength(1);
  });

  it('renders trailing slot content next to the input', () => {
    const wrapper = mountInput(
      {},
      { slots: { default: '<button class="bcc">Bcc</button>' } }
    );

    expect(wrapper.find('button.bcc').exists()).toBe(true);
  });
});
