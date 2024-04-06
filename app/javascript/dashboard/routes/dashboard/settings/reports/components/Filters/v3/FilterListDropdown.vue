<script setup>
import { ref, computed } from 'vue';
import FilterListItemButton from './FilterListItemButton.vue';
import FilterDropdownSearch from './FilterDropdownSearch.vue';

const props = defineProps({
  listItems: {
    type: Array,
    default: () => [],
  },
  enableSearch: {
    type: Boolean,
    default: false,
  },
  inputButtonText: {
    type: String,
    default: '',
  },
});

const searchTerm = ref('');

const onSearch = value => {
  searchTerm.value = value;
};

const filteredListItems = computed(() => {
  return props.listItems.filter(item =>
    item.name.toLowerCase().includes(searchTerm.value.toLowerCase())
  );
});
</script>
<template>
  <div
    class="z-20 w-40 bg-white border shadow dark:bg-slate-800 rounded-xl border-slate-50 dark:border-slate-700/50 max-h-72"
  >
    <slot name="search">
      <filter-dropdown-search
        v-if="enableSearch && listItems.length"
        :button-text="inputButtonText"
        :input-value="searchTerm"
        @input="onSearch"
        @click="onSearch('')"
      />
    </slot>
    <slot name="listItem">
      <filter-list-item-button
        v-for="item in filteredListItems"
        :key="item.id"
        :button-text="item.name"
        @click="$emit('click')"
      />
    </slot>
  </div>
</template>
