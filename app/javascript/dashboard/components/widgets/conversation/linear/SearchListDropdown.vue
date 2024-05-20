<script setup>
import { ref, computed } from 'vue';
import { picoSearch } from '@scmmishra/pico-search';
import SearchIssueItem from './SearchIssueItem.vue';
import SearchBar from './SearchBar.vue';

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

const isListEmpty = computed(() => {
  return !filteredItems.value.length;
});
</script>
<template>
  <div
    class="absolute z-20 w-full bg-white border shadow dark:bg-slate-800 rounded-xl border-slate-50 dark:border-slate-700/50 max-h-[400px]"
    @click.stop
  >
    <search-bar :input-value="searchTerm" @input="onSearch" />

    <div
      v-if="isListEmpty"
      class="flex items-center justify-center h-10 text-sm text-slate-500 dark:text-slate-300"
    >
      {{ $t('INTEGRATION_SETTINGS.LINEAR.LINK.EMPTY_LIST') }}
    </div>
    <search-issue-item
      v-for="item in filteredItems"
      :key="item.id"
      :is-active="item.id === selectedId"
      :button-text="item.name"
      @click="$emit('click', item)"
    />
  </div>
</template>
