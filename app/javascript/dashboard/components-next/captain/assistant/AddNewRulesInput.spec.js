import { mount } from '@vue/test-utils';
import AddNewRulesInput from './AddNewRulesInput.vue';

describe('AddNewRulesInput', () => {
  it('adds trimmed content on Enter and clears the input', async () => {
    const wrapper = mount(AddNewRulesInput, {
      props: {
        placeholder: 'Type a temporary guideline...',
        label: 'Add to test (↵)',
      },
    });
    const input = wrapper.get('input');

    await input.setValue('  Keep replies concise  ');
    await input.trigger('keyup', { key: 'Enter' });

    expect(wrapper.emitted('add')).toEqual([['Keep replies concise']]);
    expect(input.element.value).toBe('');
  });

  it('ignores empty content and passes the optional character limit through', async () => {
    const wrapper = mount(AddNewRulesInput, {
      props: {
        maxLength: 10000,
      },
    });
    const input = wrapper.get('input');

    await input.setValue('   ');
    await input.trigger('keyup', { key: 'Enter' });

    expect(wrapper.emitted('add')).toBeUndefined();
    expect(input.attributes('maxlength')).toBe('10000');
  });
});
