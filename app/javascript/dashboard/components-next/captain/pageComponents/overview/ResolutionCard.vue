<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  // Four header stats: { key, label, value, trend, trendGood, metric? }.
  // Entries with `metric` support drilldown when `clickable` is set.
  stats: { type: Array, required: true },
  // Cohort flow from outcome_metrics: where every conversation Captain worked
  // in the window stands now. See AssistantOutcomeStatsBuilder#resolution_flow.
  flow: { type: Object, default: null },
  loading: { type: Boolean, default: false },
  clickable: { type: Boolean, default: false },
});

const emit = defineEmits(['drilldown']);

const { t, te } = useI18n();

const VIEW_W = 760;
const BAR_W = 6;
const COL_X = [0, 330, 580];
const USABLE_H = 190;
const NODE_GAP = 12;
const PAD_TOP = 8;
const MIN_NODE_H = 4;

const COLOR_CLASSES = {
  teal: 'text-n-teal-9',
  amber: 'text-n-amber-9',
  blue: 'text-n-blue-9',
  ruby: 'text-n-ruby-9',
  slate: 'text-n-slate-8',
};

const nodeLabel = key => t(`CAPTAIN.OVERVIEW.RESOLUTION_FLOW.NODES.${key}`);

const reasonLabel = category => {
  const key = `CAPTAIN.OVERVIEW.HANDOFF_REASONS.CATEGORIES.${category}`;
  return te(key) ? t(key) : category;
};

// The middle column partitions the handled cohort; the right column fans out
// the captain-resolved and handed-off branches.
const flowNodes = computed(() => {
  const flow = props.flow;
  if (!flow?.handled) return null;

  const captain = flow.captain_resolved ?? {};
  const handed = flow.handed_to_team ?? {};
  // Top 2 reasons keep their own branch; the tail folds into "Other" so the
  // fan-out stays readable regardless of how many categories fired.
  const sortedReasons = Object.entries(handed.reasons ?? {}).sort(
    ([, a], [, b]) => b - a
  );
  const topReasons = sortedReasons.slice(0, 2);
  const otherTotal = sortedReasons
    .slice(2)
    .reduce((sum, [, value]) => sum + value, 0);
  const reasons = topReasons.map(([category, value]) => ({
    key: `reason-${category}`,
    value,
    color: 'amber',
    label: reasonLabel(category),
  }));
  if (otherTotal > 0) {
    reasons.push({
      key: 'reason-other',
      value: otherTotal,
      color: 'amber',
      label: nodeLabel('OTHER'),
    });
  }

  return [
    {
      key: 'captain',
      value: captain.total ?? 0,
      color: 'teal',
      label: nodeLabel('CAPTAIN'),
      children: [
        {
          key: 'stayed',
          value: captain.stayed_closed ?? 0,
          color: 'teal',
          label: nodeLabel('STAYED'),
        },
        {
          key: 'reopened',
          value: captain.reopened ?? 0,
          color: 'ruby',
          label: nodeLabel('REOPENED'),
        },
      ].filter(child => child.value > 0),
    },
    {
      key: 'handed',
      value: handed.total ?? 0,
      color: 'amber',
      label: nodeLabel('HANDED'),
      children: reasons,
    },
    {
      key: 'team',
      value: flow.team_resolved ?? 0,
      color: 'blue',
      label: nodeLabel('TEAM'),
      children: [],
    },
    {
      key: 'open',
      value: flow.still_open ?? 0,
      color: 'slate',
      label: nodeLabel('OPEN'),
      children: [],
    },
  ].filter(node => node.value > 0);
});

const ribbon = (x0, y0, h0, x1, y1, h1) => {
  const xm = (x0 + x1) / 2;
  return (
    `M ${x0} ${y0} C ${xm} ${y0} ${xm} ${y1} ${x1} ${y1} ` +
    `L ${x1} ${y1 + h1} C ${xm} ${y1 + h1} ${xm} ${y0 + h0} ${x0} ${y0 + h0} Z`
  );
};

