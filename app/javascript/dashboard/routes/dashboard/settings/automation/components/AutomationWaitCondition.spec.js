import { h, nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { describe, expect, it, vi } from 'vitest';
import NextButton from 'dashboard/components-next/button/Button.vue';
import ConditionRow from 'dashboard/components-next/filter/ConditionRow.vue';
import FilterSelect from 'dashboard/components-next/filter/inputs/FilterSelect.vue';
import MultiSelect from 'dashboard/components-next/filter/inputs/MultiSelect.vue';
import { DURATION_UNITS } from 'dashboard/components-next/input/constants';
import AutomationWaitCondition from './AutomationWaitCondition.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: (key, { count } = {}) => (count === undefined ? key : `${key}:${count}`),
  }),
}));

const statusOptions = [
  { value: 'open', label: 'Open' },
  { value: 'resolved', label: 'Resolved' },
  { value: 'pending', label: 'Pending' },
  { value: 'snoozed', label: 'Snoozed' },
];

const filterTypes = [
  {
    attributeKey: 'message_type',
    value: 'message_type',
    label: 'Message type',
    filterOperators: [{ value: 'equal_to', label: 'Equals' }],
  },
  {
    attributeKey: 'private_note',
    value: 'private_note',
    label: 'Private note',
    filterOperators: [{ value: 'equal_to', label: 'Equals' }],
  },
  {
    attributeKey: 'inbox_id',
    value: 'inbox_id',
    label: 'Inbox',
    filterOperators: [{ value: 'equal_to', label: 'Equals' }],
  },
  {
    attributeKey: 'status',
    value: 'status',
    label: 'Status',
    filterOperators: [{ value: 'equal_to', label: 'Equals' }],
  },
  {
    attributeKey: 'assignee_id',
    value: 'assignee_id',
    label: 'Assignee',
    filterOperators: [{ value: 'equal_to', label: 'Equals' }],
  },
  {
    attributeKey: 'labels',
    value: 'labels',
    label: 'Labels',
    filterOperators: [{ value: 'equal_to', label: 'Equals' }],
  },
];

const mountComponent = (props = {}, options = {}) =>
  shallowMount(AutomationWaitCondition, {
    props: {
      eventName: 'conversation_created',
      conditions: [
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: '',
          query_operator: 'and',
          custom_attribute_type: '',
        },
      ],
      delay: 240,
      unit: DURATION_UNITS.HOURS,
      statusOptions,
      inboxOptions: [],
      filterTypes,
      removeFilter: vi.fn(),
      ...props,
    },
    ...options,
  });

