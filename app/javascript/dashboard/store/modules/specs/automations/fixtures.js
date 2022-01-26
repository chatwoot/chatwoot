export default [
  {
    id: 12,
    account_id: 1,
    name: 'Test',
    description: 'This is a test',
    event_name: 'conversation_created',
    conditions: [
      {
        values: ['open'],
        attribute_key: 'status',
        query_operator: null,
        filter_operator: 'equal_to',
      },
    ],
    actions: [
      {
        action_name: 'add_label',
        action_params: [{}],
      },
    ],
    created_on: '2022-01-14T09:17:55.689Z',
    active: true,
  },
  {
    id: 13,
    account_id: 1,
    name: 'Auto resolve conversation',
    description: 'Auto resolves conversation',
    event_name: 'conversation_updated',
    conditions: [
      {
        values: ['resolved'],
        attribute_key: 'status',
        query_operator: null,
        filter_operator: 'equal_to',
      },
    ],
    actions: [
      {
        action_name: 'add_label',
        action_params: [{}],
      },
    ],
    created_on: '2022-01-14T13:06:31.843Z',
    active: true,
  },
  {
    id: 14,
    account_id: 1,
    name: 'Fayaz',
    description: 'This is a test',
    event_name: 'conversation_created',
    conditions: {},
    actions: [
      {
        action_name: 'add_label',
        action_params: [{}],
      },
    ],
    created_on: '2022-01-17T06:46:08.098Z',
    active: true,
  },
];
