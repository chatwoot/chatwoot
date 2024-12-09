<script setup>
import { replaceUnderscoreWithSpace } from './helper/filterHelper.js';

import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  appliedFilters: { type: Array, default: () => [] },
  maxVisibleFilters: { type: Number, default: 2 },
  clearButtonLabel: { type: String, default: '' },
  moreFiltersLabel: { type: String, default: '' },
  showClearButton: { type: Boolean, default: true },
});

const emit = defineEmits(['clearFilters', 'openFilter']);

const shouldCapitalizeFirstLetter = key => {
  const lowercaseKeys = ['email'];
  return !lowercaseKeys.includes(key);
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
  if (Array.isArray(value)) {
    return value.join(', ');
  }
  if (typeof value === 'object' && value.name) {
    return value.name;
  }
  return value;
};
</script>

<template>
  <div class="flex flex-wrap items-center w-full gap-2 mx-auto">
    <template v-for="(filter, index) in appliedFilters" :key="index">
      <div
        v-if="index < maxVisibleFilters"
        class="inline-flex items-center gap-2 h-7"
      >
        <div
          class="flex items-center h-full min-w-0 gap-1 px-2 py-1 text-xs border rounded-lg hover:bg-n-solid-2 max-w-72 border-n-weak hover:cursor-pointer"
          @click="emit('openFilter')"
        >
          <span
            class="lowercase whitespace-nowrap first-letter:capitalize text-n-slate-12"
          >
            {{ replaceUnderscoreWithSpace(filter.attributeKey) }}
          </span>
          <span class="px-1 text-xs text-n-slate-10 whitespace-nowrap">
            {{ formatOperatorLabel(filter.filterOperator) }}
          </span>
          <span
            v-if="filter.values"
            class="lowercase truncate text-n-slate-12"
            :class="{
              'first-letter:capitalize': shouldCapitalizeFirstLetter(
                filter.attributeKey
              ),
            }"
          >
            {{ formatFilterValue(filter.values) }}
          </span>
        </div>
        <template
          v-if="
            index < maxVisibleFilters - 1 && index < appliedFilters.length - 1
          "
        >
          <span
            class="content-center h-full px-1 text-xs font-medium uppercase rounded-lg text-n-slate-10"
          >
            {{ filter.queryOperator }}
          </span>
        </template>
      </div>
    </template>
    <div
      v-if="appliedFilters.length > maxVisibleFilters"
      class="inline-flex items-center content-center px-1 text-xs rounded-lg text-n-slate-10 hover:text-n-slate-11 h-7 hover:cursor-pointer"
      @click="emit('openFilter')"
    >
      {{ moreFiltersLabel }}
    </div>
    <div v-if="showClearButton" class="w-px h-3 rounded-lg bg-n-strong" />
    <Button
      v-if="showClearButton"
      :label="clearButtonLabel"
      size="xs"
      class="!px-1"
      variant="ghost"
      @click="emit('clearFilters')"
    />
  </div>
</template>
