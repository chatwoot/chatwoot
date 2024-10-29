export const contactViewList = [
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

export const customViewList = [
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
    filter_type: 0,
    query: {
      payload: [
        {
          attribute_key: 'assignee_id',
          filter_operator: 'equal_to',
          values: [45],
          query_operator: 'and',
        },
      ],
    },
  },
];

export const updateCustomViewList = [
  {
    id: 1,
    name: 'Open',
    filter_type: 'conversation',
    query: {
      payload: [
        {
          attribute_key: 'status',
          attribute_model: 'standard',
          filter_operator: 'equal_to',
          values: ['open'],
          query_operator: 'and',
          custom_attribute_type: '',
        },
        {
          attribute_key: 'assignee_id',
          filter_operator: 'equal_to',
          values: [52],
          custom_attribute_type: '',
        },
      ],
    },
    created_at: '2022-02-08T03:17:38.761Z',
    updated_at: '2023-06-05T13:57:48.478Z',
  },
];
