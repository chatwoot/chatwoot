const filterTypes = [
  {
    attributeKey: 'name',
    attributeI18nKey: 'NAME',
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
    attribute_type: 'standard',
  },
  {
    attributeKey: 'email',
    attributeI18nKey: 'EMAIL',
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
    attribute_type: 'standard',
  },
  {
    attributeKey: 'phone_number',
    attributeI18nKey: 'PHONE_NUMBER',
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
    attribute_type: 'standard',
  },
  {
    attributeKey: 'identifier',
    attributeI18nKey: 'IDENTIFIER',
    inputType: 'plain_text',
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
    ],
    attribute_type: 'standard',
  },
  {
    attributeKey: 'country_code',
    attributeI18nKey: 'COUNTRY',
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
    ],
    attribute_type: 'standard',
  },
  {
    attributeKey: 'city',
    attributeI18nKey: 'CITY',
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
];

export default filterTypes;
