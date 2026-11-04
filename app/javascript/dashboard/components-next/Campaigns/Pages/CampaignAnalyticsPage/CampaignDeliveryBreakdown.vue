<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { PercentageChart } from '@chatwoot/viz';

const props = defineProps({
  metrics: {
    type: Object,
    default: () => ({}),
  },
  loading: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();

const count = key => Number(props.metrics?.[key] || 0);

const audience = computed(() => count('audience'));

const segments = computed(() => {
  const read = count('read');
  const delivered = Math.max(count('delivered') - read, 0);
  const failed = count('failed');
  const skipped = count('skipped');
  const pending = Math.max(
    audience.value - read - delivered - failed - skipped,
    0
  );

  return [
    {
      key: 'read',
      value: read,
      color: 'rgb(var(--iris-9))',
      dotClass: 'bg-n-iris-9',
    },
    {
      key: 'delivered',
      value: delivered,
      color: 'rgb(var(--teal-9))',
      dotClass: 'bg-n-teal-9',
    },
    {
      key: 'failed',
      value: failed,
      color: 'rgb(var(--ruby-9))',
      dotClass: 'bg-n-ruby-9',
    },
    {
      key: 'skipped',
      value: skipped,
      color: 'rgb(var(--amber-9))',
      dotClass: 'bg-n-amber-9',
    },
    {
      key: 'pending',
      value: pending,
      color: 'rgb(var(--slate-6))',
      dotClass: 'bg-n-slate-6',
    },
  ].map(segment => ({
    ...segment,
    label: t(
      `CAMPAIGN.WHATSAPP.ANALYTICS.BREAKDOWN.LEGEND.${segment.key.toUpperCase()}`
    ),
  }));
});

const chartData = computed(() => ({
  total: audience.value,
  segments: segments.value.map(({ key, label, value, color }) => ({
    id: key,
    label,
    value,
    color,
  })),
}));

const deliveryRate = computed(() =>
  audience.value ? Math.round((count('delivered') / audience.value) * 100) : 0
);
</script>

<template>
  <div
    class="flex flex-col gap-4 p-5 border rounded-xl bg-n-solid-1 border-n-weak"
  >
    <div class="flex items-center justify-between gap-3">
      <span class="text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.WHATSAPP.ANALYTICS.BREAKDOWN.TITLE') }}
      </span>
      <span class="text-sm tabular-nums text-n-slate-11">
        {{
          t('CAMPAIGN.WHATSAPP.ANALYTICS.BREAKDOWN.DELIVERY_RATE', {
            value: deliveryRate,
          })
        }}
      </span>
    </div>
    <div
      v-if="loading"
      class="w-full h-2 rounded-full bg-n-slate-3 animate-pulse"
    />
    <PercentageChart
      v-else-if="audience"
      :data="chartData"
      :aria-label="t('CAMPAIGN.WHATSAPP.ANALYTICS.BREAKDOWN.TITLE')"
      :bar-height="8"
      :bar-gap="1"
      :bar-radius="999"
      :show-legend="false"
      :show-tooltip="false"
    />
    <div v-else class="w-full h-2 rounded-full bg-n-alpha-2" />
    <div class="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
      <div
        v-for="segment in segments"
        :key="segment.key"
        class="flex items-center min-w-0 gap-2"
      >
        <span class="rounded-full size-2 shrink-0" :class="segment.dotClass" />
        <span class="truncate text-body-main text-n-slate-11">
          {{ segment.label }}
        </span>
        <span class="font-medium tabular-nums text-body-main text-n-slate-12">
          {{ segment.value }}
        </span>
      </div>
    </div>
  </div>
</template>
