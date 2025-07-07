<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { usePolicy } from 'dashboard/composables/usePolicy';

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
  file: {
    type: Object,
    default: null,
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

const displayLink = computed(() => {
  // For PDF uploads, show the filename instead of the generated external_link
  if (props.file?.filename) {
    return props.file.filename;
  }
  return props.externalLink;
});

const actualLink = computed(() => {
  // For PDF uploads, return the actual file URL; for URLs, return the external_link
  if (props.file?.url) {
    return props.file.url;
  }
  return props.externalLink;
});

const handleAction = ({ action, value }) => {
  toggleDropdown(false);
  emit('action', { action, value, id: props.id });
};
</script>

<template>
  <CardLayout>
    <div class="flex justify-between w-full gap-1">
      <span class="text-base text-n-slate-12 line-clamp-1">
        {{ name }}
      </span>
      <div class="flex items-center gap-2">
        <div
          v-on-clickaway="() => toggleDropdown(false)"
          class="relative flex items-center group"
        >
          <Button
            icon="i-lucide-ellipsis-vertical"
            color="slate"
            size="xs"
            class="rounded-md group-hover:bg-n-alpha-2"
            @click="toggleDropdown()"
          />
          <DropdownMenu
            v-if="showActionsDropdown"
            :menu-items="menuItems"
            class="mt-1 ltr:right-0 rtl:left-0 xl:ltr:right-0 xl:rtl:left-0 top-full"
            @action="handleAction($event)"
          />
        </div>
      </div>
    </div>
    <div class="flex items-center justify-between w-full gap-4">
      <span
        class="text-sm shrink-0 truncate text-n-slate-11 flex items-center gap-1"
      >
        <i class="i-woot-captain" />
        {{ assistant?.name || '' }}
      </span>
      <a
        :href="actualLink"
        target="_blank"
        rel="noopener noreferrer"
        class="text-n-slate-11 text-sm truncate flex justify-start flex-1 items-center gap-1 hover:text-n-slate-12 transition-colors"
      >
        <i class="i-ph-link-simple shrink-0" />
        <span class="truncate">{{ displayLink }}</span>
      </a>
      <div class="shrink-0 text-sm text-n-slate-11 line-clamp-1">
        {{ createdAt }}
      </div>
    </div>
  </CardLayout>
</template>
