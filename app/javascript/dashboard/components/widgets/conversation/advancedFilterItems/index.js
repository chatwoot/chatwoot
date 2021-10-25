const filterTypes = [
  {
    attributeKey: 'status',
    attributeName: 'Status',
    inputType: 'multi_select',
    dataType: 'text',
    filterOperators: [
      {
        value: 'equal_to',
        label: 'Equal to',
      },
      {
        value: 'not_equal_to',
        label: 'Not equal to',
      },
    ],
    attribute_type: 'standard',
  },
  {
    attributeKey: 'assignee_id',
    attributeName: 'Assignee Name',
    inputType: 'search_select',
    dataType: 'text',
    filterOperators: [
      {
        value: 'equal_to',
        label: 'Equal to',
      },
      {
        value: 'not_equal_to',
        label: 'Not equal to',
      },
      {
        value: 'contains',
        label: 'Contains',
      },
      {
        value: 'does_not_contain',
        label: 'Does not contain',
      },
      {
        value: 'is_present',
        label: 'Is present',
      },
      {
        value: 'is_not_present',
        label: 'Is not present',
      },
    ],
    attribute_type: 'standard',
  },
  {
    attributeKey: 'contact',
    attributeName: 'Contact Name',
    inputType: 'search_select',
    dataType: 'text',
    filterOperators: [
      {
        value: 'equal_to',
        label: 'Equal to',
      },
      {
        value: 'not_equal_to',
        label: 'Not equal to',
      },
      {
        value: 'contains',
        label: 'Contains',
      },
      {
        value: 'does_not_contain',
        label: 'Does not contain',
      },
      {
        value: 'is_present',
        label: 'Is present',
      },
      {
        value: 'is_not_present',
        label: 'Is not present',
      },
    ],
    attribute_type: 'standard',
  },
  {
    attributeKey: 'inbox',
    attributeName: 'Inbox Name',
    inputType: 'search_select',
    dataType: 'text',
    filterOperators: [
      {
        value: 'equal_to',
        label: 'Equal to',
      },
      {
        value: 'not_equal_to',
        label: 'Not equal to',
      },
      {
        value: 'contains',
        label: 'Contains',
      },
      {
        value: 'does_not_contain',
        label: 'Does not contain',
      },
      {
        value: 'is_present',
        label: 'Is present',
      },
      {
        value: 'is_not_present',
        label: 'Is not present',
      },
    ],
    attribute_type: 'standard',
  },
  {
    attributeKey: 'team_id',
    attributeName: 'Team Name',
    inputType: 'search_select',
    dataType: 'number',
    filterOperators: [
      {
        value: 'equal_to',
        label: 'Equal to',
      },
      {
        value: 'not_equal_to',
        label: 'Not equal to',
      },
      {
        value: 'contains',
        label: 'Contains',
      },
      {
        value: 'does_not_contain',
        label: 'Does not contain',
      },
      {
        value: 'is_present',
        label: 'Is present',
      },
      {
        value: 'is_not_present',
        label: 'Is not present',
      },
    ],
    attribute_type: 'standard',
  },
  {
    attributeKey: 'id',
    attributeName: 'Conversation Identifier',
    inputType: 'plain_text',
    dataType: 'Number',
    filterOperators: [
      {
        value: 'equal_to',
        label: 'Equal to',
      },
      {
        value: 'not_equal_to',
        label: 'Not equal to',
      },
      {
        value: 'contains',
        label: 'Contains',
      },
      {
        value: 'does_not_contain',
        label: 'Does not contain',
      },
    ],
    attribute_type: 'standard',
  },
  {
    attributeKey: 'campaign_id',
    attributeName: 'Campaign Name',
    inputType: 'search_select',
    dataType: 'Number',
    filterOperators: [
      {
        value: 'equal_to',
        label: 'Equal to',
      },
      {
        value: 'not_equal_to',
        label: 'Not equal to',
      },
      {
        value: 'contains',
        label: 'Contains',
      },
      {
        value: 'does_not_contain',
        label: 'Does not contain',
      },
      {
        value: 'is_present',
        label: 'Is present',
      },
      {
        value: 'is_not_present',
        label: 'Is not present',
      },
    ],
    attribute_type: 'standard',
  },
  {
    attributeKey: 'labels',
    attributeName: 'Labels',
    inputType: 'multi_select',
    dataType: 'text',
    filterOperators: [
      {
        value: 'equal_to',
        label: 'Equal to',
      },
      {
        value: 'not_equal_to',
        label: 'Not equal to',
      },
      {
        value: 'contains',
        label: 'Contains',
      },
      {
        value: 'does_not_contain',
        label: 'Does not contain',
      },
      {
        value: 'is_present',
        label: 'Is present',
      },
      {
        value: 'is_not_present',
        label: 'Is not present',
      },
    ],
    attribute_type: 'standard',
  },
  {
    attributeKey: 'browser_language',
    attributeName: 'Browser Language',
    inputType: 'search_select',
    dataType: 'text',
    filterOperators: [
      {
        value: 'equal_to',
        label: 'Equal to',
      },
      {
        value: 'not_equal_to',
        label: 'Not equal to',
      },
    ],
    attribute_type: 'additional_attributes',
  },
  {
    attributeKey: 'country_code',
    attributeName: 'Country Name',
    inputType: 'search_select',
    dataType: 'text',
    filterOperators: [
      {
        value: 'equal_to',
        label: 'Equal to',
      },
      {
        value: 'not_equal_to',
        label: 'Not equal to',
      },
    ],
    attribute_type: 'additional_attributes',
  },
  {
    attributeKey: 'referer',
    attributeName: 'Referer link',
    inputType: 'plain_text',
    dataType: 'text',
    filterOperators: [
      {
        value: 'equal_to',
        label: 'Equal to',
      },
      {
        value: 'not_equal_to',
        label: 'Not equal to',
      },
      {
        value: 'contains',
        label: 'Contains',
      },
      {
        value: 'does_not_contain',
        label: 'Does not contain',
      },
    ],
    attribute_type: 'additional_attributes',
  },
];

export default filterTypes;
