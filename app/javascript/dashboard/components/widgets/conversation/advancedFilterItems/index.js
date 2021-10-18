const filterTypes = [
  {
    attribute_key: 'status',
    attribute_name: 'Status',
    input_type: 'multi_select',
    data_type: 'text',
    filter_operators: [
      {
        key: 'equal_to',
        value: 'Equal to',
      },
      {
        key: 'not_equal_to',
        value: 'Not Equal to',
      },
    ],
    attribute_type: 'standard',
  },
  {
    attribute_key: 'assignee',
    attribute_name: 'Assignee Name',
    input_type: 'search_select',
    data_type: 'text',
    filter_operators: [
      {
        key: 'equal_to',
        value: 'Equal to',
      },
      {
        key: 'not_equal_to',
        value: 'Not Equal to',
      },
      {
        key: 'contains',
        value: 'Contains',
      },
      {
        key: 'does_not_contain',
        value: 'Does no contain',
      },
      {
        key: 'is_present',
        value: 'Is present',
      },
      {
        key: 'is_not_present',
        value: 'Is not present',
      },
    ],
    attribute_type: 'standard',
  },
  {
    attribute_key: 'contact',
    attribute_name: 'Contact Name',
    input_type: 'search_select',
    data_type: 'text',
    filter_operators: [
      {
        key: 'equal_to',
        value: 'Equal to',
      },
      {
        key: 'not_equal_to',
        value: 'Not Equal to',
      },
      {
        key: 'contains',
        value: 'Contains',
      },
      {
        key: 'does_not_contain',
        value: 'Does no contain',
      },
      {
        key: 'is_present',
        value: 'Is present',
      },
      {
        key: 'is_not_present',
        value: 'Is not present',
      },
    ],
    attribute_type: 'standard',
  },
  {
    attribute_key: 'inbox',
    attribute_name: 'Inbox Name',
    input_type: 'search_select',
    data_type: 'text',
    filter_operators: [
      {
        key: 'equal_to',
        value: 'Equal to',
      },
      {
        key: 'not_equal_to',
        value: 'Not Equal to',
      },
      {
        key: 'contains',
        value: 'Contains',
      },
      {
        key: 'does_not_contain',
        value: 'Does no contain',
      },
      {
        key: 'is_present',
        value: 'Is present',
      },
      {
        key: 'is_not_present',
        value: 'Is not present',
      },
    ],
    attribute_type: 'standard',
  },
  {
    attribute_key: 'team_id',
    attribute_name: 'Team Name',
    input_type: 'search_select',
    data_type: 'number',
    filter_operators: [
      {
        key: 'equal_to',
        value: 'Equal to',
      },
      {
        key: 'not_equal_to',
        value: 'Not Equal to',
      },
      {
        key: 'contains',
        value: 'Contains',
      },
      {
        key: 'does_not_contain',
        value: 'Does no contain',
      },
      {
        key: 'is_present',
        value: 'Is present',
      },
      {
        key: 'is_not_present',
        value: 'Is not present',
      },
    ],
    attribute_type: 'standard',
  },
  {
    attribute_key: 'id',
    attribute_name: 'Conversation Identifier',
    input_type: 'plain_text',
    data_type: 'Number',
    filter_operators: [
      {
        key: 'equal_to',
        value: 'Equal to',
      },
      {
        key: 'not_equal_to',
        value: 'Not Equal to',
      },
      {
        key: 'contains',
        value: 'Contains',
      },
      {
        key: 'does_not_contain',
        value: 'Does no contain',
      },
      {
        key: 'is_present',
        value: 'Is present',
      },
      {
        key: 'is_not_present',
        value: 'Is not present',
      },
    ],
    attribute_type: 'standard',
  },
  {
    attribute_key: 'campaign_id',
    attribute_name: 'Campaign Name',
    input_type: 'search_select',
    data_type: 'Number',
    filter_operators: [
      {
        key: 'equal_to',
        value: 'Equal to',
      },
      {
        key: 'not_equal_to',
        value: 'Not Equal to',
      },
      {
        key: 'contains',
        value: 'Contains',
      },
      {
        key: 'does_not_contain',
        value: 'Does no contain',
      },
      {
        key: 'is_present',
        value: 'Is present',
      },
      {
        key: 'is_not_present',
        value: 'Is not present',
      },
    ],
    attribute_type: 'standard',
  },
  {
    attribute_key: 'labels',
    attribute_name: 'Labels',
    input_type: 'multi_select',
    data_type: 'text',
    filter_operators: [
      {
        key: 'equal_to',
        value: 'Equal to',
      },
      {
        key: 'not_equal_to',
        value: 'Not Equal to',
      },
      {
        key: 'contains',
        value: 'Contains',
      },
      {
        key: 'does_not_contain',
        value: 'Does no contain',
      },
      {
        key: 'is_present',
        value: 'Is present',
      },
      {
        key: 'is_not_present',
        value: 'Is not present',
      },
    ],
    attribute_type: 'standard',
  },
  {
    attribute_key: 'browser',
    attribute_name: 'Browser',
    input_type: 'search_select',
    data_type: 'text',
    filter_operators: [
      {
        key: 'equal_to',
        value: 'Equal to',
      },
      {
        key: 'not_equal_to',
        value: 'Not Equal to',
      },
      {
        key: 'contains',
        value: 'Contains',
      },
      {
        key: 'does_not_contain',
        value: 'Does no contain',
      },
    ],
    attribute_type: 'additional_attributes',
  },
  {
    attribute_key: 'country_code',
    attribute_name: 'Country Name',
    input_type: 'search_select',
    data_type: 'text',
    filter_operators: [
      {
        key: 'equal_to',
        value: 'Equal to',
      },
      {
        key: 'not_equal_to',
        value: 'Not Equal to',
      },
      {
        key: 'contains',
        value: 'Contains',
      },
      {
        key: 'does_not_contain',
        value: 'Does no contain',
      },
      {
        key: 'is_present',
        value: 'Is present',
      },
      {
        key: 'is_not_present',
        value: 'Is not present',
      },
    ],
    attribute_type: 'additional_attributes',
  },
  {
    attribute_key: 'referer',
    attribute_name: 'Referer link',
    input_type: 'plain_text',
    data_type: 'text',
    filter_operators: [
      {
        key: 'equal_to',
        value: 'Equal to',
      },
      {
        key: 'not_equal_to',
        value: 'Not Equal to',
      },
      {
        key: 'contains',
        value: 'Contains',
      },
      {
        key: 'does_not_contain',
        value: 'Does no contain',
      },
      {
        key: 'is_present',
        value: 'Is present',
      },
      {
        key: 'is_not_present',
        value: 'Is not present',
      },
    ],
    attribute_type: 'additional_attributes',
  },
];

export default filterTypes;
