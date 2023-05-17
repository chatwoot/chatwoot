import actionQueryGenerator from '../actionQueryGenerator';

const testData = [
  {
    action_name: 'add_label',
    action_params: [{ id: 'testlabel', name: 'testlabel' }],
  },
  {
    action_name: 'add_label_empty',
    action_params: [],
  },
  {
    action_name: 'add_label_string_array',
    action_params: ['test_1', 'test_2', 'test_3'],
  },
  {
    action_name: 'add_label_number_array',
    action_params: [1, 2, 3],
  },
  {
    action_name: 'assign_team',
    action_params: [
      {
        id: 1,
        name: 'sales team',
        description: 'This is our internal sales team',
        allow_auto_assign: true,
        account_id: 1,
        is_member: true,
      },
    ],
  },
  {
    action_name: 'assign_priority',
    action_params: { id: 'high', name: 'High' },
  },
  {
    action_name: 'test_action_params_with_id_and_value',
    action_params: { value: null, id: 'should-be-skipped', name: 'None' },
  },
  {
    action_name: 'test_action_with_no_id_no_value',
    action_params: { name: 'High' },
  },
  {
    action_name: 'test_action_with_nullish_action_params',
    action_params: null,
  },
  {
    action_name: 'test_action_with_simple_value_as_action_params',
    action_params: 'some-value',
  },
];

const finalResult = [
  {
    action_name: 'add_label',
    action_params: ['testlabel'],
  },
  {
    action_name: 'add_label_empty',
    action_params: [],
  },
  {
    action_name: 'add_label_string_array',
    action_params: ['test_1', 'test_2', 'test_3'],
  },
  {
    action_name: 'add_label_number_array',
    action_params: [1, 2, 3],
  },
  {
    action_name: 'assign_team',
    action_params: [1],
  },
  {
    action_name: 'assign_priority',
    action_params: ['high'],
  },
  {
    action_name: 'test_action_params_with_id_and_value',
    action_params: [null],
  },
  {
    action_name: 'test_action_with_no_id_no_value',
    action_params: [
      {
        name: 'High',
      },
    ],
  },
  {
    action_name: 'test_action_with_nullish_action_params',
    action_params: [],
  },
  {
    action_name: 'test_action_with_simple_value_as_action_params',
    action_params: ['some-value'],
  },
];

describe('#actionQueryGenerator', () => {
  it('returns the correct format of filter query', () => {
    expect(actionQueryGenerator(testData)).toEqual(finalResult);
    expect(
      actionQueryGenerator(testData).every(i => Array.isArray(i.action_params))
    ).toBe(true);
  });
});
