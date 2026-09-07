<script setup>
import { computed, ref } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { BarChart, LineChart } from '@chatwoot/viz';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import OverviewPanel from './OverviewPanel.vue';

const props = defineProps({
  trend: { type: Object, default: null },
  loading: { type: Boolean, default: false },
});

const { t, locale } = useI18n();
const [showDropdown, toggleDropdown] = useToggle();

const selectedMeasure = ref('conversation_count');

const formatDate = value =>
  new Intl.DateTimeFormat(locale.value, {
    month: 'short',
    day: '2-digit',
  }).format(new Date(`${value}T00:00:00`));

const formatDay = value =>
  new Intl.DateTimeFormat(locale.value, {
    day: '2-digit',
  }).format(new Date(`${value}T00:00:00`));

const bucketLabel = bucket => {
  const start = formatDate(bucket.starts_on);
  const end = formatDate(bucket.ends_on);
  const startsOn = new Date(`${bucket.starts_on}T00:00:00`);
  const endsOn = new Date(`${bucket.ends_on}T00:00:00`);
  const sameMonth =
    startsOn.getFullYear() === endsOn.getFullYear() &&
    startsOn.getMonth() === endsOn.getMonth();

  return start === end
    ? start
    : `${start} - ${sameMonth ? formatDay(bucket.ends_on) : end}`;
};

const countChartData = computed(() => {
  const buckets = props.trend?.buckets || [];
  return {
    categories: buckets.map(bucketLabel),
    series: [
      {
        id: 'handled',
        label: t('CAPTAIN.OVERVIEW.V2.RESOLUTION_TREND.HANDLED'),
        color: 'rgb(var(--slate-7))',
        pointBorderColor: 'rgb(var(--card-color))',
        valueColor: 'rgb(var(--slate-10))',
        data: buckets.map(bucket => bucket.conversations_handled),
      },
      {
        id: 'resolved',
        label: t('CAPTAIN.OVERVIEW.V2.RESOLUTION_TREND.RESOLVED'),
        color: 'rgb(var(--teal-9))',
        pointBorderColor: 'rgb(var(--card-color))',
        valueColor: 'rgb(var(--teal-11))',
        data: buckets.map(bucket => bucket.resolved_by_captain),
      },
    ],
  };
});

const rateChartData = computed(() => ({
  categories: (props.trend?.buckets || []).map(bucketLabel),
  series: [
    {
      id: 'current_resolution_rate',
      label: t('CAPTAIN.OVERVIEW.V2.RESOLUTION_TREND.CURRENT_PERIOD'),
      color: 'rgb(var(--teal-9))',
      valueColor: 'rgb(var(--teal-11))',
      data: (props.trend?.buckets || []).map(
        bucket => bucket.current_resolution_rate ?? undefined
      ),
    },
    {
      id: 'previous_resolution_rate',
      label: t('CAPTAIN.OVERVIEW.V2.RESOLUTION_TREND.PREVIOUS_PERIOD'),
      color: 'rgb(var(--slate-7))',
      valueColor: 'rgb(var(--slate-10))',
      data: (props.trend?.buckets || []).map(
        bucket => bucket.previous_resolution_rate ?? undefined
      ),
    },
  ],
}));

const measureOptions = computed(() =>
  [
    {
      value: 'conversation_count',
      label: t('CAPTAIN.OVERVIEW.V2.RESOLUTION_TREND.CONVERSATION_COUNT'),
    },
    {
      value: 'resolution_rate',
      label: t('CAPTAIN.OVERVIEW.V2.RESOLUTION_TREND.RESOLUTION_RATE'),
    },
  ].map(option => ({
    ...option,
    action: 'select',
    isSelected: option.value === selectedMeasure.value,
  }))
);

const selectedMeasureLabel = computed(
  () => measureOptions.value.find(option => option.isSelected)?.label || ''
);

