<script setup>
import { ref, computed, onMounted } from 'vue';
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['selectSearch', 'clearAll']);

const MAX_RECENT_SEARCHES = 3;
const recentSearches = ref([]);

const loadRecentSearches = () => {
  const stored = LocalStorage.get(LOCAL_STORAGE_KEYS.RECENT_SEARCHES) || [];
  recentSearches.value = Array.isArray(stored) ? stored : [];
};

const saveRecentSearches = () => {
  LocalStorage.set(LOCAL_STORAGE_KEYS.RECENT_SEARCHES, recentSearches.value);
};

const addRecentSearch = query => {
  if (!query || query.trim().length < 2) return;

  const trimmedQuery = query.trim();

  const existingIndex = recentSearches.value.findIndex(
    search => search.toLowerCase() === trimmedQuery.toLowerCase()
  );

  if (existingIndex !== -1) {
    recentSearches.value.splice(existingIndex, 1);
  }

  recentSearches.value.unshift(trimmedQuery);

  if (recentSearches.value.length > MAX_RECENT_SEARCHES) {
    recentSearches.value = recentSearches.value.slice(0, MAX_RECENT_SEARCHES);
  }

  saveRecentSearches();
};

const clearRecentSearches = () => {
  recentSearches.value = [];
  LocalStorage.remove(LOCAL_STORAGE_KEYS.RECENT_SEARCHES);
};

const hasRecentSearches = computed(() => recentSearches.value?.length > 0);

const onSelectSearch = query => {
  emit('selectSearch', query);
};

const onClearAll = () => {
  clearRecentSearches();
  emit('clearAll');
};

defineExpose({
  addRecentSearch,
  loadRecentSearches,
});

onMounted(() => {
  loadRecentSearches();
});
</script>

<template>
  <div v-if="hasRecentSearches" class="px-4 pb-4 w-full pt-2">
    <div class="flex items-center justify-between mb-4">
      <div class="flex items-center gap-2.5">
        <Icon icon="i-lucide-rotate-ccw" class="text-s-muted size-4" />
        <h3 class="text-base font-medium text-s-muted">
          {{ $t('SEARCH.RECENT_SEARCHES') }}
        </h3>
      </div>
      <Button
        type="button"
        xs
        slate
        ghost
        class="!text-s-muted hover:!text-s-primary"
        @mousedown.prevent
        @click="onClearAll"
      >
        {{ $t('SEARCH.CLEAR_ALL') }}
      </Button>
    </div>

    <div class="flex flex-col gap-4 items-start">
      <button
        v-for="(search, index) in recentSearches"
        :key="search"
        type="button"
        class="w-full flex items-center gap-2.5 text-left text-base text-s-primary rounded-lg transition-all duration-150 group p-0"
        @mousedown.prevent
        @click="onSelectSearch(search)"
      >
        <Icon
          icon="i-lucide-search"
          class="text-s-muted group-hover:text-s-muted transition-colors duration-150 size-4"
        />
        <span class="flex-1 truncate">{{ search }}</span>
        <span
          class="text-xs text-s-disabled opacity-0 group-hover:opacity-100 transition-opacity duration-150"
        >
          {{ index === 0 ? $t('SEARCH.MOST_RECENT') : '' }}
        </span>
      </button>
    </div>
  </div>
  <template v-else />
</template>
