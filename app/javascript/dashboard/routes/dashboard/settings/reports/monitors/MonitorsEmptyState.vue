<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAdmin } from 'dashboard/composables/useAdmin';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import MonitorListItem from './MonitorListItem.vue';

const emit = defineEmits(['create']);

const PREVIEW_COUNTS = [128, 64, 37];

const { t } = useI18n();
const { isAdmin } = useAdmin();

const examples = computed(() => [
  {
    name: t('MONITORS.EXAMPLES.LOGIN_PROBLEMS.NAME'),
    condition: t('MONITORS.EXAMPLES.LOGIN_PROBLEMS.CONDITION'),
  },
  {
    name: t('MONITORS.EXAMPLES.MISSING_ORDER_UPDATES.NAME'),
    condition: t('MONITORS.EXAMPLES.MISSING_ORDER_UPDATES.CONDITION'),
  },
  {
    name: t('MONITORS.EXAMPLES.COMPETITOR_MENTIONS.NAME'),
    condition: t('MONITORS.EXAMPLES.COMPETITOR_MENTIONS.CONDITION'),
  },
  {
    name: t('MONITORS.EXAMPLES.FEATURE_REQUESTS.NAME'),
    condition: t('MONITORS.EXAMPLES.FEATURE_REQUESTS.CONDITION'),
  },
  {
    name: t('MONITORS.EXAMPLES.REFUND_REQUESTS.NAME'),
    condition: t('MONITORS.EXAMPLES.REFUND_REQUESTS.CONDITION'),
  },
  {
    name: t('MONITORS.EXAMPLES.CANCELLATION_INTENT.NAME'),
    condition: t('MONITORS.EXAMPLES.CANCELLATION_INTENT.CONDITION'),
  },
]);
const previewMonitors = computed(() =>
  examples.value.slice(0, PREVIEW_COUNTS.length).map((example, index) => ({
    ...example,
    id: index + 1,
    recent_count: PREVIEW_COUNTS[index],
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
        :key="example.name"
        type="button"
        :disabled="!isAdmin"
        class="flex w-full items-center justify-between gap-2 rounded-lg border border-n-weak bg-n-slate-2 px-3 py-2 text-start text-sm text-n-slate-11 transition-colors enabled:hover:bg-n-slate-3 enabled:hover:text-n-slate-12 disabled:cursor-not-allowed disabled:opacity-60"
        @click="emit('create', example)"
      >
        <span class="flex min-w-0 flex-col gap-1">
          <span class="font-medium text-n-slate-12">{{ example.name }}</span>
          <span class="line-clamp-2 text-xs text-n-slate-11">
            {{ example.condition }}
          </span>
        </span>
        <Icon icon="i-lucide-chevron-right" class="size-4 shrink-0" />
      </button>
    </div>
  </section>
</template>
