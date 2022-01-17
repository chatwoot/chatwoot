export default [
  {
    name: 'Custom view',
    filter_type: 'conversation',
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
    filter_type: 'conversation',
    query: {
      payload: [
        {
          attribute_key: 'browser_language',
          filter_operator: 'equal_to',
          values: ['eng'],
          query_operator: 'or',
        },
        {
          attribute_key: 'campaign_id',
          filter_operator: 'equal_to',
          values: [15],
          query_operator: 'and',
        },
      ],
    },
  },
];
