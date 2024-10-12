<script setup>
import { ref, computed } from 'vue';
import { OnClickOutside } from '@vueuse/components';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  id: {
    type: String,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  articlesCount: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['click']);

const isOpen = ref(false);

const menuItems = [
  {
    label: 'Edit',
    action: 'edit',
    icon: 'edit',
  },
  {
    label: 'Delete',
    action: 'delete',
    icon: 'delete',
  },
];

const description = computed(() => {
  return props.description ? props.description : 'No description added';
});

const hasDescription = computed(() => {
  return props.description.length > 0;
});

const handleClick = id => {
  emit('click', id);
};

// eslint-disable-next-line no-unused-vars
const handleAction = action => {
  // TODO: Implement action
};
</script>

<!-- TODO: Add i18n -->
<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <CardLayout @click="handleClick(id)">
    <template #header>
      <div class="flex gap-2">
        <div class="flex justify-between w-full">
          <div class="flex items-center justify-start gap-2">
            <span
              class="text-base cursor-pointer group-hover/cardLayout:underline text-slate-900 dark:text-slate-50 line-clamp-1"
            >
              {{ title }}
            </span>
            <span
              class="inline-flex items-center justify-center h-6 px-2 py-1 text-xs text-center border rounded-lg text-slate-500 w-fit border-slate-200 dark:border-slate-800 dark:text-slate-400"
            >
              {{ articlesCount }} articles
            </span>
          </div>
          <div class="relative group" @click.stop>
            <Button
              variant="ghost"
              size="icon"
              icon="more-vertical"
              class="w-8 z-60 group-hover:bg-slate-100 dark:group-hover:bg-slate-800"
              @click="isOpen = !isOpen"
            />
            <OnClickOutside @trigger="isOpen = false">
              <DropdownMenu
                v-if="isOpen"
                :menu-items="menuItems"
                class="right-0 mt-1 xl:left-0 top-full z-60"
                @action="handleAction"
              />
            </OnClickOutside>
          </div>
        </div>
      </div>
    </template>
    <template #footer>
      <span
        class="text-sm line-clamp-3"
        :class="
          hasDescription
            ? 'text-slate-500 dark:text-slate-400'
            : 'text-slate-400 dark:text-slate-700'
        "
      >
        {{ description }}
      </span>
    </template>
  </CardLayout>
</template>
