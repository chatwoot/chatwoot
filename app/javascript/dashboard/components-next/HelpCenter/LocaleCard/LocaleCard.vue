<script setup>
import { ref } from 'vue';
import { OnClickOutside } from '@vueuse/components';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

defineProps({
  locale: {
    type: String,
    required: true,
  },
  isDefault: {
    type: Boolean,
    required: true,
  },
  articleCount: {
    type: Number,
    required: true,
  },
  categoryCount: {
    type: Number,
    required: true,
  },
});

const isOpen = ref(false);

const menuItems = [
  {
    label: 'Make default',
    action: 'default',
    icon: 'star-emphasis',
  },
  {
    label: 'Delete',
    action: 'delete',
    icon: 'delete',
  },
];

// eslint-disable-next-line no-unused-vars
const handleAction = action => {
  // TODO: Implement action
};
</script>

<!-- TODO: Add i18n -->
<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <CardLayout class="ltr:pr-2 rtl:pl-2">
    <template #header>
      <div class="flex justify-between gap-2">
        <div class="flex items-center justify-start gap-2">
          <span
            class="text-sm font-medium text-slate-900 dark:text-slate-50 line-clamp-1"
          >
            {{ locale }}
          </span>
          <span
            v-if="isDefault"
            class="bg-slate-100 dark:bg-slate-800 h-6 inline-flex items-center justify-center rounded-md text-xs border-px border-transparent text-woot-500 dark:text-woot-400 px-2 py-0.5"
          >
            Default
          </span>
        </div>
        <div class="flex items-center justify-end gap-1">
          <div class="flex items-center gap-4">
            <span
              class="text-sm text-slate-500 dark:text-slate-400 whitespace-nowrap"
            >
              {{ articleCount }} articles
            </span>
            <div class="w-px h-3 bg-slate-75 dark:bg-slate-800" />
            <span
              class="text-sm text-slate-500 dark:text-slate-400 whitespace-nowrap"
            >
              {{ categoryCount }} categories
            </span>
          </div>
          <div class="relative group">
            <Button
              variant="ghost"
              size="icon"
              icon="more-vertical"
              class="w-8 group-hover:bg-slate-100 dark:group-hover:bg-slate-800"
              @click="isOpen = !isOpen"
            />
            <OnClickOutside @trigger="isOpen = false">
              <DropdownMenu
                v-if="isOpen"
                :menu-items="menuItems"
                class="right-0 mt-1 xl:left-0 top-full z-60 min-w-[147px]"
                @action="handleAction"
              />
            </OnClickOutside>
          </div>
        </div>
      </div>
    </template>
  </CardLayout>
</template>
