<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  icon: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  articlesCount: {
    type: Number,
    required: true,
  },
  slug: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['click', 'action']);

const { t } = useI18n();

const [showActionsDropdown, toggleDropdown] = useToggle();

const categoryMenuItems = [
  {
    label: 'Edit',
    action: 'edit',
    value: 'edit',
    icon: 'i-lucide-pencil',
  },
  {
    label: 'Delete',
    action: 'delete',
    value: 'delete',
    icon: 'i-lucide-trash',
  },
];

const categoryTitleWithIcon = computed(() => {
  return `${props.icon} ${props.title}`;
});

const description = computed(() => {
  return props.description ? props.description : 'No description added';
});

const hasDescription = computed(() => {
  return props.description.length > 0;
});

const handleClick = slug => {
  emit('click', slug);
};

const handleAction = ({ action, value }) => {
  emit('action', { action, value, id: props.id });
  toggleDropdown(false);
};
</script>

<template>
  <CardLayout>
    <div class="flex w-full gap-2">
      <div class="flex justify-between w-full gap-2">
        <div class="flex items-center justify-start w-full min-w-0 gap-2">
          <span
            class="text-base truncate cursor-pointer hover:underline underline-offset-2 hover:text-n-blue-text text-n-slate-12"
            @click="handleClick(slug)"
          >
            {{ categoryTitleWithIcon }}
          </span>
          <span
            class="inline-flex items-center justify-center h-6 px-2 py-1 text-xs text-center border rounded-lg bg-n-slate-1 whitespace-nowrap shrink-0 text-n-slate-11 border-n-slate-4"
          >
            {{
              t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_CARD.ARTICLES_COUNT', {
                count: articlesCount,
              })
            }}
          </span>
        </div>
        <div
          v-on-clickaway="() => toggleDropdown(false)"
          class="relative group"
        >
          <Button
            icon="i-lucide-ellipsis-vertical"
            color="slate"
            size="xs"
            variant="ghost"
            class="rounded-md group-hover:bg-n-alpha-2"
            @click="toggleDropdown()"
          />
          <DropdownMenu
            v-if="showActionsDropdown"
            :menu-items="categoryMenuItems"
            class="mt-1 ltr:right-0 rtl:left-0 xl:ltr:left-0 xl:rtl:right-0 top-full z-60"
            @action="handleAction"
          />
        </div>
      </div>
    </div>
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
  </CardLayout>
</template>
