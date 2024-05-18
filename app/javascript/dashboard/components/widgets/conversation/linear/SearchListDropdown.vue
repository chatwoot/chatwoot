<script setup>
import { ref, computed } from 'vue';
import { picoSearch } from '@scmmishra/pico-search';
import SearchIssueItem from './SearchIssueItem.vue';
import SearchBar from './SearchBar.vue';
import SearchEmptyState from './SearchEmptyState.vue';

const props = defineProps({
  items: {
    type: Array,
    default: () => [],
  },
  selectedId: {
    type: String,
    default: null,
  },
});
const emits = defineEmits(['on-search']);

const searchTerm = ref('');

const onSearch = value => {
  searchTerm.value = value;
  emits('on-search', value);
};

const filteredItems = computed(() => {
  if (!searchTerm.value) return props.items;
  return picoSearch(props.items, searchTerm.value, ['name']);
});

const isDropdownListEmpty = computed(() => {
  return !filteredItems.value.length;
});

const isFilterActive = id => {
  if (!props.selectedId) return false;
  return id === props.selectedId;
};
</script>
<template>
  <div
    class="absolute z-20 w-full bg-white border shadow dark:bg-slate-800 rounded-xl border-slate-50 dark:border-slate-700/50 max-h-[400px]"
    @click.stop
  >
    <slot name="search">
      <search-bar
        :input-value="searchTerm"
        @input="onSearch"
        @click="$emit('removeFilter')"
      />
    </slot>
    <slot name="listItem">
      <search-empty-state
        v-if="isDropdownListEmpty"
        :message="$t('REPORT.FILTER_ACTIONS.EMPTY_LIST')"
      />
      <search-issue-item
        v-for="item in filteredItems"
        :key="item.id"
        :is-active="isFilterActive(item.id)"
        :button-text="item.name"
        @click="$emit('click', item)"
      />
    </slot>
  </div>
</template>
