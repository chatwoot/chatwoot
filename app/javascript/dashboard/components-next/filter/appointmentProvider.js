import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useOperators } from './operators';

const APPOINTMENT_ATTRIBUTES = {
  LOCATION: 'location',
  DESCRIPTION: 'description',
  START_TIME: 'start_time',
  END_TIME: 'end_time',
  ASSISTED: 'assisted',
  CONTACT_NAME: 'contact_name',
  CONTACT_EMAIL: 'contact_email',
};

export function useAppointmentFilterContext() {
  const { t } = useI18n();

  const { equalityOperators, containmentOperators, dateOperators } =
    useOperators();

  const filterTypes = computed(() => [
    {
      attributeKey: APPOINTMENT_ATTRIBUTES.LOCATION,
      value: APPOINTMENT_ATTRIBUTES.LOCATION,
      attributeName: t('APPOINTMENTS.FILTER.LOCATION'),
      label: t('APPOINTMENTS.FILTER.LOCATION'),
      inputType: 'plainText',
      dataType: 'text',
      filterOperators: equalityOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: APPOINTMENT_ATTRIBUTES.DESCRIPTION,
      value: APPOINTMENT_ATTRIBUTES.DESCRIPTION,
      attributeName: t('APPOINTMENTS.FILTER.DESCRIPTION'),
      label: t('APPOINTMENTS.FILTER.DESCRIPTION'),
      inputType: 'plainText',
      dataType: 'text',
      filterOperators: equalityOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: APPOINTMENT_ATTRIBUTES.START_TIME,
      value: APPOINTMENT_ATTRIBUTES.START_TIME,
      attributeName: t('APPOINTMENTS.FILTER.START_TIME'),
      label: t('APPOINTMENTS.FILTER.START_TIME'),
      inputType: 'date',
      dataType: 'text',
      filterOperators: dateOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: APPOINTMENT_ATTRIBUTES.END_TIME,
      value: APPOINTMENT_ATTRIBUTES.END_TIME,
      attributeName: t('APPOINTMENTS.FILTER.END_TIME'),
      label: t('APPOINTMENTS.FILTER.END_TIME'),
      inputType: 'date',
      dataType: 'text',
      filterOperators: dateOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: APPOINTMENT_ATTRIBUTES.ASSISTED,
      value: APPOINTMENT_ATTRIBUTES.ASSISTED,
      attributeName: t('APPOINTMENTS.FILTER.ASSISTED'),
      label: t('APPOINTMENTS.FILTER.ASSISTED'),
      inputType: 'searchSelect',
      options: [
        {
          id: 'true',
          name: t('APPOINTMENTS.TABLE.YES'),
        },
        {
          id: 'false',
          name: t('APPOINTMENTS.TABLE.NO'),
        },
      ],
      dataType: 'text',
      filterOperators: equalityOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: APPOINTMENT_ATTRIBUTES.CONTACT_NAME,
      value: APPOINTMENT_ATTRIBUTES.CONTACT_NAME,
      attributeName: t('APPOINTMENTS.FILTER.CONTACT_NAME'),
      label: t('APPOINTMENTS.FILTER.CONTACT_NAME'),
      inputType: 'plainText',
      dataType: 'text',
      filterOperators: containmentOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: APPOINTMENT_ATTRIBUTES.CONTACT_EMAIL,
      value: APPOINTMENT_ATTRIBUTES.CONTACT_EMAIL,
      attributeName: t('APPOINTMENTS.FILTER.CONTACT_EMAIL'),
      label: t('APPOINTMENTS.FILTER.CONTACT_EMAIL'),
      inputType: 'plainText',
      dataType: 'text',
      filterOperators: containmentOperators.value,
      attributeModel: 'standard',
    },
  ]);

  return { filterTypes };
}
