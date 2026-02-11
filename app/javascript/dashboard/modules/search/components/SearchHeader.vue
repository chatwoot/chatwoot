<script setup>
import { ref, watch, useTemplateRef, defineModel } from 'vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import { ROLES } from 'dashboard/constants/permissions';

import SearchInput from './SearchInput.vue';
import SearchFilters from './SearchFilters.vue';
import Policy from 'dashboard/components/policy.vue';

const props = defineProps({
  initialQuery: { type: String, default: '' },
});

const emit = defineEmits(['search', 'filterChange']);

const filters = defineModel('filters', { type: Object, default: () => ({}) });

const searchInputRef = useTemplateRef('searchInputRef');
const searchQuery = ref(props.initialQuery);

const onSearch = query => {
  if (query?.trim() && searchInputRef.value) {
    searchInputRef.value.addToRecentSearches(query.trim());
  }
  emit('search', query);
};

const onSelectRecentSearch = query => {
  searchQuery.value = query;
  onSearch(query);
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
      <Policy
        :permissions="ROLES"
        :installation-types="[
          INSTALLATION_TYPES.ENTERPRISE,
          INSTALLATION_TYPES.CLOUD,
        ]"
        :feature-flag="FEATURE_FLAGS.ADVANCED_SEARCH"
        class="w-full"
      >
        <SearchFilters
          v-model="filters"
          @update-filters="$emit('filterChange', $event)"
        />
      </Policy>
    </SearchInput>
  </div>
</template>
