<script setup>
import FilterButton from 'dashboard/components/ui/Dropdown/DropdownButton.vue';
import FilterListDropdown from 'dashboard/components/ui/Dropdown/DropdownList.vue';

const props = defineProps({
  name: {
    type: String,
    required: true,
  },
  id: {
    type: Number,
    required: true,
  },
  type: {
    type: String,
    required: true,
  },
  options: {
    type: Array,
    default: () => [],
  },
  activeFilterType: {
    type: String,
    default: '',
  },
  showMenu: {
    type: Boolean,
    default: false,
  },
  placeholder: {
    type: String,
    default: '',
  },
  enableSearch: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'toggleDropdown',
  'removeFilter',
  'addFilter',
  'closeDropdown',
]);
const toggleDropdown = () => emit('toggleDropdown', props.type);
const removeFilter = () => emit('removeFilter', props.type);
const addFilter = item => emit('addFilter', item);
const closeDropdown = () => emit('closeDropdown');
</script>

<template>
  <FilterButton
    right-icon="chevron-down"
    :button-text="name"
    @click="toggleDropdown"
  >
    <template v-if="showMenu && activeFilterType === type" #dropdown>
      <FilterListDropdown
        v-if="options"
        v-on-clickaway="closeDropdown"
        show-clear-filter
        :list-items="options"
        :active-filter-id="id"
        :input-placeholder="placeholder"
        :enable-search="enableSearch"
        class="flex flex-col w-[240px] overflow-y-auto left-0 md:left-auto md:right-0 top-10"
        @select="addFilter"
        @remove-filter="removeFilter"
      />
    </template>
  </FilterButton>
</template>
