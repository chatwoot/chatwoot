import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const FILTER_OPS = {
  EQUAL_TO: 'equalTo',
  NOT_EQUAL_TO: 'notEqualTo',
  IS_PRESENT: 'isPresent',
  IS_NOT_PRESENT: 'isNotPresent',
  CONTAINS: 'contains',
  DOES_NOT_CONTAIN: 'doesNotContain',
  IS_GREATER_THAN: 'isGreaterThan',
  IS_LESS_THAN: 'isLessThan',
  DAYS_BEFORE: 'daysBefore',
  STARTS_WITH: 'startsWith',
};

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

export function useOperators() {
  const { t } = useI18n();

  const operators = computed(() => {
    return Object.values(FILTER_OPS).reduce((acc, value) => {
      acc[value] = {
        value,
        label: t(`FILTER.OPERATOR_LABELS.${value}`),
        icon: filterOperatorIcon[value],
      };
      return acc;
    }, {});
  });

  // Legacy: Operator types 1
  const equalityOperators = computed(() => [
    operators.value[FILTER_OPS.EQUAL_TO],
    operators.value[FILTER_OPS.NOT_EQUAL_TO],
  ]);

  // Legacy: Operator types 2
  const presenceOperators = computed(() => [
    operators.value[FILTER_OPS.EQUAL_TO],
    operators.value[FILTER_OPS.NOT_EQUAL_TO],
    operators.value[FILTER_OPS.IS_PRESENT],
    operators.value[FILTER_OPS.IS_NOT_PRESENT],
  ]);

  // Legacy: Operator types 3
  const containmentOperators = computed(() => [
    operators.value[FILTER_OPS.EQUAL_TO],
    operators.value[FILTER_OPS.NOT_EQUAL_TO],
    operators.value[FILTER_OPS.CONTAINS],
    operators.value[FILTER_OPS.DOES_NOT_CONTAIN],
  ]);

  // Legacy: Operator types 4
  const comparisonOperators = computed(() => [
    operators.value[FILTER_OPS.EQUAL_TO],
    operators.value[FILTER_OPS.NOT_EQUAL_TO],
    operators.value[FILTER_OPS.IS_PRESENT],
    operators.value[FILTER_OPS.IS_NOT_PRESENT],
    operators.value[FILTER_OPS.IS_GREATER_THAN],
    operators.value[FILTER_OPS.IS_LESS_THAN],
  ]);

  // Legacy: Operator types 5
  const dateOperators = computed(() => [
    operators.value[FILTER_OPS.IS_GREATER_THAN],
    operators.value[FILTER_OPS.IS_LESS_THAN],
    operators.value[FILTER_OPS.DAYS_BEFORE],
  ]);

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
