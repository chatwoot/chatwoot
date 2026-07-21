<script setup>
import { computed } from 'vue';

const props = defineProps({
  // The credit_usage stat from the overview stats endpoint:
  // { current, previous, trend, daily: [{ date, value }] }
  usage: { type: Object, default: null },
});

const daily = computed(() => props.usage?.daily ?? []);

// Bar heights as a percentage of the peak day, with a small floor so even the
// lowest day stays visible.
const bars = computed(() => {
  const max = Math.max(...daily.value.map(day => day.value), 0);
  return daily.value.map(day => ({
    key: day.date,
    value: day.value,
    height: max === 0 ? 6 : Math.max(6, Math.round((day.value / max) * 100)),
  }));
});

const total = computed(() =>
  props.usage ? props.usage.current.toLocaleString() : '—'
);

const trend = computed(() => {
  if (!props.usage?.trend) return '';
  const sign = props.usage.trend > 0 ? '+' : '';
  return `${sign}${props.usage.trend}%`;
});

const formatDate = date =>
  new Date(date).toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
  });

const axisStart = computed(() =>
  daily.value.length ? formatDate(daily.value[0].date) : ''
);
const axisEnd = computed(() =>
  daily.value.length ? formatDate(daily.value[daily.value.length - 1].date) : ''
);
</script>

<template>
  <section
    class="flex flex-col gap-4 p-5 border rounded-xl bg-n-solid-1 border-n-weak"
  >
    <div class="flex items-start justify-between gap-4">
      <div class="flex flex-col gap-1">
        <div class="flex items-center gap-1.5">
          <h3 class="text-sm font-medium text-n-slate-12">
            {{ $t('CAPTAIN.OVERVIEW.CREDITS.TITLE') }}
          </h3>
          <span
            v-tooltip="$t('CAPTAIN.OVERVIEW.CREDITS.DISCLAIMER')"
            class="cursor-help i-lucide-info size-3.5 text-n-slate-9"
          />
        </div>
        <div class="flex items-baseline gap-2">
          <span class="text-2xl font-semibold tabular-nums text-n-slate-12">
            {{ total }}
          </span>
          <span class="text-sm text-n-slate-11">
            {{ $t('CAPTAIN.OVERVIEW.CREDITS.UNIT') }}
          </span>
          <span
            v-if="trend"
            class="text-sm font-medium tabular-nums text-n-slate-11"
          >
            {{ trend }}
          </span>
        </div>
      </div>
      <div class="flex items-center gap-2 mt-1">
        <span class="rounded-full size-2.5 bg-n-brand" />
        <span class="text-xs text-n-slate-11">
          {{ $t('CAPTAIN.OVERVIEW.CREDITS.LEGEND') }}
        </span>
      </div>
    </div>

    <div class="flex flex-col justify-end flex-1">
      <div class="flex items-end flex-1 gap-1 min-h-24">
        <div
          v-for="bar in bars"
          :key="bar.key"
          v-tooltip="
            `${formatDate(bar.key)} · ${bar.value} ${$t('CAPTAIN.OVERVIEW.CREDITS.UNIT')}`
          "
          class="flex-1 rounded-t transition-colors bg-n-brand hover:bg-n-brand/70"
          :style="{ height: `${bar.height}%` }"
        />
      </div>
      <div class="flex items-center justify-between mt-3">
        <span class="text-xs text-n-slate-10">{{ axisStart }}</span>
        <span class="text-xs text-n-slate-10">{{ axisEnd }}</span>
      </div>
    </div>
  </section>
</template>
