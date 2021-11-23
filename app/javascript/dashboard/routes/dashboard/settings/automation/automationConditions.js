const CONVERSATION_STATUS_CONDITION = [
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
];

const BROWSER_LANGUAGE_CONDITION = [
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
];

const COUNTRY_NAME_CONDITION = [
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
];

export const REFERER_LINK_CONDITION = [
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

export const getAutomationCondition = ({ actionType = '' }) => {
  if (actionType === 'conversation_updated') {
    return [...CONVERSATION_STATUS_CONDITION, ...COUNTRY_NAME_CONDITION];
  }
  if (actionType === 'messaged_created') {
    return [...CONVERSATION_STATUS_CONDITION];
  }
  return [
    ...CONVERSATION_STATUS_CONDITION,
    ...BROWSER_LANGUAGE_CONDITION,
    ...COUNTRY_NAME_CONDITION,
    ...REFERER_LINK_CONDITION,
  ];
};
