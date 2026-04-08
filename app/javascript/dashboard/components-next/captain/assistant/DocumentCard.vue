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
  status: {
    type: String,
    default: 'available',
  },
  faqGeneration: {
    type: Object,
    default: null,
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

const processingStatusLabel = computed(() => {
  if (props.status === 'in_progress') {
    return t('CAPTAIN.DOCUMENTS.STATUS.INGESTING');
  }
  const st = props.faqGeneration?.status;
  if (st === 'queued') return t('CAPTAIN.DOCUMENTS.STATUS.FAQ_QUEUED');
  if (st === 'processing') return t('CAPTAIN.DOCUMENTS.STATUS.FAQ_PROCESSING');
  if (st === 'failed') return t('CAPTAIN.DOCUMENTS.STATUS.FAQ_FAILED');
  return '';
});

const showProcessingStatus = computed(() => processingStatusLabel.value !== '');

const showStatusSpinner = computed(() => {
  if (props.status === 'in_progress') return true;
  const st = props.faqGeneration?.status;
  return st === 'queued' || st === 'processing';
});

const handleAction = ({ action, value }) => {
  toggleDropdown(false);
  emit('action', { action, value, id: props.id });
};
</script>

<template>
  <CardLayout>
    <div class="flex gap-1 justify-between w-full">
      <div class="flex flex-col gap-1 min-w-0 flex-1">
        <span class="line-clamp-1 text-base text-on-surface">
          {{ name }}
        </span>
        <span
          v-if="showProcessingStatus"
          class="inline-flex items-center gap-1.5 text-xs text-secondary"
        >
          <i
            v-if="showStatusSpinner"
            class="i-lucide-loader-2 size-3.5 shrink-0 animate-spin text-secondary"
          />
          <i
            v-else
            class="i-lucide-circle-alert size-3.5 shrink-0 text-warning"
          />
          {{ processingStatusLabel }}
        </span>
      </div>
      <div class="flex gap-2 items-center shrink-0">
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
