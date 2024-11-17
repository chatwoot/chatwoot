<script setup>
import { computed, defineModel, h, watch, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'next/button/Button.vue';
import FilterSelect from './FilterSelect.vue';
import MultiSelect from './inputs/MultiSelect.vue';
import SingleSelect from './inputs/SingleSelect.vue';

import { useConversationFilterContext } from './provider.js';
import { validateSingleFilter } from 'dashboard/helper/validations.js';

defineProps({
  isFirst: { type: Boolean, default: false },
});

const emit = defineEmits(['remove']);
const { t } = useI18n();
const { filterTypes } = useConversationFilterContext();
const showErrors = ref(false);

const attributeKey = defineModel('attributeKey', {
  type: String,
  required: true,
});

const values = defineModel('values', {
  type: [String, Number, Array],
  required: true,
});

const filterOperator = defineModel('filterOperator', {
  type: String,
  required: true,
});

const queryOperator = defineModel('queryOperator', {
  type: String,
  required: false,
  default: 'and',
  validator: value => ['and', 'or'].includes(value),
});

const currentFilter = computed(() => {
  return filterTypes.value.find(filterObj => {
    return filterObj.attribute_key === attributeKey.value;
  });
});

const currentOperator = computed(() => {
  const operatorFromOptions = currentFilter.value.filter_operators.find(
    operator => {
      return operator.value === filterOperator.value;
    }
  );

  if (!operatorFromOptions) return currentFilter.value.filter_operators[0];
  return operatorFromOptions;
});

const inputType = computed(() => {
  return currentOperator.value.inputOverride ?? currentFilter.value.input_type;
});

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
  return validateSingleFilter({
    attribute_key: attributeKey.value,
    filter_operator: filterOperator.value,
    values: values.value,
  });
});

watch(attributeKey, () => {
  filterOperator.value = currentFilter.value.filter_operators[0].value;
  values.value = '';
});

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
        v-if="!isFirst"
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
      />
      <FilterSelect
        v-model="filterOperator"
        variant="ghost"
        :options="currentFilter.filter_operators"
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
      <Button sm solid slate icon="i-lucide-trash" @click="emit('remove')" />
    </div>
    <span v-if="showErrors && validationError" class="text-sm text-n-ruby-11">
      {{ t(`FILTER.ERRORS.${validationError}`) }}
    </span>
  </li>
</template>
