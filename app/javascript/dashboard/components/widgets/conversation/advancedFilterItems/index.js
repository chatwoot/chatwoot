const OPERATOR_TYPES_1 = [
  {
    value: 'equal_to',
    label: 'Equal to',
  },
  {
    value: 'not_equal_to',
    label: 'Not equal to',
  },
];

const OPERATOR_TYPES_2 = [
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
];

const OPERATOR_TYPES_3 = [
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
];

const filterTypes = [
  {
    attributeKey: 'status',
    attributeI18nKey: 'STATUS',
    inputType: 'multi_select',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_1,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'assignee_id',
    attributeI18nKey: 'ASSIGNEE_NAME',
    inputType: 'search_select',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_2,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'inbox_id',
    attributeI18nKey: 'INBOX_NAME',
    inputType: 'search_select',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_2,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'team_id',
    attributeI18nKey: 'TEAM_NAME',
    inputType: 'search_select',
    dataType: 'number',
    filterOperators: OPERATOR_TYPES_2,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'display_id',
    attributeI18nKey: 'CONVERSATION_IDENTIFIER',
    inputType: 'plain_text',
    dataType: 'Number',
    filterOperators: OPERATOR_TYPES_3,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'campaign_id',
    attributeI18nKey: 'CAMPAIGN_NAME',
    inputType: 'search_select',
    dataType: 'Number',
    filterOperators: OPERATOR_TYPES_2,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'labels',
    attributeI18nKey: 'LABELS',
    inputType: 'multi_select',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_2,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'browser_language',
    attributeI18nKey: 'BROWSER_LANGUAGE',
    inputType: 'search_select',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_1,
    attribute_type: 'additional_attributes',
  },
  {
    attributeKey: 'country_code',
    attributeI18nKey: 'COUNTRY_NAME',
    inputType: 'search_select',
    dataType: 'text',
    filterOperators: 1,
    attribute_type: 'additional_attributes',
  },
  {
    attributeKey: 'referer',
    attributeI18nKey: 'REFERER_LINK',
    inputType: 'plain_text',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_3,
    attribute_type: 'additional_attributes',
  },
];

export const altSchema = [
  {
    group: 'Standard Filters',
    items: [
      {
        attributeKey: 'status',
        attributeI18nKey: 'STATUS',
        inputType: 'multi_select',
        dataType: 'text',
        filterOperators: OPERATOR_TYPES_1,
        attribute_type: 'standard',
      },
      {
        attributeKey: 'assignee_id',
        attributeI18nKey: 'ASSIGNEE_NAME',
        inputType: 'search_select',
        dataType: 'text',
        filterOperators: OPERATOR_TYPES_2,
        attribute_type: 'standard',
      },
      {
        attributeKey: 'inbox_id',
        attributeI18nKey: 'INBOX_NAME',
        inputType: 'search_select',
        dataType: 'text',
        filterOperators: OPERATOR_TYPES_2,
        attribute_type: 'standard',
      },
      {
        attributeKey: 'team_id',
        attributeI18nKey: 'TEAM_NAME',
        inputType: 'search_select',
        dataType: 'number',
        filterOperators: OPERATOR_TYPES_2,
        attribute_type: 'standard',
      },
      {
        attributeKey: 'display_id',
        attributeI18nKey: 'CONVERSATION_IDENTIFIER',
        inputType: 'plain_text',
        dataType: 'Number',
        filterOperators: OPERATOR_TYPES_3,
        attribute_type: 'standard',
      },
      {
        attributeKey: 'campaign_id',
        attributeI18nKey: 'CAMPAIGN_NAME',
        inputType: 'search_select',
        dataType: 'Number',
        filterOperators: OPERATOR_TYPES_2,
        attribute_type: 'standard',
      },
      {
        attributeKey: 'labels',
        attributeI18nKey: 'LABELS',
        inputType: 'multi_select',
        dataType: 'text',
        filterOperators: OPERATOR_TYPES_2,
        attribute_type: 'standard',
      },
    ],
  },
  {
    group: 'Additional Filters',
    items: [
      {
        attributeKey: 'browser_language',
        attributeI18nKey: 'BROWSER_LANGUAGE',
        inputType: 'search_select',
        dataType: 'text',
        filterOperators: OPERATOR_TYPES_1,
        attribute_type: 'additional_attributes',
      },
      {
        attributeKey: 'country_code',
        attributeI18nKey: 'COUNTRY_NAME',
        inputType: 'search_select',
        dataType: 'text',
        filterOperators: 1,
        attribute_type: 'additional_attributes',
      },
      {
        attributeKey: 'referer',
        attributeI18nKey: 'REFERER_LINK',
        inputType: 'plain_text',
        dataType: 'text',
        filterOperators: OPERATOR_TYPES_3,
        attribute_type: 'additional_attributes',
      },
    ],
  },
  {
    group: 'Custom Attributes',
    items: [
      {
        attributeKey: 'custom_attribute_list',
        attributeI18nKey: 'CUSTOM_ATTRIBUTE_LIST',
        inputType: 'plain_text',
        dataType: 'text',
        filterOperators: OPERATOR_TYPES_2,
        attribute_type: 'custom_attributes',
      },
      {
        attributeKey: 'custom_attribute_text',
        attributeI18nKey: 'CUSTOM_ATTRIBUTE_TEXT',
        inputType: 'plain_text',
        dataType: 'text',
        filterOperators: OPERATOR_TYPES_3,
        attribute_type: 'custom_attributes',
      },
      {
        attributeKey: 'custom_attribute_number',
        attributeI18nKey: 'CUSTOM_ATTRIBUTE_NUMBER',
        inputType: 'plain_text',
        dataType: 'text',
        filterOperators: OPERATOR_TYPES_2,
        attribute_type: 'custom_attributes',
      },
      {
        attributeKey: 'custom_attribute_link',
        attributeI18nKey: 'CUSTOM_ATTRIBUTE_LINK',
        inputType: 'plain_text',
        dataType: 'text',
        filterOperators: OPERATOR_TYPES_2,
        attribute_type: 'custom_attributes',
      },
    ],
  },
];

export default filterTypes;
