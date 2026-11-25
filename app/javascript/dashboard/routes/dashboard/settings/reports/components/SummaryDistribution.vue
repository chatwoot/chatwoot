<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import {
  conversationsLabel,
  metricHintKey,
} from '../helpers/conversationMetrics';

const props = defineProps({
  // 'agent' | 'inbox' | 'team'. Labels are left out on purpose: a conversation
  // carries several of them, so the shares would add up past the total.
  type: {
    type: String,
    required: true,
  },
  // [{ id, name, conversationsCount, resolvedConversationsCount,
  // handledConversationsCount }] with the raw numbers, already narrowed by
  // whatever filter the table is showing.
  rows: {
    type: Array,
    default: () => [],
  },
  // Distinct handled conversations in the period. Two agents replying to the same
  // conversation both count it, so on agents the rows add up past this number.
  handledTotal: {
    type: Number,
    default: null,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const router = useRouter();
const { t, locale } = useI18n();

// Past this the card stops being a summary and starts competing with the table
// below it, so the rest is aggregated into a single row.
const MAX_ROWS = 10;

const METRICS = computed(() => [
  {
    key: 'resolvedConversationsCount',
    labelKey: 'REPORT.DISTRIBUTION.METRIC.RESOLUTIONS',
    hintKey: metricHintKey('resolved', props.type),
  },
  {
    key: 'handledConversationsCount',
    labelKey: 'REPORT.DISTRIBUTION.METRIC.HANDLED',
    hintKey: metricHintKey('handled', props.type),
    overlaps: props.type === 'agent',
  },
  {
    key: 'conversationsCount',
    labelKey: `REPORT.DISTRIBUTION.METRIC.${conversationsLabel(props.type)}`,
    hintKey: metricHintKey('conversations', props.type),
  },
]);

const activeMetricIndex = ref(0);
const activeMetric = computed(() => METRICS.value[activeMetricIndex.value]);

const tabs = computed(() =>
  METRICS.value.map((metric, index) => ({ index, label: t(metric.labelKey) }))
);

const onTabChange = tab => {
  activeMetricIndex.value = tab.index;
};

const rankBy = metricKey =>
  props.rows
    .map(row => ({
      id: row.id,
      name: row.name,
      value: Number(row[metricKey]) || 0,
    }))
    .filter(row => row.value > 0)
    .sort((a, b) => b.value - a.value);

const rankedRows = computed(() => rankBy(activeMetric.value.key));

const rowsTotal = computed(() =>
  rankedRows.value.reduce((sum, row) => sum + row.value, 0)
);

// Where rows overlap, the share is of the distinct conversations: "took part in
// 40% of the handled conversations", which is why the shares can pass 100%.
const total = computed(() =>
  activeMetric.value.overlaps && props.handledTotal !== null
    ? props.handledTotal
    : rowsTotal.value
);

const segments = computed(() => {
  const head = rankedRows.value.slice(0, MAX_ROWS);
  const tail = rankedRows.value.slice(MAX_ROWS);
  const tailValue = tail.reduce((sum, row) => sum + row.value, 0);

  // The aggregated tail can outgrow the biggest single row, so it takes part in
  // the scale instead of running past the end of the track.
  const max = Math.max(head[0]?.value ?? 0, tailValue);
  const barWidth = value =>
    max ? `${Math.max((value / max) * 100, 2)}%` : '0%';

  const rows = head.map(row => ({
    ...row,
    linked: true,
    barClass: 'bg-n-blue-9',
    width: barWidth(row.value),
  }));

  if (!tail.length) return rows;

  // The tail is one row, not a footnote: the reader still wants to know how much
  // of the total sits outside the top of the list.
  return [
    ...rows,
    {
      id: 'tail',
      name: t('REPORT.DISTRIBUTION.OTHERS', { count: tail.length }),
      value: tailValue,
      linked: false,
      barClass: 'bg-n-slate-8',
      width: barWidth(tailValue),
    },
  ];
});

// vue-i18n carries locales as pt_BR, Intl wants pt-BR.
const bcp47Locale = computed(() => locale.value.replace(/_/g, '-'));

const formatCount = value => value.toLocaleString(bcp47Locale.value);

const percentageFormatter = computed(
  () =>
    new Intl.NumberFormat(bcp47Locale.value, {
      style: 'percent',
      maximumFractionDigits: 1,
    })
);

const formatShare = value =>
  total.value ? percentageFormatter.value.format(value / total.value) : '';

// One row is not a distribution: a single full-width bar says nothing the table
// does not already say.
const hasMetricData = computed(() => rankedRows.value.length > 1);

// Visibility follows every metric, not the selected one. Tying it to the
// selection means picking a metric with no activity takes the tabs down with the
// card, and nothing is left to switch back with.
const hasData = computed(() =>
  METRICS.value.some(metric => rankBy(metric.key).length > 1)
);

const openRow = segment => {
  if (!segment.linked) return;
  router.push({
    name: `${props.type}_reports_show`,
    params: { id: segment.id },
  });
};
</script>

<template>
  <div
    v-if="isLoading || hasData"
    class="px-6 py-5 mt-5 shadow outline-1 outline outline-n-container rounded-xl bg-n-solid-2"
  >
    <div class="flex flex-wrap items-start justify-between gap-3">
      <div>
        <h3 class="mb-0 text-sm font-medium text-n-slate-12">
          {{ $t(`REPORT.DISTRIBUTION.TITLE.${type.toUpperCase()}`) }}
        </h3>
        <p class="max-w-xl mt-1 mb-0 text-xs text-n-slate-10">
          {{ $t(activeMetric.hintKey) }}
          <template v-if="activeMetric.overlaps">
            {{ $t('REPORT.DISTRIBUTION.HANDLED_SHARE') }}
          </template>
        </p>
      </div>
      <TabBar
        :tabs="tabs"
        :initial-active-tab="activeMetricIndex"
        @tab-changed="onTabChange"
      />
    </div>

    <div v-if="isLoading" class="flex flex-col gap-3 mt-6">
      <div class="w-11/12 h-5 rounded bg-n-slate-3 animate-pulse" />
      <div class="w-9/12 h-5 rounded bg-n-slate-3 animate-pulse" />
      <div class="w-7/12 h-5 rounded bg-n-slate-3 animate-pulse" />
      <div class="w-5/12 h-5 rounded bg-n-slate-3 animate-pulse" />
    </div>

    <p
      v-else-if="!hasMetricData"
      class="py-8 mb-0 text-sm text-center text-n-slate-11"
    >
      {{ $t('REPORT.DISTRIBUTION.EMPTY_METRIC') }}
    </p>

    <template v-else>
      <div class="flex items-baseline gap-2 mt-4">
        <span class="text-2xl font-semibold tabular-nums text-n-slate-12">
          {{ formatCount(total) }}
        </span>
        <span class="text-sm text-n-slate-10">
          {{ $t(activeMetric.labelKey).toLowerCase() }}
        </span>
      </div>

      <ul class="flex flex-col gap-0.5 mt-3 mb-0 list-none">
        <li v-for="segment in segments" :key="segment.id">
          <component
            :is="segment.linked ? 'button' : 'div'"
            :type="segment.linked ? 'button' : undefined"
            class="grid items-center w-full grid-cols-[minmax(0,1fr)_3rem_3.25rem] sm:grid-cols-[minmax(5rem,11rem)_minmax(0,1fr)_3rem_3.25rem] gap-4 px-2 py-1.5 -mx-2 text-left rounded-lg"
            :class="segment.linked ? 'hover:bg-n-alpha-1' : 'cursor-default'"
            @click="openRow(segment)"
          >
            <span
              class="text-sm truncate"
              :class="segment.linked ? 'text-n-slate-12' : 'text-n-slate-10'"
            >
              {{ segment.name }}
            </span>
            <span
              class="hidden h-2 overflow-hidden rounded-full sm:block bg-n-alpha-1"
            >
              <!-- data-driven width, the one thing a utility class cannot carry -->
              <span
                class="block h-2 rounded-full"
                :class="segment.barClass"
                :style="{ width: segment.width }"
              />
            </span>
            <span class="text-sm text-right tabular-nums text-n-slate-11">
              {{ formatCount(segment.value) }}
            </span>
            <span
              class="text-sm font-medium text-right tabular-nums text-n-slate-12"
            >
              {{ formatShare(segment.value) }}
            </span>
          </component>
        </li>
      </ul>
    </template>
  </div>
</template>
