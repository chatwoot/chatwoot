<script setup>
import { ref, watch, useTemplateRef } from 'vue';
import { useConfig } from 'dashboard/composables/useConfig';

import SearchInput from './SearchInput.vue';
import SearchFilters from './SearchFilters.vue';

const props = defineProps({
  initialQuery: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['search', 'filterChange']);

const { isEnterprise } = useConfig();

const searchInputRef = useTemplateRef('searchInputRef');

const searchQuery = ref(props.initialQuery);

const onSearch = query => {
  if (query && query.trim() && searchInputRef.value) {
    searchInputRef.value.addToRecentSearches(query.trim());
  }
  emit('search', query);
};

const onSelectRecentSearch = query => {
  searchQuery.value = query;
  onSearch(query);
};

const onFilterChange = filters => {
  emit('filterChange', filters);
};

watch(
  () => props.initialQuery,
  newValue => {
    if (searchQuery.value !== newValue) {
      searchQuery.value = newValue;
    }
  },
  { immediate: true }
);
</script>

<template>
  <div class="flex flex-col gap-2">
    <SearchInput
      ref="searchInputRef"
      v-model="searchQuery"
      @search="onSearch"
      @select-recent-search="onSelectRecentSearch"
    >
      <SearchFilters v-if="isEnterprise" @update-filters="onFilterChange" />
    </SearchInput>
  </div>
</template>
