<script setup>
import { computed, ref } from 'vue';

import DocumentFiltersBar from 'dashboard/components-next/captain/assistant/DocumentFiltersBar.vue';

const emit = defineEmits(['change']);

const source = ref('all');
const status = ref(null);
const sort = ref('recently_updated');

const hasActiveFilters = computed(
  () => source.value !== 'all' || Boolean(status.value)
);

const buildParams = (page = 1) => {
  const params = { page };
  if (source.value !== 'all') params.source = source.value;
  if (status.value) params.filter = status.value;
  if (sort.value) params.sort = sort.value;
  return params;
};

const emitChange = () => emit('change');

const handleSourceSelect = sourceKey => {
  source.value = sourceKey;
  if (sourceKey !== 'web') status.value = null;
  emitChange();
};

const handleStatusSelect = statusKey => {
  status.value = statusKey;
  if (statusKey) source.value = 'web';
  emitChange();
};

const handleSortSelect = sortKey => {
  sort.value = sortKey;
  emitChange();
};

const reset = () => {
  source.value = 'all';
  status.value = null;
  sort.value = 'recently_updated';
};

defineExpose({ buildParams, reset, hasActiveFilters });
</script>

<template>
  <DocumentFiltersBar
    :active-source-filter="source"
    :active-status-filter="status"
    :active-sort="sort"
    @select-source="handleSourceSelect"
    @select-status="handleStatusSelect"
    @select-sort="handleSortSelect"
  />
</template>
