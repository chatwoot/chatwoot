<script setup>
import { ref, watch } from 'vue';
import SearchDateRangeSelector from './SearchDateRangeSelector.vue';
import SearchContactAgentSelector from './SearchContactAgentSelector.vue';
import SearchInboxSelector from './SearchInboxSelector.vue';

const emit = defineEmits(['updateFilters']);

const filters = ref({
  from: null, // Contact id and Agent id
  in: null, // Inbox id
  dateRange: { from: null, to: null },
});

const onDateRangeChange = ({ from, to }) => {
  filters.value.dateRange = { from, to };
  emit('updateFilters', filters.value);
};

// Watch for changes in filters.from and filters.in and emit updates
watch(
  () => [filters.value.from, filters.value.in],
  () => {
    emit('updateFilters', filters.value);
  }
);
</script>

<template>
  <div class="flex items-center gap-2 p-4 w-full">
    <SearchDateRangeSelector
      v-model:from="filters.dateRange.from"
      v-model:to="filters.dateRange.to"
      @change="onDateRangeChange"
    />

    <div class="w-px h-4 bg-n-weak mx-1" />

    <SearchContactAgentSelector
      v-model="filters.from"
      :label="$t('SEARCH.FILTERS.FROM')"
    />

    <SearchInboxSelector
      v-model="filters.in"
      :label="$t('SEARCH.FILTERS.IN')"
    />
  </div>
</template>
