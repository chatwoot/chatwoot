<script setup>
import { ref, useTemplateRef } from 'vue';
import ConditionRow from './ConditionRow.vue';
import Button from 'next/button/Button.vue';
import { filterTypes } from './fixtures/filterTypes.js';

const DEFAULT_FILTER = {
  attributeKey: 'status',
  filterOperator: 'equal_to',
  values: [],
  queryOperator: 'and',
};

const filters = ref([{ ...DEFAULT_FILTER }]);
const conditionsRef = useTemplateRef('conditionsRef');

const removeFilter = index => {
  filters.value.splice(index, 1);
};

const showQueryOperator = true;

const addFilter = () => {
  filters.value.push({ ...DEFAULT_FILTER });
};

const saveFilter = () => {
  console.log(conditionsRef.value.every(condition => condition.validate()));
};
</script>

<template>
  <Story
    title="Components/Filters/ConditionRow"
    :layout="{ type: 'grid', width: '600px' }"
  >
    <div class="min-h-[400px] p-2 space-y-2">
      <template v-for="(filter, index) in filters" :key="`filter-${index}`">
        <ConditionRow
          v-if="index === 0"
          ref="conditionsRef"
          v-model:attribute-key="filter.attributeKey"
          v-model:filter-operator="filter.filterOperator"
          v-model:values="filter.values"
          :show-query-operator="false"
          :filter-types="filterTypes"
          @remove="removeFilter(index)"
        />

        <ConditionRow
          v-else
          ref="conditionsRef"
          v-model:attribute-key="filter.attributeKey"
          v-model:filter-operator="filter.filterOperator"
          v-model:values="filter.values"
          v-model:query-operator="filters[index - 1].queryOperator"
          :show-query-operator
          :filter-types="filterTypes"
          @remove="removeFilter(index)"
        />
      </template>
      <div class="flex gap-3 mt-2">
        <Button sm ghost label="Add Filter" @click="addFilter" />
        <Button sm label="Save Filter" @click="saveFilter" />
      </div>
    </div>
  </Story>
</template>