describe('AutomationWaitCondition', () => {
  it('creates a pending status wait by default', async () => {
    const wrapper = mountComponent();
    await nextTick();

    const statusSelect = wrapper.findAllComponents(FilterSelect)[1];
    expect(statusSelect.props()).toMatchObject({
      modelValue: 'pending',
      options: statusOptions,
    });
    expect(wrapper.emitted('update:eventName').at(-1)[0]).toBe(
      'conversation_updated'
    );
    expect(wrapper.emitted('update:conditions').at(-1)[0]).toEqual([
      {
        attribute_key: 'status',
        filter_operator: 'equal_to',
        values: 'pending',
        query_operator: 'and',
        custom_attribute_type: '',
      },
    ]);
    expect(wrapper.findComponent(NextButton).exists()).toBe(false);
  });

  it('hydrates and updates the status condition for a saved wait', async () => {
    const wrapper = mountComponent({
      eventName: 'conversation_updated',
      isSavedWait: true,
      conditions: [
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: [{ id: 'pending', name: 'Pending' }],
          query_operator: 'and',
          custom_attribute_type: '',
        },
      ],
    });

    const statusSelect = wrapper.findAllComponents(FilterSelect)[1];
    expect(statusSelect.props('modelValue')).toBe('pending');

    statusSelect.vm.$emit('update:modelValue', 'open');
    await nextTick();

    expect(wrapper.emitted('update:conditions').at(-1)[0]).toEqual([
      {
        attribute_key: 'status',
        filter_operator: 'equal_to',
        values: 'open',
        query_operator: 'and',
        custom_attribute_type: '',
      },
    ]);
  });

  it('keeps a saved inbox exclusion until the admin changes the wait', async () => {
    const savedConditions = [
      {
        attribute_key: 'message_type',
        filter_operator: 'equal_to',
        values: [{ id: 'outgoing', name: 'Outgoing' }],
        query_operator: 'and',
        custom_attribute_type: '',
      },
      {
        attribute_key: 'private_note',
        filter_operator: 'equal_to',
        values: [{ id: false, name: 'False' }],
        query_operator: 'and',
        custom_attribute_type: '',
      },
      {
        attribute_key: 'inbox_id',
        filter_operator: 'not_equal_to',
        values: [{ id: 7, name: 'Support' }],
        query_operator: null,
        custom_attribute_type: '',
      },
    ];

    const wrapper = mountComponent({
      eventName: 'message_created',
      isSavedWait: true,
      inboxOptions: [{ id: 7, name: 'Support' }],
      conditions: savedConditions,
    });
    await nextTick();

    expect(wrapper.emitted('update:conditions')).toBeUndefined();
    expect(wrapper.props('conditions')).toEqual(savedConditions);
  });

  it('adds a normal condition joined to the wait with AND', async () => {
    const wrapper = mountComponent({
      eventName: 'message_created',
      isSavedWait: true,
      inboxOptions: [{ id: 7, name: 'Support' }],
      conditions: [
        {
          attribute_key: 'message_type',
          filter_operator: 'equal_to',
          values: [{ id: 'outgoing', name: 'Outgoing' }],
          query_operator: 'and',
          custom_attribute_type: '',
        },
        {
          attribute_key: 'private_note',
          filter_operator: 'equal_to',
          values: [{ id: false, name: 'False' }],
          query_operator: 'and',
          custom_attribute_type: '',
        },
        {
          attribute_key: 'inbox_id',
          filter_operator: 'equal_to',
          values: [{ id: 7, name: 'Support' }],
          query_operator: 'and',
          custom_attribute_type: '',
        },
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: [{ id: 'pending', name: 'Pending' }],
          query_operator: null,
          custom_attribute_type: '',
        },
      ],
    });
    await nextTick();

    const condition = wrapper.findComponent(ConditionRow);
    expect(condition.props()).toMatchObject({
      attributeKey: 'status',
      showQueryOperator: false,
    });
    expect(
      condition.props('filterTypes').map(filter => filter.attributeKey)
    ).toEqual(['status', 'assignee_id', 'labels']);
    expect(wrapper.emitted('update:conditions')).toBeUndefined();

    expect(wrapper.text()).toContain('FILTER.QUERY_DROPDOWN_LABELS.AND');

    condition.vm.$emit('update:values', [{ id: 'pending', name: 'Pending' }]);
    await nextTick();
    expect(wrapper.props('conditions')[3].values).toEqual([
      { id: 'pending', name: 'Pending' },
    ]);

    await wrapper.findComponent(NextButton).trigger('click');
    expect(wrapper.emitted('update:conditions').at(-1)[0].at(-1)).toEqual({
      attribute_key: 'status',
      filter_operator: 'equal_to',
      values: '',
      query_operator: null,
      custom_attribute_type: '',
    });
  });

  it('shows and preserves a saved OR connector while new conditions use AND', async () => {
    const wrapper = mountComponent({
      eventName: 'message_created',
      isSavedWait: true,
      conditions: [
        {
          attribute_key: 'message_type',
          filter_operator: 'equal_to',
          values: [{ id: 'outgoing', name: 'Outgoing' }],
          query_operator: 'or',
          custom_attribute_type: '',
        },
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: [{ id: 'pending', name: 'Pending' }],
          query_operator: null,
          custom_attribute_type: '',
        },
      ],
    });
    await nextTick();

    expect(wrapper.text()).toContain('FILTER.QUERY_DROPDOWN_LABELS.OR');
    expect(wrapper.emitted('update:conditions')).toBeUndefined();

    wrapper
      .findComponent(FilterSelect)
      .vm.$emit('update:modelValue', 'agent_unresponsive');
    await nextTick();

    const changedTriggerConditions = wrapper
      .emitted('update:conditions')
      .at(-1)[0];
    expect(changedTriggerConditions).toEqual([
      expect.objectContaining({
        attribute_key: 'message_type',
        values: 'incoming',
        query_operator: 'or',
      }),
      expect.objectContaining({
        attribute_key: 'status',
        query_operator: null,
      }),
    ]);

    await wrapper.setProps({ conditions: changedTriggerConditions });
    await wrapper.findComponent(NextButton).trigger('click');

    expect(wrapper.emitted('update:conditions').at(-1)[0]).toEqual([
      expect.objectContaining({
        attribute_key: 'message_type',
        query_operator: 'or',
      }),
      expect.objectContaining({
        attribute_key: 'status',
        query_operator: 'and',
      }),
      expect.objectContaining({
        attribute_key: 'status',
        query_operator: null,
      }),
    ]);
  });

  it('keeps a saved pending condition when the reply direction changes', async () => {
    const wrapper = mountComponent({
      eventName: 'message_created',
      isSavedWait: true,
      conditions: [
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: [{ id: 'pending', name: 'Pending' }],
          query_operator: 'and',
          custom_attribute_type: '',
        },
        {
          attribute_key: 'message_type',
          filter_operator: 'equal_to',
          values: [{ id: 'outgoing', name: 'Outgoing' }],
          query_operator: 'and',
          custom_attribute_type: '',
        },
        {
          attribute_key: 'private_note',
          filter_operator: 'equal_to',
          values: [{ id: false, name: 'False' }],
          query_operator: null,
          custom_attribute_type: '',
        },
      ],
    });
    await nextTick();

    wrapper
      .findComponent(FilterSelect)
      .vm.$emit('update:modelValue', 'agent_unresponsive');
    await nextTick();

    expect(wrapper.emitted('update:conditions').at(-1)[0]).toEqual([
      {
        attribute_key: 'status',
        filter_operator: 'equal_to',
        values: [{ id: 'pending', name: 'Pending' }],
        query_operator: 'and',
        custom_attribute_type: '',
      },
      {
        attribute_key: 'message_type',
        filter_operator: 'equal_to',
        values: 'incoming',
        query_operator: null,
        custom_attribute_type: '',
      },
    ]);
  });

  it('preserves mixed connectors and condition order when an inbox is added', async () => {
    const wrapper = mountComponent({
      eventName: 'message_created',
      isSavedWait: true,
      inboxOptions: [{ id: 7, name: 'Support' }],
      conditions: [
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: [{ id: 'open', name: 'Open' }],
          query_operator: 'or',
          custom_attribute_type: '',
        },
        {
          attribute_key: 'message_type',
          filter_operator: 'equal_to',
          values: [{ id: 'outgoing', name: 'Outgoing' }],
          query_operator: 'and',
          custom_attribute_type: '',
        },
        {
          attribute_key: 'private_note',
          filter_operator: 'equal_to',
          values: [{ id: false, name: 'False' }],
          query_operator: 'and',
          custom_attribute_type: '',
        },
        {
          attribute_key: 'priority',
          filter_operator: 'equal_to',
          values: [{ id: 'high', name: 'High' }],
          query_operator: null,
          custom_attribute_type: '',
        },
      ],
    });
    await nextTick();

    wrapper
      .findComponent(MultiSelect)
      .vm.$emit('update:modelValue', [{ id: 7, name: 'Support' }]);
    await nextTick();

    expect(wrapper.emitted('update:conditions').at(-1)[0]).toEqual([
      expect.objectContaining({
        attribute_key: 'status',
        query_operator: 'or',
      }),
      expect.objectContaining({
        attribute_key: 'message_type',
        query_operator: 'and',
      }),
      expect.objectContaining({
        attribute_key: 'private_note',
        query_operator: 'and',
      }),
      expect.objectContaining({
        attribute_key: 'inbox_id',
        values: [7],
        query_operator: 'and',
      }),
      expect.objectContaining({
        attribute_key: 'priority',
        query_operator: null,
      }),
    ]);
  });

  it('keeps every added condition joined by AND and removes the selected row', async () => {
    const removeFilter = vi.fn();
    const wrapper = mountComponent({
      eventName: 'message_created',
      isSavedWait: true,
      removeFilter,
      conditions: [
        {
          attribute_key: 'message_type',
          filter_operator: 'equal_to',
          values: [{ id: 'outgoing', name: 'Outgoing' }],
          query_operator: 'and',
          custom_attribute_type: '',
        },
        {
          attribute_key: 'private_note',
          filter_operator: 'equal_to',
          values: [{ id: false, name: 'False' }],
          query_operator: null,
          custom_attribute_type: '',
        },
      ],
    });
    await nextTick();

    const addButton = wrapper.findComponent(NextButton);
    await addButton.trigger('click');
    const oneAddedCondition = wrapper.emitted('update:conditions').at(-1)[0];
    await wrapper.setProps({ conditions: oneAddedCondition });
    await addButton.trigger('click');
    const twoAddedConditions = wrapper.emitted('update:conditions').at(-1)[0];
    await wrapper.setProps({ conditions: twoAddedConditions });

    expect(twoAddedConditions.slice(2)).toEqual([
      expect.objectContaining({
        attribute_key: 'status',
        query_operator: 'and',
      }),
      expect.objectContaining({
        attribute_key: 'status',
        query_operator: null,
      }),
    ]);
    expect(wrapper.findAllComponents(ConditionRow)).toHaveLength(2);

    wrapper.findAllComponents(ConditionRow)[1].vm.$emit('remove');
    expect(removeFilter).toHaveBeenCalledWith(3);
  });

  it('preserves added conditions between message waits and drops them for a status wait', async () => {
    const wrapper = mountComponent({
      eventName: 'message_created',
      isSavedWait: true,
      conditions: [
        {
          attribute_key: 'message_type',
          filter_operator: 'equal_to',
          values: [{ id: 'outgoing', name: 'Outgoing' }],
          query_operator: 'and',
          custom_attribute_type: '',
        },
        {
          attribute_key: 'private_note',
          filter_operator: 'equal_to',
          values: [{ id: false, name: 'False' }],
          query_operator: 'and',
          custom_attribute_type: '',
        },
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: [{ id: 'pending', name: 'Pending' }],
          query_operator: null,
          custom_attribute_type: '',
        },
      ],
    });
    await nextTick();

    const triggerSelect = wrapper.findComponent(FilterSelect);
    triggerSelect.vm.$emit('update:modelValue', 'agent_unresponsive');
    await nextTick();

    expect(wrapper.emitted('update:conditions').at(-1)[0]).toEqual([
      expect.objectContaining({
        attribute_key: 'message_type',
        values: 'incoming',
      }),
      expect.objectContaining({
        attribute_key: 'status',
        values: [{ id: 'pending', name: 'Pending' }],
        query_operator: null,
      }),
    ]);

    triggerSelect.vm.$emit('update:modelValue', 'conversation_status');
    await nextTick();

    expect(wrapper.emitted('update:conditions').at(-1)[0]).toEqual([
      expect.objectContaining({
        attribute_key: 'status',
        values: 'pending',
      }),
    ]);
    expect(wrapper.findComponent(ConditionRow).exists()).toBe(false);
    expect(wrapper.findComponent(NextButton).exists()).toBe(false);
  });

  it('validates every added condition before returning the result', async () => {
    const validations = [vi.fn(() => false), vi.fn(() => false)];
    let validationIndex = 0;
    const ConditionRowStub = {
      name: 'ConditionRow',
      setup(_, { expose }) {
        const validate = validations[validationIndex];
        validationIndex += 1;
        expose({ validate, resetValidation: vi.fn() });
        return () => h('li');
      },
    };
    const wrapper = mountComponent(
      {
        eventName: 'message_created',
        isSavedWait: true,
        conditions: [
          {
            attribute_key: 'message_type',
            filter_operator: 'equal_to',
            values: [{ id: 'incoming', name: 'Incoming' }],
            query_operator: 'and',
            custom_attribute_type: '',
          },
          {
            attribute_key: 'status',
            filter_operator: 'equal_to',
            values: '',
            query_operator: 'and',
            custom_attribute_type: '',
          },
          {
            attribute_key: 'assignee_id',
            filter_operator: 'equal_to',
            values: '',
            query_operator: null,
            custom_attribute_type: '',
          },
        ],
      },
      {
        global: {
          stubs: { ConditionRow: ConditionRowStub },
        },
      }
    );
    await nextTick();

    expect(wrapper.vm.validate()).toBe(false);
    expect(validations[0]).toHaveBeenCalledOnce();
    expect(validations[1]).toHaveBeenCalledOnce();
  });
});
