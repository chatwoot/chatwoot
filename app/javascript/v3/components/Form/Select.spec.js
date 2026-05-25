import { mount } from '@vue/test-utils';
import FormSelect from './Select.vue';

const options = [
  { label: 'Small', value: 'small' },
  { label: 'Large', value: 'large' },
];

const buildWrapper = props =>
  mount(FormSelect, {
    global: {
      stubs: {
        'fluent-icon': true,
      },
    },
    props: {
      label: 'Font size',
      name: 'fontSize',
      options,
      ...props,
    },
  });

describe('FormSelect', () => {
  it('sets the initial selected option from modelValue', () => {
    const wrapper = buildWrapper({ modelValue: 'large' });

    expect(wrapper.find('select').element.value).toBe('large');
  });

  it('shows the placeholder when modelValue is empty', () => {
    const wrapper = buildWrapper({
      modelValue: '',
      placeholder: 'Select a size',
    });

    expect(wrapper.find('select').element.value).toBe('');
  });

  it('emits model updates when the selection changes', async () => {
    const wrapper = buildWrapper({ modelValue: 'small' });

    await wrapper.find('select').setValue('large');

    expect(wrapper.emitted('update:modelValue')).toEqual([['large']]);
  });
});
