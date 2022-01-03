const filterTypes = [
  {
    attributeKey: 'status',
    attributeI18nKey: 'STATUS',
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
    attributeI18nKey: 'ASSIGNEE_NAME',
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
    attributeKey: 'inbox_id',
    attributeI18nKey: 'INBOX_NAME',
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
    attributeI18nKey: 'TEAM_NAME',
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
    attributeKey: 'display_id',
    attributeI18nKey: 'CONVERSATION_IDENTIFIER',
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
    attributeI18nKey: 'CAMPAIGN_NAME',
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
    attributeI18nKey: 'LABELS',
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
    attributeI18nKey: 'BROWSER_LANGUAGE',
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
    attributeI18nKey: 'COUNTRY_NAME',
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
    attributeI18nKey: 'REFERER_LINK',
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
