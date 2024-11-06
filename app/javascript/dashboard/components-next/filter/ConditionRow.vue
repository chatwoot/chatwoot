<script setup>
import { computed, defineModel, h } from 'vue';
import Button from 'next/button/Button.vue';
import FilterSelect from './FilterSelect.vue';

const props = defineProps({
  attributeKey: { type: String, required: true },
  values: { type: [String, Number, Array], required: true },
  isFirst: { type: Boolean, default: false },
  // attributeModel: { type: String, required: true },
  // customAttributeType: { type: String, default: '' },
});

const emit = defineEmits(['remove']);

const filterOperator = defineModel('filterOperator', {
  type: String,
  required: true,
});

const queryOperator = defineModel('queryOperator', {
  type: String,
  required: true,
  validator: value => ['and', 'or'].includes(value),
});

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
};

const filterOperatorLabel = {
  [FILTER_OPS.EQUAL_TO]: 'equal to',
  [FILTER_OPS.NOT_EQUAL_TO]: 'not equal to',
  [FILTER_OPS.IS_PRESENT]: 'is present',
  [FILTER_OPS.IS_NOT_PRESENT]: 'is not present',
  [FILTER_OPS.CONTAINS]: 'contains',
  [FILTER_OPS.DOES_NOT_CONTAIN]: 'does not contain',
  [FILTER_OPS.IS_GREATER_THAN]: 'is greater than',
  [FILTER_OPS.IS_LESS_THAN]: 'is less than',
  [FILTER_OPS.DAYS_BEFORE]: 'days before',
};

const filterDropdownOptions = Object.keys(FILTER_OPS).map(key => ({
  label: filterOperatorLabel[FILTER_OPS[key]],
  value: FILTER_OPS[key],
  icon: h('span', { class: 'flex items-center' }, [
    h('i', {
      class: `text-n-blue-text ${filterOperatorIcon[FILTER_OPS[key]]}`,
    }),
  ]),
}));

const toggleQueryOperator = () => {
  queryOperator.value = queryOperator.value === 'and' ? 'or' : 'and';
};

const valueToShow = computed(() => {
  if (Array.isArray(props.values)) {
    return props.values.map(v => v.name).join(', ');
  }

  return props.values;
});
</script>

<template>
  <div class="flex items-center gap-2 rounded-md">
    <Button
      sm
      faded
      slate
      class="text-xs font-mono tracking-wider min-w-12"
      :class="{ 'invisible pointer-events-none': isFirst }"
      :label="queryOperator === 'and' ? 'AND' : 'OR'"
      @click="toggleQueryOperator"
    />
    <Button
      sm
      faded
      slate
      trailing-icon
      icon="i-lucide-chevron-down"
      class="capitalize"
    >
      {{ attributeKey }}
    </Button>
    <FilterSelect
      v-model="filterOperator"
      variant="ghost"
      :options="filterDropdownOptions"
    />
    <Button v-if="valueToShow" sm faded slate>
      {{ valueToShow }}
    </Button>
    <Button sm solid slate icon="i-lucide-x" @click="emit('remove')" />
  </div>
</template>
