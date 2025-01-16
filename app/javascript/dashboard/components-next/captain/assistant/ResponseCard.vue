<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  question: {
    type: String,
    required: true,
  },
  answer: {
    type: String,
    required: true,
  },
  compact: {
    type: Boolean,
    default: false,
  },
  status: {
    type: String,
    default: 'approved',
  },
  assistant: {
    type: Object,
    default: () => ({}),
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

const statusAction = computed(() => {
  if (props.status === 'pending') {
    return [
      {
        label: t('CAPTAIN.RESPONSES.OPTIONS.APPROVE'),
        value: 'approve',
        action: 'approve',
        icon: 'i-lucide-circle-check-big',
      },
    ];
  }
  return [];
});

const menuItems = computed(() => [
  ...statusAction.value,
  {
    label: t('CAPTAIN.RESPONSES.OPTIONS.EDIT_RESPONSE'),
    value: 'edit',
    action: 'edit',
    icon: 'i-lucide-pencil-line',
  },
  {
    label: t('CAPTAIN.RESPONSES.OPTIONS.DELETE_RESPONSE'),
    value: 'delete',
    action: 'delete',
    icon: 'i-lucide-trash',
  },
]);

const timestamp = computed(() =>
  dynamicTime(props.updatedAt || props.createdAt)
);

const handleAssistantAction = ({ action, value }) => {
  toggleDropdown(false);
  emit('action', { action, value, id: props.id });
};
</script>

<template>
  <CardLayout :class="{ 'rounded-md': compact }">
    <div class="flex justify-between w-full gap-1">
      <span class="text-base text-n-slate-12 line-clamp-1">
        {{ question }}
      </span>
      <div v-if="!compact" class="flex items-center gap-2">
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
            class="mt-1 ltr:right-0 rtl:right-0 top-full"
            @action="handleAssistantAction($event)"
          />
        </div>
      </div>
    </div>
    <span class="text-n-slate-11 text-sm line-clamp-5">
      {{ answer }}
    </span>
    <span v-if="!compact">
      <span
        class="text-sm shrink-0 truncate text-n-slate-11 inline-flex items-center gap-1"
      >
        <i class="i-woot-captain" />
        {{ assistant?.name || '' }}
      </span>
      <div
        v-if="status !== 'approved'"
        class="shrink-0 text-sm text-n-slate-11 line-clamp-1 inline-flex items-center gap-1 ml-3"
      >
        <i
          class="i-ph-stack text-base"
          :title="t('CAPTAIN.RESPONSES.STATUS.TITLE')"
        />
        {{ t(`CAPTAIN.RESPONSES.STATUS.${status.toUpperCase()}`) }}
      </div>
      <div
        class="shrink-0 text-sm text-n-slate-11 line-clamp-1 inline-flex items-center gap-1 ml-3"
      >
        <i class="i-ph-calendar-dot" />
        {{ timestamp }}
      </div>
    </span>
  </CardLayout>
</template>
