import {
  OPERATOR_TYPES_1,
  OPERATOR_TYPES_2,
  OPERATOR_TYPES_3,
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
    attributeKey: 'display_id',
    attributeI18nKey: 'CONVERSATION_IDENTIFIER',
    inputType: 'plain_text',
    dataType: 'Number',
    filterOperators: OPERATOR_TYPES_3,
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
    attributeKey: 'browser_language',
    attributeI18nKey: 'BROWSER_LANGUAGE',
    inputType: 'search_select',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_1,
    attributeModel: 'additional',
  },
  {
    attributeKey: 'country_code',
    attributeI18nKey: 'COUNTRY_NAME',
    inputType: 'search_select',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_1,
    attributeModel: 'additional',
  },
  {
    attributeKey: 'referer',
    attributeI18nKey: 'REFERER_LINK',
    inputType: 'plain_text',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_3,
    attributeModel: 'additional',
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
        key: 'display_id',
        i18nKey: 'CONVERSATION_IDENTIFIER',
      },
      {
        key: 'campaign_id',
        i18nKey: 'CAMPAIGN_NAME',
      },
      {
        key: 'labels',
        i18nKey: 'LABELS',
      },
    ],
  },
  {
    name: 'Additional Filters',
    i18nGroup: 'ADDITIONAL_FILTERS',
    attributes: [
      {
        key: 'browser_language',
        i18nKey: 'BROWSER_LANGUAGE',
      },
      {
        key: 'country_code',
        i18nKey: 'COUNTRY_NAME',
      },
      {
        key: 'referer',
        i18nKey: 'REFERER_LINK',
      },
    ],
  },
];

export default filterTypes;
