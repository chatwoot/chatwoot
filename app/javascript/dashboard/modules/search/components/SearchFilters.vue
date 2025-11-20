<script setup>
import { defineModel } from 'vue';
import SearchDateRangeSelector from './SearchDateRangeSelector.vue';
import SearchContactAgentSelector from './SearchContactAgentSelector.vue';
import SearchInboxSelector from './SearchInboxSelector.vue';

const emit = defineEmits(['updateFilters']);

const filters = defineModel({
  type: Object,
  default: () => ({
    from: null, // Contact id and Agent id
    in: null, // Inbox id
    dateRange: { type: null, from: null, to: null },
  }),
});

const onFilterChange = () => {
  emit('updateFilters', filters.value);
};
</script>

<template>
  <div class="flex items-center gap-2 p-4 w-full">
    <SearchDateRangeSelector
      v-model="filters.dateRange"
      @change="onFilterChange"
    />

    <div class="w-px h-4 bg-n-weak mx-1" />

    <SearchContactAgentSelector
      v-model="filters.from"
      :label="$t('SEARCH.FILTERS.FROM')"
      @change="onFilterChange"
    />

    <SearchInboxSelector
      v-model="filters.in"
      :label="$t('SEARCH.FILTERS.IN')"
      @change="onFilterChange"
    />
  </div>
</template>
