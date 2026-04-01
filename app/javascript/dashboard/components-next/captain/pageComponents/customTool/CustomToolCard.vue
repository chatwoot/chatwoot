<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Policy from 'dashboard/components/policy.vue';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
  authType: {
    type: String,
    default: 'none',
  },
  updatedAt: {
    type: Number,
    required: true,
  },
  createdAt: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['action']);

const { t } = useI18n();

const [showActionsDropdown, toggleDropdown] = useToggle();

const menuItems = computed(() => [
  {
    label: t('CAPTAIN.CUSTOM_TOOLS.OPTIONS.EDIT_TOOL'),
    value: 'edit',
    action: 'edit',
    icon: 'i-lucide-pencil-line',
  },
  {
    label: t('CAPTAIN.CUSTOM_TOOLS.OPTIONS.DELETE_TOOL'),
    value: 'delete',
    action: 'delete',
    icon: 'i-lucide-trash',
  },
]);

const timestamp = computed(() =>
  dynamicTime(props.updatedAt || props.createdAt)
);

const handleAction = ({ action, value }) => {
  toggleDropdown(false);
  emit('action', { action, value, id: props.id });
};

const authTypeLabel = computed(() => {
  return t(
    `CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_TYPES.${props.authType.toUpperCase()}`
  );
});
</script>

<template>
  <CardLayout class="relative">
    <div class="flex relative justify-between w-full gap-1">
      <span class="line-clamp-1 text-base font-medium text-on-surface">
        {{ title }}
      </span>
      <div class="flex items-center gap-2">
        <Policy
          v-on-clickaway="() => toggleDropdown(false)"
          :permissions="['administrator']"
          class="group relative flex items-center"
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
            class="mt-1 ltr:right-0 rtl:right-0 top-full"
            @action="handleAction($event)"
          />
        </Policy>
      </div>
    </div>
    <div class="flex w-full items-center justify-between gap-4">
      <div class="flex flex-1 items-center gap-3">
        <span
          v-if="description"
          class="flex-1 truncate text-sm text-on-surface-variant"
        >
          {{ description }}
        </span>
        <span
          v-if="authType !== 'none'"
          class="inline-flex shrink-0 items-center gap-1 text-sm text-on-surface-variant"
        >
          <i class="i-lucide-lock text-base" />
          {{ authTypeLabel }}
        </span>
      </div>
      <span class="line-clamp-1 shrink-0 text-sm text-on-surface-variant">
        {{ timestamp }}
      </span>
    </div>
  </CardLayout>
</template>
