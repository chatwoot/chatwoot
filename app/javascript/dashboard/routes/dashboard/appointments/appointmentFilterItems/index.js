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
    attributeKey: 'scheduled_at',
    attributeI18nKey: 'SCHEDULED_AT',
    inputType: 'date',
    dataType: 'text',
    filterOperators: OPERATOR_TYPES_5,
    attributeModel: 'standard',
  },
  {
    attributeKey: 'ended_at',
    attributeI18nKey: 'ENDED_AT',
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
        key: 'scheduled_at',
        i18nKey: 'SCHEDULED_AT',
      },
      {
        key: 'ended_at',
        i18nKey: 'ENDED_AT',
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
