<script setup>
import { replaceUnderscoreWithSpace } from './helper/filterHelper.js';

import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  appliedFilters: {
    type: Array,
    default: () => [],
  },
  maxVisibleFilters: {
    type: Number,
    default: 2,
  },
  clearButtonLabel: {
    type: String,
    default: '',
  },
  moreFiltersLabel: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['clearFilters']);

const capitalizeFirstLetter = key => {
  const attributeKeys = ['email'];
  return !attributeKeys.includes(key);
};

const formatOperatorLabel = operator => {
  const operators = {
    equal_to: 'is',
    not_equal_to: 'is not',
    contains: 'contains',
    does_not_contain: 'does not contain',
    is_present: 'is present',
    is_not_present: 'is not present',
    is_greater_than: 'is greater than',
    is_less_than: 'is less than',
    days_before: 'days before',
  };
  return operators[operator] || replaceUnderscoreWithSpace(operator);
};

const formatFilterValue = value => {
  if (!value) return '';
  if (typeof value === 'object' && value.name) {
    return value.name;
  }
  return value;
};
</script>

<template>
  <div class="flex flex-wrap items-center w-full gap-2 mx-auto">
    <template
      v-for="(filter, index) in appliedFilters"
      :key="filter.attributeKey"
    >
      <div
        v-if="index < maxVisibleFilters"
        class="inline-flex items-center gap-2 h-7"
      >
        <span
          class="content-center h-full px-2 text-xs lowercase truncate border rounded-lg max-w-52 first-letter:capitalize text-n-slate-12 border-n-weak bg-n-solid-2"
        >
          {{ replaceUnderscoreWithSpace(filter.attributeKey) }}
        </span>
        <span
          class="content-center h-full px-1 text-xs truncate rounded-lg text-n-slate-10"
        >
          {{ formatOperatorLabel(filter.filterOperator) }}
        </span>
        <span
          v-if="filter.values"
          class="content-center h-full px-2 text-xs lowercase truncate border rounded-lg max-w-52 text-n-slate-12 border-n-weak bg-n-solid-2"
          :class="
            capitalizeFirstLetter(filter.attributeKey) &&
            'first-letter:capitalize'
          "
        >
          {{ formatFilterValue(filter.values) }}
        </span>
        <template v-if="index < appliedFilters.length - 1">
          <span
            class="content-center h-full px-1 text-xs uppercase rounded-lg text-n-slate-10"
          >
            {{ filter.queryOperator }}
          </span>
        </template>
      </div>
    </template>
    <div
      v-if="appliedFilters.length > maxVisibleFilters"
      class="inline-flex items-center content-center px-1 text-xs rounded-lg text-n-slate-10 h-7"
    >
      {{ moreFiltersLabel }}
    </div>
    <div class="w-px h-3 rounded-lg bg-n-strong" />
    <Button
      :label="clearButtonLabel"
      size="xs"
      class="!px-1"
      variant="ghost"
      @click="emit('clearFilters')"
    />
  </div>
</template>
