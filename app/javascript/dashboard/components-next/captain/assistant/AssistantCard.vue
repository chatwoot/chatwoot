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
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  updatedAt: {
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
      label: t('CAPTAIN.ASSISTANTS.OPTIONS.VIEW_CONNECTED_INBOXES'),
      value: 'viewConnectedInboxes',
      action: 'viewConnectedInboxes',
      icon: 'i-lucide-link',
    },
  ];

  if (checkPermissions(['administrator'])) {
    allOptions.push(
      {
        label: t('CAPTAIN.ASSISTANTS.OPTIONS.EDIT_ASSISTANT'),
        value: 'edit',
        action: 'edit',
        icon: 'i-lucide-pencil-line',
      },
      {
        label: t('CAPTAIN.ASSISTANTS.OPTIONS.DELETE_ASSISTANT'),
        value: 'delete',
        action: 'delete',
        icon: 'i-lucide-trash',
      }
    );
  }

  return allOptions;
});

const lastUpdatedAt = computed(() => dynamicTime(props.updatedAt));

const handleAction = ({ action, value }) => {
  toggleDropdown(false);
  emit('action', { action, value, id: props.id });
};
</script>

<template>
  <CardLayout>
    <div class="flex justify-between w-full gap-1">
      <h6
        class="line-clamp-1 text-base font-normal text-on-surface transition-colors hover:underline"
      >
        {{ name }}
      </h6>
      <div class="flex items-center gap-2">
        <div
          v-on-clickaway="() => toggleDropdown(false)"
          class="relative flex items-center group"
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
            class="mt-1 ltr:right-0 rtl:left-0 top-full"
            @action="handleAction($event)"
          />
        </div>
      </div>
    </div>
    <div class="flex items-center justify-between w-full gap-4">
      <span class="truncate text-sm text-on-surface-variant">
        {{ description || t('CAPTAIN.ASSISTANTS.CARD_DESCRIPTION_FALLBACK') }}
      </span>
      <span class="line-clamp-1 shrink-0 text-sm text-on-surface-variant">
        {{ lastUpdatedAt }}
      </span>
    </div>
  </CardLayout>
</template>
