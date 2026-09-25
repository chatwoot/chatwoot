<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAdmin } from 'dashboard/composables/useAdmin';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import MonitorListItem from './MonitorListItem.vue';

const emit = defineEmits(['create']);

const PREVIEW_ROWS = [
  {
    recent_count: 128,
    icon: 'money-dollar-circle-line',
    icon_color: '#22C55E',
  },
  { recent_count: 64, icon: 'chat-3-line', icon_color: '#3B82F6' },
  { recent_count: 37, icon: 'settings-3-line', icon_color: '#8B5CF6' },
];

const { t } = useI18n();
const { isAdmin } = useAdmin();

const examples = computed(() => [
  {
    name: t('MONITORS.EXAMPLES.REFUNDS.NAME'),
    condition: t('MONITORS.EXAMPLES.REFUNDS.CONDITION'),
  },
  {
    name: t('MONITORS.EXAMPLES.BSUID.NAME'),
    condition: t('MONITORS.EXAMPLES.BSUID.CONDITION'),
  },
  {
    name: t('MONITORS.EXAMPLES.AUTOMATIONS.NAME'),
    condition: t('MONITORS.EXAMPLES.AUTOMATIONS.CONDITION'),
  },
]);
const previewMonitors = computed(() =>
  examples.value.map((example, index) => ({
    ...example,
    ...PREVIEW_ROWS[index],
    id: index + 1,
    paused_at: null,
  }))
);
</script>

<template>
  <section class="flex flex-col items-center gap-8 pb-12">
    <div
      inert
      class="w-full select-none opacity-70 [mask-image:linear-gradient(to_bottom,black,transparent)]"
    >
      <div class="flex flex-col divide-y divide-n-weak border-t border-n-weak">
        <MonitorListItem
          v-for="monitor in previewMonitors"
          :key="monitor.id"
          :monitor="monitor"
        />
      </div>
    </div>
    <div class="flex flex-col items-center gap-3 text-center">
      <h2 class="m-0 text-3xl font-medium text-n-slate-12">
        {{ t('MONITORS.EMPTY_TITLE') }}
      </h2>
      <p class="m-0 max-w-xl text-base tracking-[0.3px] text-n-slate-11">
        {{ t('MONITORS.EMPTY_DESCRIPTION') }}
      </p>
    </div>
    <Button
      v-if="isAdmin"
      icon="i-lucide-plus"
      :label="t('MONITORS.CREATE')"
      @click="emit('create')"
    />
    <p v-else class="m-0 text-sm text-n-slate-11">
      {{ t('MONITORS.ADMIN_HELP') }}
    </p>
    <div class="flex w-full max-w-xl flex-col gap-2">
      <span class="text-xs text-n-slate-10">
        {{ t('MONITORS.EXAMPLES_TITLE') }}
      </span>
      <button
        v-for="example in examples"
        :key="example.condition"
        type="button"
        :disabled="!isAdmin"
        class="flex w-full items-center justify-between gap-2 rounded-lg border border-n-weak bg-n-slate-2 px-3 py-2 text-start text-sm text-n-slate-11 transition-colors enabled:hover:bg-n-slate-3 enabled:hover:text-n-slate-12 disabled:cursor-not-allowed disabled:opacity-60"
        @click="emit('create', example)"
      >
        <span class="min-w-0 truncate">{{ example.condition }}</span>
        <Icon icon="i-lucide-chevron-right" class="size-4 shrink-0" />
      </button>
    </div>
  </section>
</template>
