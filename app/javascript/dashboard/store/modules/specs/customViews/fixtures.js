export default [
  {
    name: 'Custom view',
    filter_type: 0,
    query: {
      payload: [
        {
          attribute_key: 'assignee_id',
          filter_operator: 'equal_to',
          values: [45],
          query_operator: 'and',
        },
        {
          attribute_key: 'inbox_id',
          filter_operator: 'equal_to',
          values: [144],
          query_operator: 'and',
        },
      ],
    },
  },
  {
    name: 'Custom view 1',
    filter_type: 1,
    query: {
      payload: [
        {
          attribute_key: 'name',
          filter_operator: 'equal_to',
          values: ['john doe'],
          query_operator: null,
        },
      ],
    },
  },
];
