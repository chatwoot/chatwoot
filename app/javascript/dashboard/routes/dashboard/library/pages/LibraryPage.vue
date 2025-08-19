<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import { useLibraryResources } from '../composables/useLibraryResources';
import LibraryListLayout from '../components/LibraryListLayout.vue';
import LibraryResourcesList from '../components/LibraryResourcesList.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const { t } = useI18n();

const {
  resources,
  searchQuery,
  currentPage,
  totalItems,
  isLoading,
  searchResources,
  updateCurrentPage,
} = useLibraryResources();

const headerTitle = computed(() => {
  if (searchQuery.value) {
    return t('LIBRARY.HEADER.SEARCH_TITLE');
  }
  return t('LIBRARY.HEADER.TITLE');
});

const hasResources = computed(() => resources.value.length > 0);

const showEmptyState = computed(() => {
  return !hasResources.value && !searchQuery.value && !isLoading.value;
});

const showEmptySearch = computed(() => {
  return !hasResources.value && searchQuery.value && !isLoading.value;
});

const handleViewResource = () => {};

const handleEditResource = () => {};
</script>

<template>
  <div
    class="flex flex-col justify-between flex-1 h-full m-0 overflow-auto bg-n-background"
  >
    <LibraryListLayout
      :search-value="searchQuery"
      :header-title="headerTitle"
      :current-page="currentPage"
      :total-items="totalItems"
      :show-pagination-footer="!isLoading && hasResources"
      :is-loading="isLoading"
      @update:current-page="updateCurrentPage"
      @search="searchResources"
    >
      <div
        v-if="isLoading"
        class="flex items-center justify-center py-10 text-n-slate-11"
      >
        <Spinner />
      </div>

      <template v-else>
        <!-- Empty state when no resources and no search -->
        <div
          v-if="showEmptyState"
          class="flex flex-col items-center justify-center py-20 text-center"
        >
          <div class="mb-6">
            <span class="i-lucide-library-big text-6xl text-n-slate-8" />
          </div>
          <h2 class="text-xl font-semibold text-n-base mb-2">
            {{ t('LIBRARY.EMPTY_STATE.TITLE') }}
          </h2>
          <p class="text-n-slate-11 max-w-md">
            {{ t('LIBRARY.EMPTY_STATE.DESCRIPTION') }}
          </p>
        </div>

        <!-- Empty search results -->
        <div
          v-else-if="showEmptySearch"
          class="flex flex-col items-center justify-center py-20 text-center"
        >
          <div class="mb-6">
            <span class="i-lucide-search-x text-6xl text-n-slate-8" />
          </div>
          <h2 class="text-xl font-semibold text-n-base mb-2">
            {{ t('LIBRARY.EMPTY_SEARCH.TITLE') }}
          </h2>
          <p class="text-n-slate-11 max-w-md">
            {{ t('LIBRARY.EMPTY_SEARCH.DESCRIPTION') }}
          </p>
        </div>

        <!-- Resources list -->
        <LibraryResourcesList
          v-else
          :resources="resources"
          @view-resource="handleViewResource"
          @edit-resource="handleEditResource"
        />
      </template>
    </LibraryListLayout>
  </div>
</template>
