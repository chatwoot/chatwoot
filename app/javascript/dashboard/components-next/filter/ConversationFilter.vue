<script setup>
import { defineModel, useTemplateRef } from 'vue';
import Button from 'next/button/Button.vue';
import ConditionRow from './ConditionRow.vue';

const filters = defineModel({
  type: Array,
  default: [],
});

const removeFilter = index => {
  filters.value.splice(index, 1);
};

const addFilter = () => {
  filters.value.push({
    attribute_key: 'status',
    filter_operator: 'equal_to',
    values: '',
    query_operator: 'and',
  });
};

const conditionRefs = useTemplateRef('conditions');

function validateAndSubmit() {
  conditionRefs.value.map(condition => condition.validate()).every(Boolean);
}
</script>

<template>
  <div class="bg-n-alpha-3 border border-n-weak p-6 rounded-xl">
    <div class="mt-1 mb-3 font-medium text-base tracking-tight leading-6">
      {{ 'Filters' }}
    </div>
    <ul class="grid gap-4 list-none">
      <template v-for="(filter, index) in filters" :key="filter.id">
        <ConditionRow
          v-if="index === 0"
          ref="conditions"
          v-model:attribute-key="filter.attribute_key"
          v-model:filter-operator="filter.filter_operator"
          v-model:values="filter.values"
          is-first
          @remove="removeFilter(index)"
        />
        <ConditionRow
          v-else
          ref="conditions"
          v-model:attribute-key="filter.attribute_key"
          v-model:filter-operator="filter.filter_operator"
          v-model:query-operator="filters[index - 1].query_operator"
          v-model:values="filter.values"
          @remove="removeFilter(index)"
        />
      </template>
    </ul>

    <div class="flex gap-2 justify-between mt-6">
      <Button sm ghost blue @click="addFilter">
        {{ $t('FILTER.ADD_NEW_FILTER') }}
      </Button>
      <div class="flex gap-2">
        <Button sm faded slate> Clear all </Button>
        <Button sm solid blue @click="validateAndSubmit"> Apply filter </Button>
      </div>
    </div>
  </div>
</template>
