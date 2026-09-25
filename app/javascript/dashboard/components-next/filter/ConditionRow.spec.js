import { shallowMount } from '@vue/test-utils';
import { describe, expect, it, vi } from 'vitest';
import ConditionRow from './ConditionRow.vue';
import Input from 'dashboard/components-next/input/Input.vue';

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));

const textFilter = placeholder => ({
  attributeKey: 'captain_condition',
  value: 'captain_condition',
  label: 'Captain',
  inputType: 'plainText',
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
  it('shows the attribute placeholder in the text input when the filter defines one', () => {
    const wrapper = mountRow(textFilter('Describe what to look for'));

    expect(wrapper.findComponent(Input).props('placeholder')).toBe(
      'Describe what to look for'
    );
  });

  it('falls back to the generic placeholder otherwise', () => {
    const wrapper = mountRow(textFilter(undefined));

    expect(wrapper.findComponent(Input).props('placeholder')).toBe(
      'FILTER.INPUT_PLACEHOLDER'
    );
  });
});
