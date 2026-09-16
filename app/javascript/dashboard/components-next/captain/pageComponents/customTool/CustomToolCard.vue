<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { useExactTimestamp } from 'shared/composables/useExactTimestamp';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
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
  enabled: {
    type: Boolean,
    default: true,
  },
  isUpdating: {
    type: Boolean,
    default: false,
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

const emit = defineEmits(['action', 'toggle']);

const exactTimestamp = useExactTimestamp();

const { t } = useI18n();

const [showActionsDropdown, toggleDropdown] = useToggle();

const enabledState = computed({
  get: () => props.enabled,
  set: enabled => emit('toggle', { id: props.id, enabled }),
});

const statusLabel = computed(() =>
  props.enabled
    ? t('CAPTAIN.CUSTOM_TOOLS.STATUS.ENABLED')
    : t('CAPTAIN.CUSTOM_TOOLS.STATUS.DISABLED')
);

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
      <span class="text-base text-n-slate-12 line-clamp-1 font-medium">
        {{ title }}
      </span>
      <div class="flex items-center gap-2">
        <span class="text-xs text-n-slate-11">
          {{ statusLabel }}
        </span>
        <Policy
          as="span"
          :permissions="['administrator']"
          class="inline-flex items-center"
        >
          <Switch
            v-model="enabledState"
            :disabled="isUpdating"
            :aria-label="t('CAPTAIN.CUSTOM_TOOLS.STATUS.TOGGLE', { title })"
            :class="{ 'opacity-50 cursor-not-allowed': isUpdating }"
          />
        </Policy>
        <Policy
          v-on-clickaway="() => toggleDropdown(false)"
          :permissions="['administrator']"
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
            @action="handleAction($event)"
          />
        </Policy>
      </div>
    </div>
    <div class="flex items-center justify-between w-full gap-4 min-w-0">
      <div class="flex items-center gap-3 flex-1 min-w-0">
        <span v-if="description" class="text-sm truncate text-n-slate-11">
          {{ description }}
        </span>
        <span
          v-if="authType !== 'none'"
          class="text-sm shrink-0 text-n-slate-11 inline-flex items-center gap-1"
        >
          <i class="i-lucide-lock text-base" />
          {{ authTypeLabel }}
        </span>
      </div>
      <span
        v-tooltip.top="{
          content: exactTimestamp(updatedAt || createdAt),
          delay: { show: 500, hide: 0 },
        }"
        class="text-sm text-n-slate-11 line-clamp-1 shrink-0"
      >
        {{ timestamp }}
      </span>
    </div>
  </CardLayout>
</template>
