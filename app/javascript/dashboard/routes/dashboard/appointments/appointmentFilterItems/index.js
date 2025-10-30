import {
  OPERATOR_TYPES_1,
  OPERATOR_TYPES_3,
  OPERATOR_TYPES_5,
} from 'dashboard/components/widgets/FilterInput/FilterOperatorTypes.js';

const filterTypes = [
  {
    attributeKey: 'location',
    attributeI18nKey: 'LOCATION',
    inputType: 'plain_text',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_1,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'description',
    attributeI18nKey: 'DESCRIPTION',
    inputType: 'plain_text',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_1,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'start_time',
    attributeI18nKey: 'START_TIME',
    inputType: 'date',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_5,
    attributeModel: 'standard',
  },
  {
    attributeKey: 'end_time',
    attributeI18nKey: 'END_TIME',
    inputType: 'date',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_5,
    attributeModel: 'standard',
  },
  {
    attributeKey: 'assisted',
    attributeI18nKey: 'ASSISTED',
    inputType: 'search_select',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_1,
    attributeModel: 'standard',
  },
  {
    attributeKey: 'contact_name',
    attributeI18nKey: 'CONTACT_NAME',
    inputType: 'plain_text',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_3,
    attribute_type: 'standard',
  },
  {
    attributeKey: 'contact_email',
    attributeI18nKey: 'CONTACT_EMAIL',
    inputType: 'plain_text',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_3,
    attribute_type: 'standard',
  },
];

export const filterAttributeGroups = [
  {
    name: 'Appointment Filters',
    i18nGroup: 'APPOINTMENT_FILTERS',
    attributes: [
      {
        key: 'location',
        i18nKey: 'LOCATION',
      },
      {
        key: 'description',
        i18nKey: 'DESCRIPTION',
      },
      {
        key: 'start_time',
        i18nKey: 'START_TIME',
      },
      {
        key: 'end_time',
        i18nKey: 'END_TIME',
      },
      {
        key: 'assisted',
        i18nKey: 'ASSISTED',
      },
      {
        key: 'contact_name',
        i18nKey: 'CONTACT_NAME',
      },
      {
        key: 'contact_email',
        i18nKey: 'CONTACT_EMAIL',
      },
    ],
  },
];

export default filterTypes;
