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
    action_name: 'test_action_2',
    action_params: { value: null, id: 'null', name: 'None' },
  },
  {
    action_name: 'test_action',
    action_params: { name: 'High' },
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
    action_name: 'assign_team',
    action_params: [1],
  },
  {
    action_name: 'assign_priority',
    action_params: ['high'],
  },
  {
    action_name: 'test_action_2',
    action_params: [null],
  },
  {
    action_name: 'test_action',
    action_params: [
      {
        name: 'High',
      },
    ],
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
