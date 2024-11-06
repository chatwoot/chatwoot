<script setup>
import Button from 'next/button/Button.vue';
import ConditionRow from './ConditionRow.vue';
import { defineModel } from 'vue';

const filters = defineModel({
  type: Array,
  default: [],
});

const removeFilter = index => {
  filters.value.splice(index, 1);
};

const addFilter = () => {
  filters.value.push({
    attributeKey: '',
    filterOperator: 'equalTo',
    values: '',
    queryOperator: 'AND',
    attributeModel: 'standard',
    customAttribute_type: '',
  });
};
</script>

<template>
  <div class="bg-n-alpha-3 border border-n-weak p-6 rounded-xl">
    <div class="mt-1 mb-3 font-medium text-base tracking-tight leading-6">
      {{ 'Filters' }}
    </div>
    <div class="grid gap-4">
      <ConditionRow
        v-for="(filter, index) in filters"
        :key="filter.id"
        v-model:attribute-key="filter.attributeKey"
        v-model:filter-operator="filter.filterOperator"
        v-model:query-operator="filter.queryOperator"
        v-model:values="filter.values"
        :is-first="index === 0"
        @remove="removeFilter(index)"
      />
      <Button sm slate faded @click="addFilter"> Add new filter </Button>
    </div>

    <div class="flex gap-2 justify-between mt-6">
      <Button sm ghost blue> Cancel </Button>
      <div class="flex gap-2">
        <Button sm faded slate> Clear all </Button>
        <Button sm solid blue> Apply filter </Button>
      </div>
    </div>
  </div>
</template>
