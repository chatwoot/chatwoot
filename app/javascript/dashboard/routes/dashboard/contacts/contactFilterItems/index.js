import {
  OPERATOR_TYPES_1,
  OPERATOR_TYPES_3,
} from 'dashboard/components/widgets/FilterInput/FilterOperatorTypes.js';
const filterTypes = [
  {
    attributeKey: 'name',
    attributeI18nKey: 'NAME',
    inputType: 'plain_text',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_1,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'email',
    attributeI18nKey: 'EMAIL',
    inputType: 'plain_text',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_3,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'phone_number',
    attributeI18nKey: 'PHONE_NUMBER',
    inputType: 'plain_text',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_3,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'identifier',
    attributeI18nKey: 'IDENTIFIER',
    inputType: 'plain_text',
    dataType: 'number',
    filterOperators: OPERATOR_TYPES_1,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'country_code',
    attributeI18nKey: 'COUNTRY',
    inputType: 'search_select',
    dataType: 'number',
    filterOperators: OPERATOR_TYPES_1,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'city',
    attributeI18nKey: 'CITY',
    inputType: 'plain_text',
    dataType: 'Number',
    filterOperators: OPERATOR_TYPES_3,
    attribute_type: 'standard',
  },
];

export const filterAttributeGroups = [
  {
    name: 'Standard Filters',
    i18nGroup: 'STANDARD_FILTERS',
    attributes: [
      {
        key: 'name',
        i18nKey: 'NAME',
      },
      {
        key: 'email',
        i18nKey: 'EMAIL',
      },
      {
        key: 'phone_number',
        i18nKey: 'PHONE_NUMBER',
      },
      {
        key: 'identifier',
        i18nKey: 'IDENTIFIER',
      },
      {
        key: 'country_code',
        i18nKey: 'COUNTRY',
      },
      {
        key: 'city',
        i18nKey: 'CITY',
      },
    ],
  },
];

export default filterTypes;
