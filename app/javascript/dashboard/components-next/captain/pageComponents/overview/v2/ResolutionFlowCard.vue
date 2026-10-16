<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { SankeyChart } from '@chatwoot/viz';
import OverviewPanel from './OverviewPanel.vue';

const props = defineProps({
  flow: { type: Object, default: null },
  loading: { type: Boolean, default: false },
});

const { t } = useI18n();

const FLOW_NODE_LABELS = {
  conversations_handled: 'HANDLED',
  resolved_by_captain: 'RESOLVED_BY_CAPTAIN',
  handed_off: 'HANDED_OFF',
  closed_with_team: 'CLOSED_WITH_TEAM',
  reopened_within_7_days: 'REOPENED',
  stayed_closed: 'STAYED_CLOSED',
  other_reasons: 'OTHER_REASONS',
};

const REASON_LABELS = {
  customer_request: 'CUSTOMER_REQUEST',
  missing_knowledge: 'MISSING_KNOWLEDGE',
  unsupported_request: 'UNSUPPORTED_REQUEST',
  policy_restriction: 'POLICY_RESTRICTION',
  tool_failure: 'TOOL_FAILURE',
  pending_clarification: 'PENDING_CLARIFICATION',
  usage_limit: 'USAGE_LIMIT',
  unclassified: 'UNCLASSIFIED',
};

const FLOW_NODE_COLORS = {
  conversations_handled: 'rgb(var(--iris-9))',
  resolved_by_captain: 'rgb(var(--teal-9))',
  stayed_closed: 'rgb(var(--teal-9))',
  reopened_within_7_days: 'rgb(var(--ruby-9))',
  closed_with_team: 'rgb(var(--slate-8))',
};
const DEFAULT_FLOW_NODE_COLOR = 'rgb(var(--amber-9))';

const reasonLabel = category =>
  t(
    `CAPTAIN.OVERVIEW.V2.HANDOFF_REASONS.${REASON_LABELS[category] || 'UNCLASSIFIED'}`
  );

const nodeLabel = id => {
  if (id.startsWith('handoff_reason_')) {
    return reasonLabel(id.replace('handoff_reason_', ''));
  }
  return t(
    `CAPTAIN.OVERVIEW.V2.RESOLUTION_FLOW.NODES.${FLOW_NODE_LABELS[id] || 'OTHER_REASONS'}`
  );
};

const nodeColor = id => FLOW_NODE_COLORS[id] || DEFAULT_FLOW_NODE_COLOR;

const chartData = computed(() => {
  const sankey = props.flow?.sankey;
  if (!sankey) return { nodes: [], links: [] };

  const links = sankey.links.filter(link => Number(link.value) > 0);
  const connectedNodeIds = new Set(
    links.flatMap(link => [String(link.source), String(link.target)])
  );
  const nodes = sankey.nodes
    .map(node => ({
      ...node,
      id: String(node.id),
      label: nodeLabel(String(node.id)),
      color: nodeColor(String(node.id)),
    }))
    .filter(node => connectedNodeIds.has(node.id));

  return { nodes, links };
});

const distribution = computed(() => props.flow?.handoff_distribution || []);
const hasData = computed(() => chartData.value.links.length > 0);
const formatCount = value => Number(value).toLocaleString();
</script>

<template>
  <OverviewPanel>
    <div
      class="flex flex-col min-w-0 gap-5 p-5 lg:flex-row lg:items-center lg:justify-between lg:gap-0"
    >
      <div class="w-full min-w-0 lg:w-[47.1875rem]">
        <div
          v-if="loading"
          class="h-[16.25rem] rounded-lg bg-n-slate-3 animate-pulse"
        />
        <SankeyChart
          v-else-if="hasData"
          :data="chartData"
          :format-value="formatCount"
          :height="260"
          :node-padding="24"
          show-label-background
          :aria-label="$t('CAPTAIN.OVERVIEW.V2.RESOLUTION_FLOW.ARIA_LABEL')"
          class="[--cw-viz-sankey-label-color:rgb(var(--slate-11))] [--cw-viz-sankey-label-value-color:rgb(var(--slate-12))] [--cw-viz-sankey-label-background:rgb(var(--slate-1))] [--cw-viz-sankey-label-border-color:rgb(var(--slate-4))] [--cw-viz-sankey-label-font-size:0.75rem] [&_.cw-viz-sankey__label-background--terminal]:fill-[rgb(var(--card-color))] [&_.cw-viz-sankey__label-text]:font-[440] [&_.cw-viz-sankey__label-text]:tracking-[-0.015rem] [&_.cw-viz-sankey__label-value]:font-[440] [&_.cw-viz-sankey__label-value]:tracking-[-0.015rem]"
        />
        <div
          v-else
          class="grid h-[16.25rem] text-body-main place-content-center text-n-slate-11"
        >
          {{ $t('CAPTAIN.OVERVIEW.V2.EMPTY') }}
        </div>
      </div>
      <div
        class="flex flex-col justify-center w-full gap-3 lg:self-stretch lg:w-[18.375rem] lg:pl-4 lg:pr-2"
      >
        <h2 class="text-heading-3 text-n-slate-12">
          {{ $t('CAPTAIN.OVERVIEW.V2.HANDOFF_REASONS.TITLE') }}
        </h2>
        <div v-if="loading" class="flex flex-col gap-2.5">
          <div
            v-for="index in 6"
            :key="index"
            class="h-[1.3125rem] rounded bg-n-slate-3 animate-pulse"
          />
        </div>
        <ul v-else-if="distribution.length" class="flex flex-col gap-2.5">
          <li
            v-for="reason in distribution"
            :key="reason.category"
            class="flex items-center w-full gap-4"
          >
            <span
              class="flex-1 min-w-0 truncate text-body-main text-n-slate-11"
            >
              {{ reasonLabel(reason.category) }}
            </span>
            <span class="flex items-center gap-1 tabular-nums shrink-0">
              <span class="text-button text-n-slate-12">
                {{ reason.count.toLocaleString() }}
              </span>
              <span class="w-11 text-center text-label-small text-n-slate-11">
                {{
                  $t('CAPTAIN.OVERVIEW.V2.HANDOFF_REASONS.PERCENTAGE', {
                    value: reason.percentage,
                  })
                }}
              </span>
            </span>
          </li>
        </ul>
        <p v-else class="text-body-main text-n-slate-11">
          {{ $t('CAPTAIN.OVERVIEW.V2.EMPTY') }}
        </p>
      </div>
    </div>
  </OverviewPanel>
</template>
