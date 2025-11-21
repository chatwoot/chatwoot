import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useOperators } from './operators';

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

const PAYMENT_LINK_ATTRIBUTES = {
  STATUS: 'status',
  AMOUNT: 'amount',
  CREATED_AT: 'created_at',
  PAID_AT: 'paid_at',
};

/**
 * Composable that provides payment link filtering context
 * @returns {{ filterTypes: import('vue').ComputedRef<FilterType[]> }}
 */
export function usePaymentLinkFilterContext() {
  const { t } = useI18n();

  const { equalityOperators, dateOperators, comparisonOperators } =
    useOperators();

  /**
   * @type {import('vue').ComputedRef<FilterType[]>}
   */
  const filterTypes = computed(() => [
    {
      attributeKey: PAYMENT_LINK_ATTRIBUTES.STATUS,
      value: PAYMENT_LINK_ATTRIBUTES.STATUS,
      attributeName: t('PAYMENT_LINKS.FILTER.STATUS'),
      label: t('PAYMENT_LINKS.FILTER.STATUS'),
      inputType: 'multiSelect',
      dataType: 'text',
      options: [
        {
          id: 'initiated',
          name: t('PAYMENT_LINKS.STATUS.INITIATED'),
        },
        {
          id: 'pending',
          name: t('PAYMENT_LINKS.STATUS.PENDING'),
        },
        {
          id: 'paid',
          name: t('PAYMENT_LINKS.STATUS.PAID'),
        },
        {
          id: 'failed',
          name: t('PAYMENT_LINKS.STATUS.FAILED'),
        },
        {
          id: 'expired',
          name: t('PAYMENT_LINKS.STATUS.EXPIRED'),
        },
        {
          id: 'cancelled',
          name: t('PAYMENT_LINKS.STATUS.CANCELLED'),
        },
      ],
      filterOperators: equalityOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: PAYMENT_LINK_ATTRIBUTES.AMOUNT,
      value: PAYMENT_LINK_ATTRIBUTES.AMOUNT,
      attributeName: t('PAYMENT_LINKS.FILTER.AMOUNT'),
      label: t('PAYMENT_LINKS.FILTER.AMOUNT'),
      inputType: 'plainText',
      dataType: 'number',
      filterOperators: comparisonOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: PAYMENT_LINK_ATTRIBUTES.CREATED_AT,
      value: PAYMENT_LINK_ATTRIBUTES.CREATED_AT,
      attributeName: t('PAYMENT_LINKS.FILTER.CREATED_AT'),
      label: t('PAYMENT_LINKS.FILTER.CREATED_AT'),
      inputType: 'date',
      dataType: 'text',
      filterOperators: dateOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: PAYMENT_LINK_ATTRIBUTES.PAID_AT,
      value: PAYMENT_LINK_ATTRIBUTES.PAID_AT,
      attributeName: t('PAYMENT_LINKS.FILTER.PAID_AT'),
      label: t('PAYMENT_LINKS.FILTER.PAID_AT'),
      inputType: 'date',
      dataType: 'text',
      filterOperators: dateOperators.value,
      attributeModel: 'standard',
    },
  ]);

  return { filterTypes };
}
