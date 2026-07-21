<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  // The credit_usage stat from the overview stats endpoint:
  // { current, previous, trend, daily: [{ date, value }] }
  usage: { type: Object, default: null },
});

const { t } = useI18n();

const daily = computed(() => props.usage?.daily ?? []);

// Long ranges (90 days) get too many daily bars to read, so past this many
// days the series is bucketed into weeks.
const WEEKLY_THRESHOLD = 35;

const isWeekly = computed(() => daily.value.length > WEEKLY_THRESHOLD);

// One bucket per day, or per 7 consecutive days on long ranges (the last week
// may be partial and always includes today). A bucket is unrecorded (null)
// only when every day in it predates credit tracking.
const buckets = computed(() => {
  if (!isWeekly.value) {
    return daily.value.map(day => ({
      start: day.date,
      end: day.date,
      value: day.value,
    }));
  }

  const weeks = [];
  for (let i = 0; i < daily.value.length; i += 7) {
    const chunk = daily.value.slice(i, i + 7);
    const recorded = chunk.filter(day => day.value !== null);
    weeks.push({
      start: chunk[0].date,
      end: chunk[chunk.length - 1].date,
      value: recorded.length
        ? +recorded.reduce((sum, day) => sum + day.value, 0).toFixed(2)
        : null,
    });
  }
  return weeks;
});

// Bar heights as a percentage of the peak bucket, with a small floor so even
// the lowest one stays visible. Unrecorded buckets render as muted
// placeholder bars.
const bars = computed(() => {
  const max = Math.max(...buckets.value.map(bucket => bucket.value ?? 0), 0);
  return buckets.value.map(bucket => ({
    ...bucket,
    key: bucket.start,
    recorded: bucket.value !== null,
    height:
      max === 0 || bucket.value === null
        ? 6
        : Math.max(6, Math.round((bucket.value / max) * 100)),
  }));
});

const formatDate = date =>
  new Date(date).toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
  });

const barTooltip = bar => {
  const period =
    bar.start === bar.end
      ? formatDate(bar.start)
      : `${formatDate(bar.start)} – ${formatDate(bar.end)}`;
  const usage = bar.recorded
    ? `${bar.value} ${t('CAPTAIN.OVERVIEW.CREDITS.UNIT')}`
    : t('CAPTAIN.OVERVIEW.CREDITS.NO_DATA');
  return `${period} · ${usage}`;
};

const total = computed(() =>
  props.usage ? props.usage.current.toLocaleString() : '—'
);

const trend = computed(() => {
  if (!props.usage?.trend) return '';
  const sign = props.usage.trend > 0 ? '+' : '';
  return `${sign}${props.usage.trend}%`;
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
          {{
            isWeekly
              ? $t('CAPTAIN.OVERVIEW.CREDITS.LEGEND_WEEKLY')
              : $t('CAPTAIN.OVERVIEW.CREDITS.LEGEND')
          }}
        </span>
      </div>
    </div>

    <div class="flex flex-col justify-end flex-1">
      <div class="flex items-end flex-1 gap-1 min-h-24">
        <div
          v-for="bar in bars"
          :key="bar.key"
          v-tooltip="barTooltip(bar)"
          class="flex-1 rounded-t transition-colors"
          :class="
            bar.recorded
              ? 'bg-n-brand hover:bg-n-brand/70'
              : 'bg-n-alpha-2 hover:bg-n-alpha-3'
          "
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
