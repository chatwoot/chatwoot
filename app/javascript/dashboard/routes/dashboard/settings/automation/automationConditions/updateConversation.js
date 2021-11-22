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

export default conditions;
