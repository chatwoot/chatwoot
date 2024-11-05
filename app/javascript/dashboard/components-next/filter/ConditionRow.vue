<script setup>
import { computed } from 'vue';
import Button from 'next/button/Button.vue';

const { values } = defineProps({
  attributeKey: { type: String, required: true },
  // attributeModel: { type: String, required: true },
  filterOperator: { type: String, required: true },
  values: { type: [String, Number, Array], required: true },
  // customAttributeType: { type: String, default: '' },
  queryOperator: {
    type: String,
    required: true,
    validator: value => ['and', 'or'].includes(value),
  },
});

const queryOperatorIcon = {
  and: 'i-woot-match-and',
  or: 'i-woot-match-or',
};

const filterOperatorIcon = {
  equalTo: '=',
  notEqualTo: '≠',
  isPresent: '∈',
  isNotPresent: '∉',
  contains: '⊇',
  doesNotContain: '⊅',
  isGreaterThan: '>',
  isLessThan: '<',
  daysBefore: '-n days',
};

const filterOperatorLabel = {
  equalTo: 'equal to',
  notEqualTo: 'not equal to',
  isPresent: 'is present',
  isNotPresent: 'is not present',
  contains: 'contains',
  doesNotContain: 'does not contain',
  isGreaterThan: 'is greater than',
  isLessThan: 'is less than',
  daysBefore: 'days before',
};

const valueToShow = computed(() => {
  if (Array.isArray(values)) {
    return values.map(v => v.name).join(', ');
  }

  return values;
});
</script>

<template>
  <div class="mb-4 rounded-md flex items-center gap-2">
    <Button sm faded slate :icon="queryOperatorIcon[queryOperator]" />
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
    <Button sm ghost slate>
      <div class="leading-5">
        <span class="text-n-blue-text text-lg leading-none">
          {{ filterOperatorIcon[filterOperator] }}
        </span>
        {{ filterOperatorLabel[filterOperator] }}
      </div>
    </Button>
    <Button sm faded slate>
      {{ valueToShow }}
    </Button>
    <Button sm solid slate icon="i-lucide-x" />
  </div>
</template>
