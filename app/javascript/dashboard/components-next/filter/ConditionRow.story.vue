<script setup>
import { ref } from 'vue';
import ConditionRow from './ConditionRow.vue';

const DEFAULT_FILTER = {
  attributeKey: 'status',
  filterOperator: 'equal_to',
  values: '',
  queryOperator: 'and',
};

const filters = ref([DEFAULT_FILTER]);

const filterTypes = [];
const removeFilter = index => {
  filters.value.splice(index, 1);
};
</script>

<template>
  <Story
    title="Filters/ConditionRow"
    :layout="{ type: 'grid', width: '600px' }"
  >
    <div class="min-h-[400px]">
      <template v-for="(filter, index) in filters" :key="filter.id">
        <ConditionRow
          v-if="index === 0"
          :key="`filter-${filter.attributeKey}-0`"
          v-model:attribute-key="filter.attributeKey"
          v-model:filter-operator="filter.filterOperator"
          v-model:values="filter.values"
          is-first
          @remove="removeFilter(index)"
        />
        <ConditionRow
          v-else
          :key="`filter-${filter.attributeKey}-${index}`"
          v-model:attribute-key="filter.attributeKey"
          v-model:filter-operator="filter.filterOperator"
          v-model:query-operator="filters[index - 1].queryOperator"
          v-model:values="filter.values"
          @remove="removeFilter(index)"
        />
      </template>
    </div>
  </Story>
</template>
