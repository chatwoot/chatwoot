<script setup>
import FilterButton from 'dashboard/components/ui/Dropdown/DropdownButton.vue';
import FilterListDropdown from 'dashboard/components/ui/Dropdown/DropdownList.vue';
import FilterListItemButton from 'dashboard/components/ui/Dropdown/DropdownListItemButton.vue';
import FilterDropdownEmptyState from 'dashboard/components/ui/Dropdown/DropdownEmptyState.vue';

import { ref } from 'vue';

defineProps({
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

const emit = defineEmits(['toggleDropdown', 'addFilter', 'closeDropdown']);

const hoveredItemId = ref(null);

const showSubMenu = id => {
  hoveredItemId.value = id;
};

const hideSubMenu = () => {
  hoveredItemId.value = null;
};

const isHovered = id => hoveredItemId.value === id;

const toggleDropdown = () => emit('toggleDropdown');
const addFilter = item => {
  emit('addFilter', item);
  hideSubMenu();
};
const closeDropdown = () => {
  hideSubMenu();
  emit('closeDropdown');
};
</script>

<template>
  <FilterButton :button-text="name" left-icon="filter" @click="toggleDropdown">
    <!-- Dropdown with search and sub-dropdown -->
    <template v-if="showMenu" #dropdown>
      <FilterListDropdown
        v-on-clickaway="closeDropdown"
        class="left-0 md:right-0 top-10"
      >
        <template #listItem>
          <FilterDropdownEmptyState
            v-if="!menuOption.length"
            :message="emptyStateMessage"
          />
          <FilterListItemButton
            v-for="item in menuOption"
            :key="item.id"
            :button-text="item.name"
            @mouseenter="showSubMenu(item.id)"
            @mouseleave="hideSubMenu"
            @focus="showSubMenu(item.id)"
          >
            <!-- Submenu with search and clear button  -->
            <template v-if="item.options && isHovered(item.id)" #dropdown>
              <FilterListDropdown
                :list-items="item.options"
                :input-placeholder="
                  $t(`${placeholderI18nKey}.${item.type.toUpperCase()}`)
                "
                :enable-search="enableSearch"
                class="flex flex-col w-[216px] overflow-y-auto top-0 left-36"
                @select="addFilter"
              />
            </template>
          </FilterListItemButton>
        </template>
      </FilterListDropdown>
    </template>
  </FilterButton>
</template>
