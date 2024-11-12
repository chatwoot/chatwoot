<script setup>
import { computed, defineModel, h } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'next/button/Button.vue';
import FilterSelect from './FilterSelect.vue';
import MultiSelect from './inputs/MultiSelect.vue';
import SingleSelect from './inputs/SingleSelect.vue';

import { useConversationFilterContext } from './provider.js';

defineProps({
  isFirst: { type: Boolean, default: false },
  // attributeModel: { type: String, required: true },
  // customAttributeType: { type: String, default: '' },
});

const emit = defineEmits(['remove']);
const { t } = useI18n();
const { filterTypes } = useConversationFilterContext();

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
  required: true,
  validator: value => ['and', 'or'].includes(value),
});

const currentFilter = computed(() => {
  return filterTypes.value.find(filterObj => {
    return filterObj.attribute_key === attributeKey.value;
  });
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

const currentOperator = computed(() => {
  const operatorFromOptions = currentFilter.value.filter_operators.find(
    operator => {
      return operator.value === filterOperator.value;
    }
  );

  if (!operatorFromOptions) return currentFilter.value.filter_operators[0];
  return operatorFromOptions;
});
</script>

<template>
  <div class="flex items-center gap-2 rounded-md">
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
        v-if="currentFilter.input_type === 'multiSelect'"
        v-model="values"
        :options="currentFilter.options"
      />
      <SingleSelect
        v-else-if="currentFilter.input_type === 'searchSelect'"
        v-model="values"
        :options="currentFilter.options"
      />
      <SingleSelect
        v-else-if="currentFilter.input_type === 'booleanSelect'"
        v-model="values"
        disable-search
        :options="booleanOptions"
      />
      <input
        v-else
        v-model="values"
        :type="currentFilter.input_type === 'date' ? 'date' : 'text'"
        class="py-1.5 px-3 text-n-slate-12 bg-n-alpha-1 text-sm rounded-lg reset-base"
        :placeholder="t('FILTER.INPUT_PLACEHOLDER')"
      />
    </template>
    <Button sm solid slate icon="i-lucide-trash" @click="emit('remove')" />
  </div>
</template>
