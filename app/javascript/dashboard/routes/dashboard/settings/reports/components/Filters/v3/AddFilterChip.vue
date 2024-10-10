<script setup>
import FilterButton from './FilterButton.vue';
import FilterListDropdown from './FilterListDropdown.vue';
import FilterListItemButton from './FilterListItemButton.vue';
import FilterDropdownEmptyState from './FilterDropdownEmptyState.vue';

import { ref } from 'vue';
import { createPopper } from '@popperjs/core';

const props = defineProps({
  name: {
    type: String,
    required: true,
  },
  menuOption: {
    type: Array,
    default: () => [],
  },
  showMenu: {
    type: Boolean,
    default: false,
  },
  placeholderI18nKey: {
    type: String,
    default: '',
  },
  enableSearch: {
    type: Boolean,
    default: true,
  },
  emptyStateMessage: {
    type: String,
    default: '',
  },
});

const hoveredItemId = ref(null);
const popperInstances = ref({});

const getPopperInstance = id => {
  return popperInstances.value[id];
};

const showSubMenu = id => {
  hoveredItemId.value = id;

  const popperInstance = getPopperInstance(id);
  popperInstance.update();
};

const hideSubMenu = () => {
  hoveredItemId.value = null;
};

const isHovered = id => hoveredItemId.value === id;

const emit = defineEmits(['toggleDropdown', 'addFilter', 'closeDropdown']);
const toggleDropdown = () => emit('toggleDropdown');
const addFilter = item => {
  emit('addFilter', item);
  hideSubMenu();
};
const closeDropdown = () => {
  hideSubMenu();
  emit('closeDropdown');
};

const createPopperInstances = () => {
  popperInstances.value = props.menuOption.reduce((acc, { id }) => {
    const reference = document.querySelector(`#filter-item-${id}`);
    const popper = document.querySelector(`#filter-submenu-${id}`);
    const viewport = document.querySelector('#kanban-board');
    return {
      ...acc,
      [id]: createPopper(reference, popper, {
        placement: 'right-start',
        modifiers: [
          {
            name: 'offset',
            options: {
              offset: [0, 2],
            },
          },
          {
            name: 'preventOverflow',
            padding: 20,
            options: {
              boundary: viewport,
            },
          },
        ],
      }),
    };
  }, {});
};
</script>

<template>
  <filter-button :button-text="name" left-icon="filter" @click="toggleDropdown">
    <!-- Dropdown with search and sub-dropdown -->
    <template v-if="showMenu" #dropdown>
      <filter-list-dropdown
        v-on-clickaway="closeDropdown"
        class="left-0 md:right-0 top-10"
        @createPopperInstances="createPopperInstances"
      >
        <template #listItem>
          <filter-dropdown-empty-state
            v-if="!menuOption.length"
            :message="emptyStateMessage"
          />
          <filter-list-item-button
            v-for="item in menuOption"
            :id="`filter-item-${item.id}`"
            :key="item.id"
            :button-text="item.name"
            @mouseenter="showSubMenu(item.id)"
            @mouseleave="hideSubMenu"
            @focus="showSubMenu(item.id)"
          >
            <!-- Submenu with search and clear button  -->
            <template v-if="item.options" #dropdown>
              <filter-list-dropdown
                v-show="isHovered(item.id)"
                :id="`filter-submenu-${item.id}`"
                :list-items="item.options"
                :input-placeholder="$t('GENERAL.LIST_SEARCH_PLACEHOLDER')"
                :enable-search="enableSearch"
                class="flex flex-col w-80 overflow-y-auto top-0 left-36 max-h-[calc(100vh-7rem)]"
                @click="addFilter"
              />
            </template>
          </filter-list-item-button>
        </template>
      </filter-list-dropdown>
    </template>
  </filter-button>
</template>
