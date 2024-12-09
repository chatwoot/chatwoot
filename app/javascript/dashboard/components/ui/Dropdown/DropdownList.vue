<script setup>
import { ref, computed } from 'vue';
import { debounce } from '@chatwoot/utils';
import { picoSearch } from '@scmmishra/pico-search';
import ListItemButton from './DropdownListItemButton.vue';
import DropdownSearch from './DropdownSearch.vue';
import DropdownEmptyState from './DropdownEmptyState.vue';
import DropdownLoadingState from './DropdownLoadingState.vue';

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
  isLoading: {
    type: Boolean,
    default: false,
  },
  loadingPlaceholder: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['onSearch', 'select', 'removeFilter']);

const searchTerm = ref('');

const debouncedEmit = debounce(value => {
  emit('onSearch', value);
}, 300);

const onSearch = value => {
  searchTerm.value = value;
  debouncedEmit(value);
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

const shouldShowLoadingState = computed(() => {
  return (
    props.isLoading && isDropdownListEmpty.value && props.loadingPlaceholder
  );
});

const shouldShowEmptyState = computed(() => {
  return !props.isLoading && isDropdownListEmpty.value;
});
</script>

<template>
  <div
    class="absolute z-20 w-40 bg-white border shadow dark:bg-slate-800 rounded-xl border-slate-50 dark:border-slate-700/50 max-h-[400px]"
    @click.stop
  >
    <slot name="search">
      <DropdownSearch
        v-if="enableSearch"
        v-model="searchTerm"
        :input-placeholder="inputPlaceholder"
        :show-clear-filter="showClearFilter"
        @update:model-value="onSearch"
        @remove="$emit('removeFilter')"
      />
    </slot>
    <slot name="listItem">
      <DropdownLoadingState
        v-if="shouldShowLoadingState"
        :message="loadingPlaceholder"
      />
      <DropdownEmptyState
        v-else-if="shouldShowEmptyState"
        :message="$t('REPORT.FILTER_ACTIONS.EMPTY_LIST')"
      />
      <ListItemButton
        v-for="item in filteredListItems"
        :key="item.id"
        :is-active="isFilterActive(item.id)"
        :button-text="item.name"
        :icon="item.icon"
        :icon-color="item.iconColor"
        @click.stop.prevent="emit('select', item)"
      />
    </slot>
  </div>
</template>
