<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { usePolicy } from 'dashboard/composables/usePolicy';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  name: {
    type: String,
    required: true,
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
  description: {
    type: String,
    default: '',
  },
  status: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['action']);
const { checkPermissions } = usePolicy();

const { t } = useI18n();

const [showActionsDropdown, toggleDropdown] = useToggle();

const menuItems = computed(() => {
  const allOptions = [];

  if (checkPermissions(['administrator'])) {
    allOptions.push({
      label: t('CAPTAIN.DOCUMENTS.OPTIONS.EDIT_DOCUMENT'),
      value: 'edit',
      action: 'edit',
      icon: 'i-lucide-pencil-line',
    });
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

const isPending = computed(() => {
  console.log('[DocumentCard] status prop:', props.status, 'isPending:', props.status === 'pending');
  return props.status === 'pending';
});

const handleAction = ({ action, value }) => {
  toggleDropdown(false);
  emit('action', { action, value, id: props.id });
};

const displayName = computed(() => props.name || t('CAPTAIN.DOCUMENTS.UNTITLED'));
const displayLink = computed(() => {
  // Always display 'LINK' if there is a link, otherwise blank
  return props.externalLink ? 'LINK' : '';
});
</script>

<template>
  <CardLayout>
    <div class="flex justify-between w-full gap-1">
      <div class="flex items-center gap-2">
        <span class="text-base text-n-slate-12 line-clamp-1">
          {{ displayName }}
        </span>
        <div v-if="isPending" class="relative group">
          <Icon
            icon="i-lucide-clock"
            class="text-n-slate-11"
          />
          <div class="absolute hidden group-hover:block bg-n-slate-1 text-n-slate-12 text-xs p-2 rounded shadow-sm whitespace-nowrap">
            {{ t('CAPTAIN.DOCUMENTS.PENDING_INDICATOR') }}
          </div>
        </div>
      </div>
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
    <div v-if="description" class="text-n-slate-11 text-sm mb-1">
      {{ description }}
    </div>
    <div class="flex items-center justify-between w-full gap-4">
      <span
        class="text-n-slate-11 text-sm truncate flex justify-start flex-1 items-center gap-1"
      >
        <i class="i-ph-link-simple shrink-0" />
        <template v-if="externalLink">
          <a 
            :href="externalLink"
            target="_blank"
            rel="noopener noreferrer"
            class="truncate hover:underline"
          >
            LINK
          </a>
        </template>
        <template v-else>
          <span class="truncate opacity-60 cursor-default">LINK</span>
        </template>
      </span>
      <div class="shrink-0 text-sm text-n-slate-11 line-clamp-1">
        {{ createdAt }}
      </div>
    </div>
  </CardLayout>
</template>
