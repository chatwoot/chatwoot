<script setup>
import { computed, ref } from 'vue';
import { OnClickOutside } from '@vueuse/components';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon.vue';

const props = defineProps({
  title: {
    type: String,
    required: true,
  },
  status: {
    type: String,
    required: true,
  },
  author: {
    type: String,
    required: true,
  },
  category: {
    type: String,
    required: true,
  },
  views: {
    type: Number,
    required: true,
  },
  updatedAt: {
    type: String,
    required: true,
  },
});

const isOpen = ref(false);

const menuItems = computed(() => {
  const baseItems = [{ label: 'Delete', action: 'delete', icon: 'delete' }];
  const menuOptions = {
    archived: [
      { label: 'Publish', action: 'publish', icon: 'checkmark' },
      { label: 'Draft', action: 'draft', icon: 'draft' },
    ],
    draft: [
      { label: 'Publish', action: 'publish', icon: 'checkmark' },
      { label: 'Archive', action: 'archive', icon: 'archive' },
    ],
    '': [
      // Empty string represents published status
      { label: 'Draft', action: 'draft', icon: 'draft' },
      { label: 'Archive', action: 'archive', icon: 'archive' },
    ],
  };
  return [...(menuOptions[props.status] || menuOptions['']), ...baseItems];
});

const statusTextColor = computed(() => {
  switch (props.status) {
    case 'archived':
      return '!text-slate-600 dark:!text-slate-200';
    case 'draft':
      return '!text-amber-700 dark:!text-amber-400';
    default:
      return '!text-teal-700 dark:!text-teal-400';
  }
});

const statusText = computed(() => {
  switch (props.status) {
    case 'archived':
      return 'Archived';
    case 'draft':
      return 'Draft';
    default:
      return 'Published';
  }
});

const handleAction = () => {
  isOpen.value = false;
};
</script>

<!-- TODO: Add i18n -->
<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <CardLayout>
    <template #header>
      <div class="flex justify-between gap-1">
        <span class="text-base text-slate-900 dark:text-slate-50 line-clamp-1">
          {{ title }}
        </span>
        <div class="relative group">
          <Button
            variant="ghost"
            size="sm"
            class="text-xs bg-slate-50 !font-normal group-hover:bg-slate-100/50 dark:group-hover:bg-slate-700/50 !h-6 dark:bg-slate-800 rounded-md border-0 !px-2 !py-0.5"
            :label="statusText"
            :class="statusTextColor"
            @click="isOpen = !isOpen"
          />
          <OnClickOutside @trigger="isOpen = false">
            <DropdownMenu
              v-if="isOpen"
              :menu-items="menuItems"
              class="right-0 mt-2 xl:left-0 top-full"
              @action="handleAction"
            />
          </OnClickOutside>
        </div>
      </div>
    </template>
    <template #footer>
      <div class="flex items-center justify-between gap-4">
        <div class="flex items-center gap-4">
          <div class="flex items-center gap-1">
            <div class="w-4 h-4 rounded-full bg-slate-100 dark:bg-slate-700" />
            <span class="text-sm text-slate-500 dark:text-slate-400">
              {{ author }}
            </span>
          </div>
          <span
            class="block text-sm whitespace-nowrap text-slate-500 dark:text-slate-400"
          >
            {{ category }}
          </span>
          <div
            class="inline-flex items-center gap-1 text-slate-500 dark:text-slate-400 whitespace-nowrap"
          >
            <FluentIcon icon="eye-show" size="18" />
            <span class="text-sm"> {{ views }} views </span>
          </div>
        </div>
        <span class="text-sm text-slate-600 dark:text-slate-400 line-clamp-1">
          {{ updatedAt }}
        </span>
      </div>
    </template>
  </CardLayout>
</template>
