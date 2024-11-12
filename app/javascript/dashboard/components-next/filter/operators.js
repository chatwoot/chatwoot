import { computed, h } from 'vue';
import { useI18n } from 'vue-i18n';

/**
 * @typedef {Object} FilterOperations
 * @property {string} EQUAL_TO - Equals comparison
 * @property {string} NOT_EQUAL_TO - Not equals comparison
 * @property {string} IS_PRESENT - Present check
 * @property {string} IS_NOT_PRESENT - Not present check
 * @property {string} CONTAINS - Contains check
 * @property {string} DOES_NOT_CONTAIN - Does not contain check
 * @property {string} IS_GREATER_THAN - Greater than comparison
 * @property {string} IS_LESS_THAN - Less than comparison
 * @property {string} DAYS_BEFORE - Days before check
 * @property {string} STARTS_WITH - Starts with check
 */
const FILTER_OPS = {
  EQUAL_TO: 'equal_to',
  NOT_EQUAL_TO: 'not_equal_to',
  IS_PRESENT: 'is_present',
  IS_NOT_PRESENT: 'is_not_present',
  CONTAINS: 'contains',
  DOES_NOT_CONTAIN: 'does_not_contain',
  IS_GREATER_THAN: 'is_greater_than',
  IS_LESS_THAN: 'is_less_than',
  DAYS_BEFORE: 'days_before',
  STARTS_WITH: 'starts_with',
};

const NO_INPUT_OPTS = [FILTER_OPS.IS_PRESENT, FILTER_OPS.IS_NOT_PRESENT];
/**
 * @type {Object.<string, string>}
 */
const filterOperatorIcon = {
  [FILTER_OPS.EQUAL_TO]: 'i-ph-equals-bold',
  [FILTER_OPS.NOT_EQUAL_TO]: 'i-ph-not-equals-bold',
  [FILTER_OPS.IS_PRESENT]: 'i-ph-member-of-bold',
  [FILTER_OPS.IS_NOT_PRESENT]: 'i-ph-not-member-of-bold',
  [FILTER_OPS.CONTAINS]: 'i-ph-superset-of-bold',
  [FILTER_OPS.DOES_NOT_CONTAIN]: 'i-ph-not-superset-of-bold',
  [FILTER_OPS.IS_GREATER_THAN]: 'i-ph-greater-than-bold',
  [FILTER_OPS.IS_LESS_THAN]: 'i-ph-less-than-bold',
  [FILTER_OPS.DAYS_BEFORE]: 'i-ph-calendar-minus-bold',
  [FILTER_OPS.STARTS_WITH]: 'i-ph-caret-line-right-bold',
};

/**
 * Hook to access filter operators
 * @returns {Object} Object containing filter operators and helper functions
 */
export function useOperators() {
  const { t } = useI18n();

  /**
   * @type {import('vue').ComputedRef<Object.<string, {value: string, label: string, icon: string, hasInput: boolean}>>}
   */
  const operators = computed(() => {
    return Object.values(FILTER_OPS).reduce((acc, value) => {
      acc[value] = {
        value,
        label: t(`FILTER.OPERATOR_LABELS.${value}`),
        hasInput: !NO_INPUT_OPTS.includes(value),
        icon: h('span', {
          class: `${filterOperatorIcon[value]} !text-n-blue-text`,
        }),
      };
      return acc;
    }, {});
  });

  /**
   * @type {import('vue').ComputedRef<Array<{value: string, label: string, icon: string}>>}
   */
  const equalityOperators = computed(() => [
    operators.value[FILTER_OPS.EQUAL_TO],
    operators.value[FILTER_OPS.NOT_EQUAL_TO],
  ]);

  /**
   * @type {import('vue').ComputedRef<Array<{value: string, label: string, icon: string}>>}
   */
  const presenceOperators = computed(() => [
    operators.value[FILTER_OPS.EQUAL_TO],
    operators.value[FILTER_OPS.NOT_EQUAL_TO],
    operators.value[FILTER_OPS.IS_PRESENT],
    operators.value[FILTER_OPS.IS_NOT_PRESENT],
  ]);

  /**
   * @type {import('vue').ComputedRef<Array<{value: string, label: string, icon: string}>>}
   */
  const containmentOperators = computed(() => [
    operators.value[FILTER_OPS.EQUAL_TO],
    operators.value[FILTER_OPS.NOT_EQUAL_TO],
    operators.value[FILTER_OPS.CONTAINS],
    operators.value[FILTER_OPS.DOES_NOT_CONTAIN],
  ]);

  /**
   * @type {import('vue').ComputedRef<Array<{value: string, label: string, icon: string}>>}
   */
  const comparisonOperators = computed(() => [
    operators.value[FILTER_OPS.EQUAL_TO],
    operators.value[FILTER_OPS.NOT_EQUAL_TO],
    operators.value[FILTER_OPS.IS_PRESENT],
    operators.value[FILTER_OPS.IS_NOT_PRESENT],
    operators.value[FILTER_OPS.IS_GREATER_THAN],
    operators.value[FILTER_OPS.IS_LESS_THAN],
  ]);

  /**
   * @type {import('vue').ComputedRef<Array<{value: string, label: string, icon: string}>>}
   */
  const dateOperators = computed(() => [
    operators.value[FILTER_OPS.IS_GREATER_THAN],
    operators.value[FILTER_OPS.IS_LESS_THAN],
    operators.value[FILTER_OPS.DAYS_BEFORE],
  ]);

  /**
   * Get operator types based on key
   * @param {string} key - Type of operator to get
   * @returns {Array<{value: string, label: string, icon: string}>}
   */
  const getOperatorTypes = key => {
    switch (key) {
      case 'list':
        return equalityOperators.value;
      case 'text':
        return containmentOperators.value;
      case 'number':
        return equalityOperators.value;
      case 'link':
        return equalityOperators.value;
      case 'date':
        return comparisonOperators.value;
      case 'checkbox':
        return equalityOperators.value;
      default:
        return equalityOperators.value;
    }
  };

  return {
    operators,
    equalityOperators,
    presenceOperators,
    containmentOperators,
    comparisonOperators,
    dateOperators,
    getOperatorTypes,
  };
}
