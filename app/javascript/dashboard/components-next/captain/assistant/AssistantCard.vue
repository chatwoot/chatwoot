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
      <router-link
        :to="{ name: 'captain_assistants_edit', params: { assistantId: id } }"
        class="text-base text-n-slate-12 line-clamp-1 hover:underline transition-colors"
      >
        {{ name }}
      </router-link>
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
            class="mt-1 ltr:right-0 rtl:left-0 top-full"
            @action="handleAction($event)"
          />
        </div>
      </div>
    </div>
    <div class="flex items-center justify-between w-full gap-4">
      <span class="text-sm truncate text-n-slate-11">
        {{ description || 'Description not available' }}
      </span>
      <span class="text-sm text-n-slate-11 line-clamp-1 shrink-0">
        {{ lastUpdatedAt }}
      </span>
    </div>
  </CardLayout>
</template>
