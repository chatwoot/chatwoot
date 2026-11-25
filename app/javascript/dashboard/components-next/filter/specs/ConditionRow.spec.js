import { mount } from '@vue/test-utils';
import ConditionRow from '../ConditionRow.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

const operator = (value, hasInput) => ({
  value,
  label: value,
  hasInput,
  inputOverride: null,
  icon: null,
});

const listFilterType = {
  attributeKey: 'conversation_type',
  value: 'conversation_type',
  attributeName: 'Conversation type',
  label: 'Conversation type',
  inputType: 'searchSelect',
  options: [{ id: 'platinum', name: 'platinum' }],
  filterOperators: [
    operator('equal_to', true),
    operator('not_equal_to', true),
    operator('is_present', false),
    operator('is_not_present', false),
  ],
  attributeModel: 'customAttributes',
};

const mountConditionRow = props =>
  mount(ConditionRow, {
    props: {
      filterTypes: [listFilterType],
      attributeKey: 'conversation_type',
      filterOperator: 'equal_to',
      values: { id: 'platinum', name: 'platinum' },
      ...props,
    },
    global: {
      stubs: {
        Button: true,
        Input: true,
        FilterSelect: true,
        MultiSelect: true,
        SingleSelect: true,
      },
    },
  });

describe('ConditionRow', () => {
  it('clears the value when switching to an operator without input', async () => {
    const wrapper = mountConditionRow();

    await wrapper.setProps({ filterOperator: 'is_not_present' });

    expect(wrapper.emitted('update:values').at(-1)).toEqual([[]]);
  });

  it('restores an empty value of the right shape when the input comes back', async () => {
    const wrapper = mountConditionRow({ filterOperator: 'is_not_present' });

    await wrapper.setProps({ filterOperator: 'equal_to' });

    expect(wrapper.emitted('update:values').at(-1)).toEqual([{}]);
  });

  it('keeps the value when switching between operators that take input', async () => {
    const wrapper = mountConditionRow();

    await wrapper.setProps({ filterOperator: 'not_equal_to' });

    expect(wrapper.emitted('update:values')).toBeUndefined();
  });

  it('hides the input for operators without input', async () => {
    const wrapper = mountConditionRow({ filterOperator: 'is_present' });

    expect(wrapper.findComponent({ name: 'SingleSelect' }).exists()).toBe(
      false
    );
  });
});
