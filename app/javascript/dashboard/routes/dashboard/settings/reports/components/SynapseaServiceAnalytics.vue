<script setup>
import { computed, onMounted } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { formatTime } from '@chatwoot/utils';

const store = useStore();
const accountSummary = useMapGetter('getAccountSummary');
const agentConversationMetric = useMapGetter('getAgentConversationMetric');
const inboxes = useMapGetter('inboxes/getInboxes');

const avgResponseTime = computed(() =>
  formatTime(accountSummary.value?.avg_first_response_time || 0)
);

const leadConversions = computed(
  () => accountSummary.value?.resolutions_count || 0
);

const topAgentPerformance = computed(() => {
  const metricList = agentConversationMetric.value || [];
  if (!metricList.length) return 0;

  return metricList.reduce(
    (maxValue, item) => Math.max(maxValue, item?.value || 0),
    0
  );
});

const topContactOrigin = computed(() => {
  const channelCount = (inboxes.value || []).reduce((acc, inbox) => {
    const key = inbox.channel_type || 'unknown';
    acc[key] = (acc[key] || 0) + 1;
    return acc;
  }, {});

  const [topChannel] = Object.entries(channelCount).sort(
    ([, a], [, b]) => b - a
  );

  if (!topChannel) return '—';
  return topChannel[0];
});

onMounted(() => {
  store.dispatch('fetchAgentConversationMetric');
  store.dispatch('inboxes/get');
});
</script>

<template>
  <section class="mt-4 rounded-xl border border-n-weak bg-n-solid-2 p-4">
    <header class="mb-3">
      <h3 class="m-0 text-sm font-medium text-n-slate-12">
        {{ $t('REPORT.SYNAPSEA_ANALYTICS.TITLE') }}
      </h3>
      <p class="m-0 text-xs text-n-slate-11">
        {{ $t('REPORT.SYNAPSEA_ANALYTICS.DESCRIPTION') }}
      </p>
    </header>
    <div class="grid grid-cols-1 gap-2 md:grid-cols-2 xl:grid-cols-4">
      <article class="rounded-lg bg-n-alpha-2 p-3">
        <p class="m-0 text-xs text-n-slate-11">
          {{ $t('REPORT.SYNAPSEA_ANALYTICS.AVG_RESPONSE_TIME') }}
        </p>
        <p class="m-0 text-base font-medium text-n-slate-12">
          {{ avgResponseTime }}
        </p>
      </article>
      <article class="rounded-lg bg-n-alpha-2 p-3">
        <p class="m-0 text-xs text-n-slate-11">
          {{ $t('REPORT.SYNAPSEA_ANALYTICS.LEAD_CONVERSIONS') }}
        </p>
        <p class="m-0 text-base font-medium text-n-slate-12">
          {{ leadConversions }}
        </p>
      </article>
      <article class="rounded-lg bg-n-alpha-2 p-3">
        <p class="m-0 text-xs text-n-slate-11">
          {{ $t('REPORT.SYNAPSEA_ANALYTICS.AGENT_PERFORMANCE') }}
        </p>
        <p class="m-0 text-base font-medium text-n-slate-12">
          {{ topAgentPerformance }}
        </p>
      </article>
      <article class="rounded-lg bg-n-alpha-2 p-3">
        <p class="m-0 text-xs text-n-slate-11">
          {{ $t('REPORT.SYNAPSEA_ANALYTICS.CONTACT_ORIGIN') }}
        </p>
        <p class="m-0 text-base font-medium capitalize text-n-slate-12">
          {{ topContactOrigin }}
        </p>
      </article>
    </div>
  </section>
</template>
