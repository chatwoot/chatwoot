import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useOperators } from './operators';
import { useMapGetter } from 'dashboard/composables/store.js';
import { buildAttributesFilterTypes } from './helper/filterHelper.js';
import countries from 'shared/constants/countries.js';

/**
 * @typedef {Object} FilterOption
 * @property {string|number} id
 * @property {string} name
 * @property {import('vue').VNode} [icon]
 */

/**
 * @typedef {Object} FilterOperator
 * @property {string} value
 * @property {string} label
 * @property {string} icon
 * @property {boolean} hasInput
 */

/**
 * @typedef {Object} FilterType
 * @property {string} attributeKey - The attribute key
 * @property {string} value - This is a proxy for the attribute key used in FilterSelect
 * @property {string} attributeName - The attribute name used to display on the UI
 * @property {string} label - This is a proxy for the attribute name used in FilterSelect
 * @property {'multiSelect'|'searchSelect'|'plainText'|'date'|'booleanSelect'} inputType - The input type for the attribute
 * @property {FilterOption[]} [options] - The options available for the attribute if it is a multiSelect or singleSelect type
 * @property {'text'|'number'} dataType
 * @property {FilterOperator[]} filterOperators - The operators available for the attribute
 * @property {'standard'|'additional'|'customAttributes'} attributeModel
 */

/**
 * @typedef {Object} FilterGroup
 * @property {string} name
 * @property {FilterType[]} attributes
 */

/**
 * Composable that provides conversation filtering context
 * @returns {{ filterTypes: import('vue').ComputedRef<FilterType[]>, filterGroups: import('vue').ComputedRef<FilterGroup[]> }}
 */
export function useContactFilterContext() {
  const { t } = useI18n();

  const contactAttributes = useMapGetter('attributes/getContactAttributes');

  const {
    equalityOperators,
    containmentOperators,
    dateOperators,
    getOperatorTypes,
  } = useOperators();

  /**
   * @type {import('vue').ComputedRef<FilterType[]>}
   */
  const customFilterTypes = computed(() =>
    buildAttributesFilterTypes(contactAttributes.value, getOperatorTypes)
  );

  /**
   * @type {import('vue').ComputedRef<FilterType[]>}
   */
  const filterTypes = computed(() => [
    {
      attributeKey: 'name',
      value: 'name',
      attributeName: t('CONTACTS_LAYOUT.FILTER.NAME'),
      label: t('CONTACTS_LAYOUT.FILTER.NAME'),
      inputType: 'plainText',
      dataType: 'text',
      filterOperators: equalityOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: 'email',
      value: 'email',
      attributeName: t('CONTACTS_LAYOUT.FILTER.EMAIL'),
      label: t('CONTACTS_LAYOUT.FILTER.EMAIL'),
      inputType: 'plainText',
      dataType: 'text',
      filterOperators: containmentOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: 'phone_number',
      value: 'phone_number',
      attributeName: t('CONTACTS_LAYOUT.FILTER.PHONE_NUMBER'),
      label: t('CONTACTS_LAYOUT.FILTER.PHONE_NUMBER'),
      inputType: 'plainText',
      dataType: 'text',
      filterOperators: containmentOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: 'identifier',
      value: 'identifier',
      attributeName: t('CONTACTS_LAYOUT.FILTER.IDENTIFIER'),
      label: t('CONTACTS_LAYOUT.FILTER.IDENTIFIER'),
      inputType: 'plainText',
      dataType: 'number',
      filterOperators: equalityOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: 'country_code',
      value: 'country_code',
      attributeName: t('FILTER.ATTRIBUTES.COUNTRY_NAME'),
      label: t('FILTER.ATTRIBUTES.COUNTRY_NAME'),
      inputType: 'searchSelect',
      options: countries,
      dataType: 'number',
      filterOperators: equalityOperators.value,
      attributeModel: 'additional',
    },
    {
      attributeKey: 'city',
      value: 'city',
      attributeName: t('CONTACTS_LAYOUT.FILTER.CITY'),
      label: t('CONTACTS_LAYOUT.FILTER.CITY'),
      inputType: 'plainText',
      dataType: 'text',
      filterOperators: containmentOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: 'created_at',
      value: 'created_at',
      attributeName: t('CONTACTS_LAYOUT.FILTER.CREATED_AT'),
      label: t('CONTACTS_LAYOUT.FILTER.CREATED_AT'),
      inputType: 'date',
      dataType: 'text',
      filterOperators: dateOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: 'last_activity_at',
      value: 'last_activity_at',
      attributeName: t('CONTACTS_LAYOUT.FILTER.LAST_ACTIVITY'),
      label: t('CONTACTS_LAYOUT.FILTER.LAST_ACTIVITY'),
      inputType: 'date',
      dataType: 'text',
      filterOperators: dateOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: 'referer',
      value: 'referer',
      attributeName: t('CONTACTS_LAYOUT.FILTER.REFERER_LINK'),
      label: t('CONTACTS_LAYOUT.FILTER.REFERER_LINK'),
      inputType: 'plainText',
      dataType: 'text',
      filterOperators: containmentOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: 'blocked',
      value: 'blocked',
      attributeName: t('CONTACTS_LAYOUT.FILTER.BLOCKED'),
      label: t('CONTACTS_LAYOUT.FILTER.BLOCKED'),
      inputType: 'searchSelect',
      options: [
        {
          id: 'true',
          name: t('CONTACTS_LAYOUT.FILTER.BLOCKED_TRUE'),
        },
        {
          id: 'false',
          name: t('CONTACTS_LAYOUT.FILTER.BLOCKED_FALSE'),
        },
      ],
      dataType: 'text',
      filterOperators: equalityOperators.value,
      attributeModel: 'standard',
    },
    ...customFilterTypes.value,
  ]);

  return { filterTypes };
}
