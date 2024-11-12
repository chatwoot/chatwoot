<script setup>
import { computed, defineModel, h } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'next/button/Button.vue';
import FilterSelect from './FilterSelect.vue';
import MultiSelect from './inputs/MultiSelect.vue';
import SearchSelect from './inputs/SearchSelect.vue';
import PlainText from './inputs/PlainText.vue';
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
      <SearchSelect
        v-else-if="currentFilter.input_type === 'searchSelect'"
        v-model="values"
        :options="currentFilter.options"
      />
      <PlainText
        v-else-if="currentFilter.input_type === 'plainText'"
        v-model="values"
      />
    </template>
    <Button sm solid slate icon="i-lucide-trash" @click="emit('remove')" />
  </div>
</template>
