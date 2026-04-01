<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { usePolicy } from 'dashboard/composables/usePolicy';
import {
  isPdfDocument,
  formatDocumentLink,
} from 'shared/helpers/documentHelper';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  name: {
    type: String,
    default: '',
  },
  assistant: {
    type: Object,
    default: () => ({}),
  },
  externalLink: {
    type: String,
    required: true,
  },
  createdAt: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['action']);
const { checkPermissions } = usePolicy();

const { t } = useI18n();

const [showActionsDropdown, toggleDropdown] = useToggle();

const menuItems = computed(() => {
  const allOptions = [
    {
      label: t('CAPTAIN.DOCUMENTS.OPTIONS.VIEW_RELATED_RESPONSES'),
      value: 'viewRelatedQuestions',
      action: 'viewRelatedQuestions',
      icon: 'i-ph-tree-view-duotone',
    },
  ];

  if (checkPermissions(['administrator'])) {
    allOptions.push({
      label: t('CAPTAIN.DOCUMENTS.OPTIONS.DELETE_DOCUMENT'),
      value: 'delete',
      action: 'delete',
      icon: 'i-lucide-trash',
    });
  }

  return allOptions;
});

const createdAt = computed(() => dynamicTime(props.createdAt));

const displayLink = computed(() => formatDocumentLink(props.externalLink));
const linkIcon = computed(() =>
  isPdfDocument(props.externalLink) ? 'i-ph-file-pdf' : 'i-ph-link-simple'
);

const handleAction = ({ action, value }) => {
  toggleDropdown(false);
  emit('action', { action, value, id: props.id });
};
</script>

<template>
  <CardLayout>
    <div class="flex gap-1 justify-between w-full">
      <span class="line-clamp-1 text-base text-on-surface">
        {{ name }}
      </span>
      <div class="flex gap-2 items-center">
        <div
          v-on-clickaway="() => toggleDropdown(false)"
          class="flex relative items-center group"
        >
          <Button
            icon="i-lucide-ellipsis-vertical"
            ghost
            slate
            xs
            class="rounded-md text-on-surface-variant group-hover:bg-surface-container-highest"
            @click="toggleDropdown()"
          />
          <DropdownMenu
            v-if="showActionsDropdown"
            :menu-items="menuItems"
            class="top-full mt-1 ltr:right-0 rtl:left-0 xl:ltr:right-0 xl:rtl:left-0"
            @action="handleAction($event)"
          />
        </div>
      </div>
    </div>
    <div class="flex gap-4 justify-between items-center w-full">
      <span
        class="flex shrink-0 items-center gap-1 truncate text-sm text-on-surface-variant"
      >
        <i class="i-woot-captain" />
        {{ assistant?.name || '' }}
      </span>
      <span
        class="flex flex-1 items-center justify-start gap-1 truncate text-sm text-on-surface-variant"
      >
        <i :class="linkIcon" class="shrink-0" />
        <span class="truncate">{{ displayLink }}</span>
      </span>
      <div class="line-clamp-1 shrink-0 text-sm text-on-surface-variant">
        {{ createdAt }}
      </div>
    </div>
  </CardLayout>
</template>
