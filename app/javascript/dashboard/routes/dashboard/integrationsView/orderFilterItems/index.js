import {
  OPERATOR_TYPES_1,
  OPERATOR_TYPES_3,
  OPERATOR_TYPES_5,
} from 'dashboard/components/widgets/FilterInput/FilterOperatorTypes.js';
const filterTypes = [
  {
    attributeKey: 'order_number',
    attributeI18nKey: 'ORDER_NUMBER',
    inputType: 'plain_text',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_1,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'status',
    attributeI18nKey: 'STATUS',
    inputType: 'plain_text',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_3,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'platform',
    attributeI18nKey: 'PLATFORM',
    inputType: 'plain_text',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_3,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'payment_status',
    attributeI18nKey: 'PAYMENT_STATUS',
    inputType: 'plain_text',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_3,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'created_via',
    attributeI18nKey: 'CREATED_VIA',
    inputType: 'plain_text',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_3,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'date_created',
    attributeI18nKey: 'CREATED_AT',
    inputType: 'date',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_5,
    attributeModel: 'standard',
  },
  {
    attributeKey: 'date_modified',
    attributeI18nKey: 'LAST_ACTIVITY',
    inputType: 'date',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_5,
    attributeModel: 'standard',
  },
];

export const filterAttributeGroups = [
  {
    name: 'Standard Filters',
    i18nGroup: 'STANDARD_FILTERS',
    attributes: [
      {
        key: 'order_number',
        i18nKey: 'ORDER_NUMBER',
      },
      {
        key: 'status',
        i18nKey: 'STATUS',
      },
      {
        key: 'platform',
        i18nKey: 'PLATFORM',
      },
      {
        key: 'payment_status',
        i18nKey: 'PAYMENT_STATUS',
      },
      {
        key: 'created_via',
        i18nKey: 'CREATED_VIA',
      },
      {
        key: 'date_created',
        i18nKey: 'CREATED_AT',
      },
      {
        key: 'date_modified',
        i18nKey: 'LAST_ACTIVITY',
      },
    ],
  },
];

export default filterTypes;
