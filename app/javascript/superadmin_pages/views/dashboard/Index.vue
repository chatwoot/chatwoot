<script setup>
import { computed, onMounted, ref } from 'vue';
import format from 'date-fns/format';
import parseISO from 'date-fns/parseISO';
import BarChart from 'shared/components/charts/BarChart.vue';

const props = defineProps({
  componentData: {
    type: Object,
    default: () => ({}),
  },
});

const CHART_COLOR = '#2781F6';
const CHART_HEIGHT = 300;
const BAR_MAX_WIDTH = 28;
const BAR_RADIUS = 6;
const Y_TICK_COUNT = 4;
const AXIS_DATE_FORMAT = 'd MMM';

const stats = ref(null);
const failed = ref(false);

const loading = computed(() => !stats.value && !failed.value);

onMounted(async () => {
  try {
    const response = await fetch(window.location.pathname, {
      headers: { Accept: 'application/json' },
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    stats.value = await response.json();
  } catch {
    failed.value = true;
  }
});

const metrics = computed(() => [
  {
    label: 'Accounts',
    value: stats.value?.accountsCount,
    icon: 'i-lucide-building-2',
    tone: 'bg-n-blue-3 text-n-blue-11',
    href: props.componentData.accountsPath,
  },
  {
    label: 'Users',
    value: stats.value?.usersCount,
    icon: 'i-lucide-users',
    tone: 'bg-n-iris-3 text-n-iris-11',
    href: props.componentData.usersPath,
  },
  {
    label: 'Inboxes',
    value: stats.value?.inboxesCount,
    icon: 'i-lucide-inbox',
    tone: 'bg-n-teal-3 text-n-teal-11',
  },
  {
    label: 'Conversations',
    value: stats.value?.conversationsCount,
    icon: 'i-lucide-messages-square',
    tone: 'bg-n-amber-3 text-n-amber-11',
  },
]);

const chartTitle = 'Conversations';
const chartCaption = 'Created per day over the last 30 days';
const chartAriaLabel = 'Conversations created by day';
const loadError =
  'Could not load the dashboard stats. Reload the page to try again.';

const chartData = computed(() => {
  const sourceData = stats.value?.chartData || [];
  return {
    categories: sourceData.map(([label]) =>
      format(parseISO(label), AXIS_DATE_FORMAT)
    ),
    series: [
      {
        id: 'conversations',
        label: 'Conversations',
        color: CHART_COLOR,
        data: sourceData.map(([, value]) => value),
      },
    ],
  };
});

// Whole-number steps, so a quiet installation does not get an axis of fractions.
const yStepSize = computed(() => {
  const counts = (stats.value?.chartData || []).map(([, value]) => value);
  return Math.max(1, Math.ceil(Math.max(0, ...counts) / Y_TICK_COUNT));
});

const chartSummary = computed(() => {
  const sourceData = stats.value?.chartData || [];
  if (!sourceData.length) return [];

  const total = sourceData.reduce((sum, [, value]) => sum + value, 0);
  const [busiestDay, busiestCount] = sourceData.reduce((busiest, day) =>
    day[1] > busiest[1] ? day : busiest
  );

  return [
    { label: 'Total', value: total.toLocaleString() },
    {
      label: 'Daily average',
      value: Math.round(total / sourceData.length).toLocaleString(),
    },
    {
      label: 'Busiest day',
      value: `${busiestCount.toLocaleString()} on ${format(parseISO(busiestDay), AXIS_DATE_FORMAT)}`,
    },
  ];
});
</script>

<template>
  <div class="flex flex-col gap-6 min-w-0">
    <dl
      class="grid grid-cols-2 gap-px overflow-hidden border lg:grid-cols-4 rounded-xl border-n-weak bg-n-weak"
    >
      <component
        :is="item.href ? 'a' : 'div'"
        v-for="item in metrics"
        :key="item.label"
        :href="item.href"
        class="flex flex-col gap-3 p-4 bg-n-solid-1"
        :class="{ 'hover:bg-n-solid-3': item.href }"
      >
        <dt class="flex items-center gap-2.5 text-body-main text-n-slate-11">
          <span
            class="grid rounded-lg size-8 place-items-center shrink-0"
            :class="item.tone"
          >
            <span class="size-4" :class="item.icon" />
          </span>
          {{ item.label }}
        </dt>
        <dd
          class="text-3xl font-semibold tracking-tight font-interDisplay tabular-nums text-n-slate-12"
        >
          <span
            v-if="loading"
            class="inline-block w-16 rounded h-8 bg-n-slate-3 animate-pulse"
          />
          <template v-else>{{ item.value || 'N/A' }}</template>
        </dd>
      </component>
    </dl>

    <section class="p-4 border rounded-xl border-n-weak bg-n-solid-1">
      <div class="flex flex-wrap items-start justify-between gap-x-8 gap-y-3">
        <div>
          <h2 class="text-heading-3 text-n-slate-12">{{ chartTitle }}</h2>
          <p class="text-label-small text-n-slate-11">{{ chartCaption }}</p>
        </div>
        <dl class="flex flex-wrap gap-x-8 gap-y-2">
          <div v-for="item in chartSummary" :key="item.label">
            <dt
              class="text-xs font-medium uppercase tracking-wider text-n-slate-10"
            >
              {{ item.label }}
            </dt>
            <dd
              class="text-base font-semibold font-interDisplay tabular-nums text-n-slate-12"
            >
              {{ item.value }}
            </dd>
          </div>
        </dl>
      </div>
      <div
        v-if="loading"
        class="mt-4 rounded-lg h-[18.75rem] bg-n-slate-3 animate-pulse"
      />
      <p
        v-else-if="failed"
        class="py-16 text-center text-body-main text-n-slate-11"
      >
        {{ loadError }}
      </p>
      <div v-else class="w-full min-w-0 mt-4">
        <BarChart
          class="![--cw-viz-bar-axis-color:transparent] ![--cw-viz-bar-axis-font-size:0.6875rem] ![--cw-viz-bar-label-color:rgb(var(--slate-10))]"
          :data="chartData"
          :height="CHART_HEIGHT"
          :max-bar-width="BAR_MAX_WIDTH"
          :bar-radius="BAR_RADIUS"
          :y-step-size="yStepSize"
          timeseries
          :aria-label="chartAriaLabel"
        />
      </div>
    </section>
  </div>
</template>
