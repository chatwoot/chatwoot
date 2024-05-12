import {
  OPERATOR_TYPES_1,
  OPERATOR_TYPES_2,
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
    attributeKey: 'assignee_id_in_leads',
    attributeI18nKey: 'LEADS_ASSIGNEE',
    inputType: 'search_select',
    dataType: 'number',
    filterOperators: OPERATOR_TYPES_2,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'assignee_id_in_deals',
    attributeI18nKey: 'DEALS_ASSIGNEE',
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
        key: 'assignee_id_in_leads',
        i18nKey: 'LEADS_ASSIGNEE',
      },
      {
        key: 'assignee_id_in_deals',
        i18nKey: 'DEALS_ASSIGNEE',
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
