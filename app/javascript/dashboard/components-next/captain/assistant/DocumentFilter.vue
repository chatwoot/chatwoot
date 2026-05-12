<script setup>
import { computed, ref } from 'vue';
import { debounce } from '@chatwoot/utils';

import DocumentFiltersBar from 'dashboard/components-next/captain/assistant/DocumentFiltersBar.vue';

const emit = defineEmits(['change']);

const source = ref('all');
const status = ref(null);
const sort = ref('recently_updated');
const query = ref('');

const hasActiveFilters = computed(
  () =>
    source.value !== 'all' ||
    Boolean(status.value) ||
    Boolean(query.value.trim())
);

const buildParams = (page = 1) => {
  const params = { page };
  if (source.value !== 'all') params.source = source.value;
  if (status.value) params.filter = status.value;
  if (sort.value) params.sort = sort.value;
  if (query.value.trim()) params.searchKey = query.value.trim();
  return params;
};

const emitChange = () => emit('change');
const debouncedEmitChange = debounce(emitChange, 300);

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

const handleSearch = value => {
  query.value = value;
  debouncedEmitChange();
};

const reset = () => {
  source.value = 'all';
  status.value = null;
  sort.value = 'recently_updated';
  query.value = '';
};

defineExpose({ buildParams, reset, hasActiveFilters });
</script>

<template>
  <DocumentFiltersBar
    :active-source-filter="source"
    :active-status-filter="status"
    :active-sort="sort"
    :search-query="query"
    @select-source="handleSourceSelect"
    @select-status="handleStatusSelect"
    @select-sort="handleSortSelect"
    @search="handleSearch"
  />
</template>
