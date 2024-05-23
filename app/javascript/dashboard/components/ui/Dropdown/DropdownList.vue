<script setup>
import { ref, computed } from 'vue';
import { picoSearch } from '@scmmishra/pico-search';
import ListItemButton from './DropdownListItemButton.vue';
import DropdownSearch from './DropdownSearch.vue';
import DropdownEmptyState from './DropdownEmptyState.vue';

const props = defineProps({
  listItems: {
    type: Array,
    default: () => [],
  },
  enableSearch: {
    type: Boolean,
    default: false,
  },
  inputPlaceholder: {
    type: String,
    default: '',
  },
  activeFilterId: {
    type: [String, Number],
    default: null,
  },
  showClearFilter: {
    type: Boolean,
    default: false,
  },
});

const emits = defineEmits(['on-search']);

const searchTerm = ref('');

const onSearch = value => {
  searchTerm.value = value;
  emits('on-search', value);
};

const filteredListItems = computed(() => {
  if (!searchTerm.value) return props.listItems;
  return picoSearch(props.listItems, searchTerm.value, ['name']);
});

const isDropdownListEmpty = computed(() => {
  return !filteredListItems.value.length;
});

const isFilterActive = id => {
  if (!props.activeFilterId) return false;
  return id === props.activeFilterId;
};
</script>
<template>
  <div
    class="absolute z-20 w-40 bg-white border shadow dark:bg-slate-800 rounded-xl border-slate-50 dark:border-slate-700/50 max-h-[400px]"
    @click.stop
  >
    <slot name="search">
      <dropdown-search
        v-if="enableSearch"
        :input-value="searchTerm"
        :input-placeholder="inputPlaceholder"
        :show-clear-filter="showClearFilter"
        @input="onSearch"
        @click="$emit('removeFilter')"
      />
    </slot>
    <slot name="listItem">
      <dropdown-empty-state
        v-if="isDropdownListEmpty"
        :message="$t('REPORT.FILTER_ACTIONS.EMPTY_LIST')"
      />
      <list-item-button
        v-for="item in filteredListItems"
        :key="item.id"
        :is-active="isFilterActive(item.id)"
        :button-text="item.name"
        @click="$emit('click', item)"
      />
    </slot>
  </div>
</template>