const hasCountData = computed(() => countChartData.value.categories.length > 0);
const hasRateData = computed(() =>
  rateChartData.value.series.some(series =>
    series.data.some(value => Number.isFinite(value))
  )
);
const formatCount = value => Number(value).toLocaleString();
const formatRate = value => `${Number(value).toFixed(1)}%`;

const selectMeasure = ({ value }) => {
  selectedMeasure.value = value;
  toggleDropdown(false);
};
</script>

<template>
  <OverviewPanel :title="$t('CAPTAIN.OVERVIEW.V2.RESOLUTION_TREND.TITLE')">
    <template #actions>
      <div
        v-on-click-outside="() => toggleDropdown(false)"
        class="relative flex items-center"
      >
        <Button
          sm
          slate
          trailing-icon
          icon="i-lucide-chevron-down"
          :label="selectedMeasureLabel"
          @click="toggleDropdown()"
        />
        <DropdownMenu
          v-if="showDropdown"
          :menu-items="measureOptions"
          class="mt-1 min-w-48 end-0 top-full"
          @action="selectMeasure($event)"
        />
      </div>
    </template>
    <div class="min-w-0 px-5 pb-5 pt-8">
      <div
        v-if="loading"
        class="h-[14.5rem] rounded-lg bg-n-slate-3 animate-pulse"
      />
      <LineChart
        v-else-if="selectedMeasure === 'conversation_count' && hasCountData"
        :data="countChartData"
        :format-value="formatCount"
        :height="232"
        :point-radius="3"
        :aria-label="$t('CAPTAIN.OVERVIEW.V2.RESOLUTION_TREND.ARIA_LABEL')"
        class="[--cw-viz-line-label-color:rgb(var(--slate-11))] [--cw-viz-line-axis-color:rgb(var(--slate-4))] [--cw-viz-line-axis-font-size:0.75rem] [--cw-viz-line-value-font-size:0.75rem] [--cw-viz-line-width:0.0625rem] [--cw-viz-line-point-border-width:0.25rem] [--cw-viz-line-tooltip-background:rgb(var(--solid-2))] [--cw-viz-line-tooltip-color:rgb(var(--slate-12))] [--cw-viz-line-tooltip-border-color:rgb(var(--border-strong))] [&_.cw-viz-line__axis-label]:font-[440] [&_.cw-viz-line__axis-label]:tracking-[-0.015rem] [&_.cw-viz-line__value]:font-[440] [&_.cw-viz-line__value]:tracking-[-0.015rem]"
      />
      <BarChart
        v-else-if="selectedMeasure === 'resolution_rate' && hasRateData"
        :data="rateChartData"
        :format-value="formatRate"
        :height="232"
        :y-domain="[0, 100]"
        :y-step-size="20"
        :bar-radius="4"
        :bar-gap="4"
        :max-bar-width="32"
        :aria-label="$t('CAPTAIN.OVERVIEW.V2.RESOLUTION_TREND.RATE_ARIA_LABEL')"
        class="[--cw-viz-bar-label-color:rgb(var(--slate-11))] [--cw-viz-bar-axis-color:rgb(var(--slate-4))] [--cw-viz-bar-axis-font-size:0.75rem] [--cw-viz-bar-value-font-size:0.75rem] [--cw-viz-bar-tooltip-background:rgb(var(--solid-2))] [--cw-viz-bar-tooltip-color:rgb(var(--slate-12))] [--cw-viz-bar-tooltip-border-color:rgb(var(--border-strong))] [&_.cw-viz-bar__axis-label]:font-[440] [&_.cw-viz-bar__axis-label]:tracking-[-0.015rem] [&_.cw-viz-bar__value]:font-[440] [&_.cw-viz-bar__value]:tracking-[-0.015rem]"
      />
      <div
        v-else
        class="grid h-[14.5rem] text-body-main place-content-center text-n-slate-11"
      >
        {{ $t('CAPTAIN.OVERVIEW.V2.EMPTY') }}
      </div>
    </div>
  </OverviewPanel>
</template>