const layout = computed(() => {
  const mids = flowNodes.value;
  if (!mids) return null;

  const scale = value =>
    Math.max((value * USABLE_H) / props.flow.handled, MIN_NODE_H);
  const nodes = [];
  const links = [];

  // Middle column: node height is the sum of its fan-out so ribbons stay
  // contiguous inside the node.
  let midY = PAD_TOP;
  mids.forEach(mid => {
    mid.h = mid.children.length
      ? mid.children.reduce((sum, child) => sum + scale(child.value), 0)
      : scale(mid.value);
    mid.y = midY;
    midY += mid.h + NODE_GAP;
    nodes.push({ ...mid, x: COL_X[1] });
  });

  // Source node spans the middle column contiguously.
  const handledH = mids.reduce((sum, mid) => sum + mid.h, 0);
  nodes.push({
    key: 'handled',
    x: COL_X[0],
    y: PAD_TOP,
    h: handledH,
    color: 'slate',
    label: nodeLabel('HANDLED'),
    value: props.flow.handled,
  });

  let sourceOffset = PAD_TOP;
  mids.forEach(mid => {
    links.push({
      key: `handled-${mid.key}`,
      color: mid.color,
      d: ribbon(COL_X[0] + BAR_W, sourceOffset, mid.h, COL_X[1], mid.y, mid.h),
    });
    sourceOffset += mid.h;
  });

  // Right column: children stacked in branch order.
  let rightY = PAD_TOP;
  mids.forEach(mid => {
    let childOffset = mid.y;
    mid.children.forEach(child => {
      const h = scale(child.value);
      nodes.push({ ...child, x: COL_X[2], y: rightY, h });
      links.push({
        key: `${mid.key}-${child.key}`,
        color: child.color,
        d: ribbon(COL_X[1] + BAR_W, childOffset, h, COL_X[2], rightY, h),
      });
      childOffset += h;
      rightY += h + NODE_GAP;
    });
  });

  const height = Math.max(midY, rightY, PAD_TOP + handledH) + PAD_TOP;
  return { nodes, links, height };
});

const onStatClick = stat => {
  if (props.clickable && stat.metric) emit('drilldown', stat);
};
</script>

<template>
  <div
    class="flex flex-col gap-6 p-5 border rounded-xl bg-n-solid-1 border-n-weak"
  >
    <div class="grid grid-cols-2 gap-4 lg:grid-cols-4">
      <div
        v-for="stat in stats"
        :key="stat.key"
        class="flex flex-col gap-1 rounded-lg"
        :class="
          clickable && stat.metric
            ? 'cursor-pointer transition-colors hover:bg-n-slate-2/50 focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-brand'
            : ''
        "
        :role="clickable && stat.metric ? 'button' : undefined"
        :tabindex="clickable && stat.metric ? 0 : undefined"
        @click="onStatClick(stat)"
        @keydown.enter.self.prevent="onStatClick(stat)"
        @keydown.space.self.prevent="onStatClick(stat)"
      >
        <span class="text-sm font-medium text-n-slate-11">{{
          stat.label
        }}</span>
        <div
          v-if="loading"
          class="w-16 h-7 rounded bg-n-slate-3 animate-pulse"
        />
        <div v-else class="flex items-baseline gap-1.5">
          <span
            class="text-2xl font-semibold tracking-tight tabular-nums text-n-slate-12"
          >
            {{ stat.value }}
          </span>
          <span v-if="stat.suffix" class="text-sm tabular-nums text-n-slate-10">
            {{ stat.suffix }}
          </span>
          <span
            v-if="stat.trend"
            class="text-xs font-medium tabular-nums"
            :class="
              stat.trendGood === null
                ? 'text-n-slate-11'
                : stat.trendGood
                  ? 'text-n-teal-11'
                  : 'text-n-ruby-11'
            "
          >
            {{ stat.trend }}
          </span>
        </div>
      </div>
    </div>

    <div v-if="loading" class="h-48 rounded bg-n-slate-3 animate-pulse" />

    <span v-else-if="!layout" class="text-sm text-n-slate-10">
      {{ $t('CAPTAIN.OVERVIEW.RESOLUTION_FLOW.EMPTY') }}
    </span>

    <svg
      v-else
      :viewBox="`0 0 ${VIEW_W} ${layout.height}`"
      class="w-full h-auto"
      role="img"
      :aria-label="$t('CAPTAIN.OVERVIEW.RESOLUTION_FLOW.NODES.HANDLED')"
    >
      <path
        v-for="link in layout.links"
        :key="link.key"
        :d="link.d"
        class="fill-current opacity-20"
        :class="COLOR_CLASSES[link.color]"
      />
      <g v-for="node in layout.nodes" :key="node.key">
        <rect
          :x="node.x"
          :y="node.y"
          :width="BAR_W"
          :height="node.h"
          rx="2"
          class="fill-current"
          :class="COLOR_CLASSES[node.color]"
        />
        <text
          :x="node.x + BAR_W + 8"
          :y="node.y + Math.max(node.h / 2, 6) + 4"
          font-size="11"
          class="fill-current text-n-slate-11"
        >
          {{ node.label }} · {{ node.value.toLocaleString() }}
        </text>
      </g>
    </svg>
  </div>
</template>
