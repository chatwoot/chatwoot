<script setup>
import { ref, useTemplateRef, onMounted, onUnmounted } from 'vue';
import { debounce } from '@chatwoot/utils';
import RecentSearches from './RecentSearches.vue';

const emit = defineEmits(['search', 'selectRecentSearch']);

const searchQuery = defineModel({
  type: String,
  default: '',
});
const isInputFocused = ref(false);
const showRecentSearches = ref(false);
const searchInput = useTemplateRef('searchInput');
const recentSearchesRef = useTemplateRef('recentSearchesRef');

const handler = e => {
  if (e.key === '/' && document.activeElement.tagName !== 'INPUT') {
    e.preventDefault();
    searchInput.value.focus();
  } else if (e.key === 'Escape' && document.activeElement.tagName === 'INPUT') {
    e.preventDefault();
    searchInput.value.blur();
  }
};

const debouncedEmit = debounce(
  value =>
    emit('search', value.length > 1 || value.match(/^[0-9]+$/) ? value : ''),
  500
);

const onInput = () => {
  debouncedEmit(searchQuery.value);

  if (searchQuery.value.trim()) {
    showRecentSearches.value = false;
  } else if (isInputFocused.value) {
    showRecentSearches.value = true;
  }
};

const onFocus = () => {
  isInputFocused.value = true;
  if (!searchQuery.value.trim()) {
    showRecentSearches.value = true;
  }
};

const onBlur = () => {
  isInputFocused.value = false;
  showRecentSearches.value = false;
};

const onSelectRecentSearch = query => {
  searchQuery.value = query;
  emit('selectRecentSearch', query);
  showRecentSearches.value = false;
  searchInput.value.focus();
};

const addToRecentSearches = query => {
  if (recentSearchesRef.value) {
    recentSearchesRef.value.addRecentSearch(query);
  }
};

defineExpose({
  addToRecentSearches,
});

onMounted(() => {
  searchInput.value.focus();
  document.addEventListener('keydown', handler);
});

onUnmounted(() => {
  document.removeEventListener('keydown', handler);
});
</script>

<template>
  <div
    class="rounded-xl transition-[border-bottom] duration-[0.2s] ease-[ease-in-out] relative flex items-start flex-col border border-solid bg-n-solid-1 divide-y divide-n-strong"
    :class="{
      'border-n-brand': isInputFocused,
      'border-n-strong': !isInputFocused,
    }"
  >
    <div class="flex items-center w-full h-[3.25rem] px-4 gap-2">
      <div class="flex items-center">
        <fluent-icon
          icon="search"
          class="icon"
          aria-hidden="true"
          :class="{
            'text-n-blue-11': isInputFocused,
            'text-n-slate-10': !isInputFocused,
          }"
        />
      </div>
      <input
        ref="searchInput"
        v-model="searchQuery"
        type="search"
        class="reset-base outline-none w-full m-0 bg-transparent border-transparent shadow-none text-n-slate-12 dark:text-n-slate-12 active:border-transparent active:shadow-none hover:border-transparent hover:shadow-none focus:border-transparent focus:shadow-none placeholder:text-n-slate-10 text-base"
        :placeholder="$t('SEARCH.INPUT_PLACEHOLDER')"
        @focus="onFocus"
        @blur="onBlur"
        @input="onInput"
      />
      <span class="text-sm text-n-slate-10 flex-shrink-0">
        {{ $t('SEARCH.PLACEHOLDER_KEYBINDING') }}
      </span>
    </div>

    <slot />

    <div
      class="transition-all duration-200 ease-out grid overflow-hidden w-full !border-t-0"
      :class="
        showRecentSearches
          ? 'grid-rows-[1fr] opacity-100'
          : 'grid-rows-[0fr] opacity-0'
      "
    >
      <div class="overflow-hidden w-full">
        <RecentSearches
          ref="recentSearchesRef"
          @select-search="onSelectRecentSearch"
          @clear-all="showRecentSearches = false"
        />
      </div>
    </div>
  </div>
</template>
