export default [
  {
    name: 'Test 5',
    description: 'Hello',
    id: 46,
    account_id: 1,
    event_name: 'conversation_created',
    conditions: [
      {
        values: ['open'],
        attribute_key: 'status',
        filter_operator: 'equal_to',
      },
    ],
    actions: [{ action_name: 'add_label', action_params: ['testlabel'] }],
    created_on: '2022-02-08T10:46:32.387Z',
    active: true,
  },
  {
    id: 47,
    account_id: 1,
    name: 'Snooze',
    description: 'Test Description',
    event_name: 'conversation_created',
    conditions: [
      {
        values: ['pending'],
        attribute_key: 'status',
        filter_operator: 'equal_to',
      },
    ],
    actions: [{ action_name: 'assign_team', action_params: [1] }],
    created_on: '2022-02-08T11:19:44.714Z',
    active: true,
  },
];
