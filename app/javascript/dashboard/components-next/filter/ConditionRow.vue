<script setup>
import { computed, defineModel, h, watch, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'next/button/Button.vue';
import FilterSelect from './inputs/FilterSelect.vue';
import MultiSelect from './inputs/MultiSelect.vue';
import SingleSelect from './inputs/SingleSelect.vue';

import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { validateSingleFilter } from 'dashboard/helper/validations.js';

// filterTypes: import('vue').ComputedRef<FilterType[]>
const { filterTypes } = defineProps({
  showQueryOperator: { type: Boolean, default: false },
  filterTypes: { type: Array, required: true },
});

const emit = defineEmits(['remove']);
const { t } = useI18n();
const showErrors = ref(false);

const attributeKey = defineModel('attributeKey', {
  type: String,
  required: true,
});

const values = defineModel('values', {
  type: [String, Number, Array, Object],
  required: true,
});

const filterOperator = defineModel('filterOperator', {
  type: String,
  required: true,
});

const queryOperator = defineModel('queryOperator', {
  type: String,
  required: false,
  default: undefined,
  validator: value => ['and', 'or'].includes(value),
});

const getFilterFromFilterTypes = key =>
  filterTypes.find(filterObj => filterObj.attributeKey === key);

const currentFilter = computed(() =>
  getFilterFromFilterTypes(attributeKey.value)
);

const getOperator = (filter, selectedOperator) => {
  const operatorFromOptions = filter.filterOperators.find(
    operator => operator.value === selectedOperator
  );

  if (!operatorFromOptions) {
    return filter.filterOperators[0];
  }

  return operatorFromOptions;
};

const currentOperator = computed(() =>
  getOperator(currentFilter.value, filterOperator.value)
);

const getInputType = (operator, filter) =>
  operator.inputOverride ?? filter.inputType;

const inputType = computed(() =>
  getInputType(currentOperator.value, currentFilter.value)
);

const queryOperatorOptions = computed(() => {
  return [
    {
      label: t(`FILTER.QUERY_DROPDOWN_LABELS.AND`),
      value: 'and',
      icon: h('span', { class: 'i-lucide-ampersands !text-n-blue-text' }),
    },
    {
      label: t(`FILTER.QUERY_DROPDOWN_LABELS.OR`),
      value: 'or',
      icon: h('span', { class: 'i-woot-logic-or !text-n-blue-text' }),
    },
  ];
});

const booleanOptions = computed(() => [
  { id: true, name: t('FILTER.ATTRIBUTE_LABELS.TRUE') },
  { id: false, name: t('FILTER.ATTRIBUTE_LABELS.FALSE') },
]);

const validationError = computed(() => {
  // TOOD: Migrate validateSingleFilter to use camelcase and then remove useSnakeCase here too
  return validateSingleFilter(
    useSnakeCase({
      attributeKey: attributeKey.value,
      filterOperator: filterOperator.value,
      values: values.value,
    })
  );
});

const resetModelOnAttributeKeyChange = newAttributeKey => {
  /**
   * Resets the filter values and operator when the attribute key changes. This ensures that
   * the values and operator remain compatible with the new attribute type. For example,
   * switching from a text field to a multi-select should reset the value from '' (empty string)
   * to an empty array.
   */
  const filter = getFilterFromFilterTypes(newAttributeKey);
  const newOperator = getOperator(filter, filterOperator.value);
  const newInputType = getInputType(newOperator, filter);
  if (newInputType === 'multiSelect') {
    values.value = [];
  } else if (['searchSelect', 'booleanSelect'].includes(newInputType)) {
    values.value = {};
  } else {
    values.value = '';
  }
  filterOperator.value = newOperator.value;
};

watch([attributeKey, values, filterOperator], () => {
  showErrors.value = false;
});

const validate = () => {
  showErrors.value = true;
  return !validationError.value;
};

defineExpose({ validate });
</script>

<template>
  <li class="list-none">
    <div
      class="flex items-center gap-2 rounded-md"
      :class="{
        'animate-wiggle': showErrors && validationError,
      }"
    >
      <FilterSelect
        v-if="showQueryOperator"
        v-model="queryOperator"
        variant="faded"
        hide-icon
        class="text-sm"
        :options="queryOperatorOptions"
      />
      <FilterSelect
        v-model="attributeKey"
        variant="faded"
        :options="filterTypes"
        @update:model-value="resetModelOnAttributeKeyChange"
      />
      <FilterSelect
        v-model="filterOperator"
        variant="ghost"
        :options="currentFilter.filterOperators"
      />
      <template v-if="currentOperator.hasInput">
        <MultiSelect
          v-if="inputType === 'multiSelect'"
          v-model="values"
          :options="currentFilter.options"
        />
        <SingleSelect
          v-else-if="inputType === 'searchSelect'"
          v-model="values"
          :options="currentFilter.options"
        />
        <SingleSelect
          v-else-if="inputType === 'booleanSelect'"
          v-model="values"
          disable-search
          :options="booleanOptions"
        />
        <input
          v-else
          v-model="values"
          :type="inputType === 'date' ? 'date' : 'text'"
          class="py-1.5 px-3 text-n-slate-12 bg-n-alpha-1 text-sm rounded-lg reset-base"
          :placeholder="t('FILTER.INPUT_PLACEHOLDER')"
        />
      </template>
      <Button
        sm
        solid
        slate
        icon="i-lucide-trash"
        @click.stop="emit('remove')"
      />
    </div>
    <span v-if="showErrors && validationError" class="text-sm text-n-ruby-11">
      {{ t(`FILTER.ERRORS.${validationError}`) }}
    </span>
  </li>
</template>
