import {
  OPERATOR_TYPES_1,
  OPERATOR_TYPES_2,
  OPERATOR_TYPES_4,
  OPERATOR_TYPES_5,
  OPERATOR_TYPES_6,
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
    filterOperators: OPERATOR_TYPES_6,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'phone_number',
    attributeI18nKey: 'PHONE_NUMBER',
    inputType: 'plain_text',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_6,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'initial_channel_type',
    attributeI18nKey: 'INITIAL_CHANNEL',
    inputType: 'plain_text',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_1,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'stage_id',
    attributeI18nKey: 'STAGE',
    inputType: 'search_select',
    dataType: 'number',
    filterOperators: OPERATOR_TYPES_2,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'assignee_id',
    attributeI18nKey: 'ASSIGNEE_ID',
    inputType: 'search_select',
    dataType: 'number',
    filterOperators: OPERATOR_TYPES_2,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'team_id',
    attributeI18nKey: 'TEAM',
    inputType: 'search_select',
    dataType: 'number',
    filterOperators: OPERATOR_TYPES_2,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'product_id',
    attributeI18nKey: 'PRODUCT',
    inputType: 'search_select',
    dataType: 'number',
    filterOperators: OPERATOR_TYPES_2,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'po_value',
    attributeI18nKey: 'PO_VALUE',
    inputType: 'number',
    dataType: 'number',
    filterOperators: OPERATOR_TYPES_4,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'po_date',
    attributeI18nKey: 'PO_DATE',
    inputType: 'date',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_5,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'created_at',
    attributeI18nKey: 'CREATED_AT',
    inputType: 'date',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_5,
    attributeModel: 'standard',
  },
  {
    attributeKey: 'last_activity_at',
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
        key: 'initial_channel_type',
        i18nKey: 'INITIAL_CHANNEL',
      },
      {
        key: 'stage_id',
        i18nKey: 'STAGE',
      },
      {
        key: 'assignee_id',
        i18nKey: 'ASSIGNEE_ID',
      },
      {
        key: 'product_id',
        i18nKey: 'PRODUCT',
      },
      {
        key: 'po_value',
        i18nKey: 'PO_VALUE',
      },
      {
        key: 'po_date',
        i18nKey: 'PO_DATE',
      },
      {
        key: 'team_id',
        i18nKey: 'TEAM',
      },
      {
        key: 'created_at',
        i18nKey: 'CREATED_AT',
      },
      {
        key: 'last_activity_at',
        i18nKey: 'LAST_ACTIVITY',
      },
    ],
  },
];

export default filterTypes;
