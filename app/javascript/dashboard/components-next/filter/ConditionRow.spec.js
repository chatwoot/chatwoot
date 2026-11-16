import { shallowMount } from '@vue/test-utils';
import { describe, expect, it, vi } from 'vitest';
import ConditionRow from './ConditionRow.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import FilterSelect from './inputs/FilterSelect.vue';
import { buildAttributesFilterTypes } from './helper/filterHelper';
import { useOperators } from './operators';

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));

const textFilter = (placeholder, inputType = 'plainText') => ({
  attributeKey: 'captain_condition',
  value: 'captain_condition',
  label: 'Captain',
  inputType,
  options: [],
  placeholder,
  filterOperators: [{ value: 'detects', label: 'Detects', hasInput: true }],
});

const mountRow = filter =>
  shallowMount(ConditionRow, {
    props: {
      filterTypes: [filter],
      attributeKey: 'captain_condition',
      filterOperator: 'detects',
      values: '',
    },
  });

describe('ConditionRow', () => {
  it.each(['contains', 'does_not_contain'])(
    'blocks a saved numeric custom attribute filter using %s until its operator is corrected',
    async filterOperator => {
      const { getOperatorTypes } = useOperators();
      const filterTypes = buildAttributesFilterTypes(
        [
          {
            attributeKey: 'contract_count',
            attributeDisplayName: 'Contract count',
            attributeDisplayType: 'number',
          },
        ],
        getOperatorTypes,
        'contact'
      );
      const wrapper = shallowMount(ConditionRow, {
        props: {
          filterTypes,
          attributeKey: 'contract_count',
          filterOperator,
          values: '12',
        },
      });

      const operatorPicker = wrapper.findAllComponents(FilterSelect)[1];
      expect(operatorPicker.props('options').map(({ value }) => value)).toEqual(
        ['equal_to', 'not_equal_to']
      );
      expect(wrapper.vm.validate()).toBe(false);
      await wrapper.vm.$nextTick();
      expect(wrapper.text()).toContain('FILTER.ERRORS.INVALID_FILTER_OPERATOR');

      await wrapper.setProps({ filterOperator: 'equal_to' });
      expect(wrapper.vm.validate()).toBe(true);
      expect(wrapper.text()).not.toContain(
        'FILTER.ERRORS.INVALID_FILTER_OPERATOR'
      );
    }
  );

  it('shows the attribute placeholder in the text input when the filter defines one', () => {
    const wrapper = mountRow(textFilter('Describe what to look for'));

    expect(wrapper.findComponent(Input).props('placeholder')).toBe(
      'Describe what to look for'
    );
  });

  it('limits the text input to the length the filter allows', () => {
    const wrapper = mountRow({ ...textFilter('Describe'), maxLength: 500 });

    expect(wrapper.findComponent(Input).attributes('maxlength')).toBe('500');
  });

  it('falls back to the generic placeholder otherwise', () => {
    const wrapper = mountRow(textFilter(undefined));

    expect(wrapper.findComponent(Input).props('placeholder')).toBe(
      'FILTER.INPUT_PLACEHOLDER'
    );
  });

  it('uses a growing text area with a character count for long text', () => {
    const wrapper = mountRow({
      ...textFilter('Describe what to look for', 'longText'),
      maxLength: 500,
    });

    const textArea = wrapper.findComponent(TextArea);
    expect(wrapper.findComponent(Input).exists()).toBe(false);
    expect(textArea.props()).toMatchObject({
      placeholder: 'Describe what to look for',
      maxLength: 500,
      autoHeight: true,
      showCharacterCount: true,
    });
  });
});
