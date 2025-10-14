import {
  OPERATOR_TYPES_1,
  OPERATOR_TYPES_2,
  OPERATOR_TYPES_5,
} from '../../FilterInput/FilterOperatorTypes';

const filterTypes = [
  {
    attributeKey: 'status',
    attributeI18nKey: 'STATUS',
    inputType: 'multi_select',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_1,
    attributeModel: 'standard',
  },
  {
    attributeKey: 'assignee_id',
    attributeI18nKey: 'ASSIGNEE_NAME',
    inputType: 'search_select',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_2,
    attributeModel: 'standard',
  },
  {
    attributeKey: 'priority',
    attributeI18nKey: 'PRIORITY',
    inputType: 'multi_select',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_1,
    attributeModel: 'standard',
  },
  {
    attributeKey: 'inbox_id',
    attributeI18nKey: 'INBOX_NAME',
    inputType: 'search_select',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_2,
    attributeModel: 'standard',
  },
  {
    attributeKey: 'team_id',
    attributeI18nKey: 'TEAM_NAME',
    inputType: 'search_select',
    dataType: 'number',
    filterOperators: OPERATOR_TYPES_2,
    attributeModel: 'standard',
  },
  {
    attributeKey: 'campaign_id',
    attributeI18nKey: 'CAMPAIGN_NAME',
    inputType: 'search_select',
    dataType: 'Number',
    filterOperators: OPERATOR_TYPES_2,
    attributeModel: 'standard',
  },
  {
    attributeKey: 'labels',
    attributeI18nKey: 'LABELS',
    inputType: 'multi_select',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_2,
    attributeModel: 'standard',
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
        key: 'status',
        i18nKey: 'STATUS',
      },
      {
        key: 'assignee_id',
        i18nKey: 'ASSIGNEE_NAME',
      },
      {
        key: 'inbox_id',
        i18nKey: 'INBOX_NAME',
      },
      {
        key: 'team_id',
        i18nKey: 'TEAM_NAME',
      },
      {
        key: 'campaign_id',
        i18nKey: 'CAMPAIGN_NAME',
      },
      {
        key: 'labels',
        i18nKey: 'LABELS',
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
  {
    name: 'Additional Filters',
    i18nGroup: 'ADDITIONAL_FILTERS',
    attributes: [],
  },
];

export default filterTypes;
