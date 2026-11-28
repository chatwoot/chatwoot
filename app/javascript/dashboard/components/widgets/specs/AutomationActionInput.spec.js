import { shallowMount } from '@vue/test-utils';
import { describe, expect, it } from 'vitest';
import AutomationActionInput from '../AutomationActionInput.vue';
import SingleSelect from 'dashboard/components-next/filter/inputs/SingleSelect.vue';
import MultiSelect from 'dashboard/components-next/filter/inputs/MultiSelect.vue';

const actionTypes = [
  {
    key: 'assign_agent_bot',
    label: 'Assign a bot',
    inputType: 'search_select',
  },
  { key: 'add_label', label: 'Add a label', inputType: 'multi_select' },
];

const mountInput = (actionName, actionParams, dropdownValues) =>
  shallowMount(AutomationActionInput, {
    props: {
      modelValue: { action_name: actionName, action_params: actionParams },
      actionTypes,
      dropdownValues,
    },
  });

describe('AutomationActionInput', () => {
  it('offers a saved single selection that is missing from the options', () => {
    const wrapper = mountInput(
      'assign_agent_bot',
      [{ id: 7, name: 'Unavailable (7)' }],
      [{ id: 1, name: 'Sales bot' }]
    );

    const valueSelect = wrapper.findAllComponents(SingleSelect)[1];
    expect(valueSelect.props('options')).toEqual([
      { id: 1, name: 'Sales bot' },
      { id: 7, name: 'Unavailable (7)' },
    ]);
  });

  it('offers saved multi selections that are missing from the options', () => {
    const wrapper = mountInput(
      'add_label',
      [
        { id: 'billing', name: 'billing' },
        { id: 'gone', name: 'Unavailable (gone)' },
      ],
      [{ id: 'billing', name: 'billing' }]
    );

    expect(wrapper.findComponent(MultiSelect).props('options')).toEqual([
      { id: 'billing', name: 'billing' },
      { id: 'gone', name: 'Unavailable (gone)' },
    ]);
  });

  it('keeps the options unchanged when the selection is one of them', () => {
    const wrapper = mountInput(
      'assign_agent_bot',
      { id: 1, name: 'Sales bot' },
      [
        { id: 1, name: 'Sales bot' },
        { id: 2, name: 'Support bot' },
      ]
    );

    const valueSelect = wrapper.findAllComponents(SingleSelect)[1];
    expect(valueSelect.props('options')).toEqual([
      { id: 1, name: 'Sales bot' },
      { id: 2, name: 'Support bot' },
    ]);
  });
});
