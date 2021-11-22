const conditions = [
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

export default conditions;
