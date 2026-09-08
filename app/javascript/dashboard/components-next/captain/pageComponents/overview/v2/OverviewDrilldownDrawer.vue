<script setup>
import { onMounted, onBeforeUnmount, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import CaptainAssistantStats from 'dashboard/api/captain/assistantStats';
import { useReportDrilldown } from 'dashboard/routes/dashboard/settings/reports/composables/useReportDrilldown';
import ReportDrilldownCard from 'dashboard/routes/dashboard/settings/reports/components/ReportDrilldownCard.vue';
import SidePanel from 'dashboard/components-next/side-panel/SidePanel.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import MetricHint from '../MetricHint.vue';
import { DRILLDOWN_METRICS } from './drilldownMetrics';

const props = defineProps({
  assistantId: { type: [String, Number], required: true },
  metric: { type: Object, required: true },
  range: { type: String, required: true },
});
const emit = defineEmits(['close']);
const { t, locale } = useI18n();
const panel = ref(null);
const {
  records,
  meta,
  isFetching,
  isFetchingMore,
  hasError,
  hasRecords,
  hasMore,
  open,
  close,
  loadMore,
} = useReportDrilldown(params => CaptainAssistantStats.getDrilldown(params));

const fetchRecords = () =>
  open({
    assistantId: props.assistantId,
    metric: props.metric.key,
    reason: props.metric.reason,
    range: props.range,
  });

const formatStartedAt = timestamp =>
  new Intl.DateTimeFormat(locale.value, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(timestamp * 1000));

onMounted(() => {
  panel.value.open();
  fetchRecords();
});
onBeforeUnmount(close);
</script>

<template>
  <SidePanel
    ref="panel"
    :title="metric.label"
    width="xl"
    @close="close"
    @after-leave="emit('close')"
  >
    <template #header>
      <div class="flex flex-col gap-2 min-w-0">
        <div class="flex flex-wrap items-center gap-2">
          <h3 class="text-heading-2 text-n-slate-12">{{ metric.label }}</h3>
          <MetricHint
            :label="metric.label"
            :description="
              t(DRILLDOWN_METRICS[metric.key], { reason: metric.label })
            "
            :note="t('CAPTAIN.OVERVIEW.V2.DRILLDOWN.EPISODES_HINT')"
          />
        </div>
        <span class="text-heading-1 tabular-nums text-n-slate-12">
          {{ metric.value }}
        </span>
        <span
          v-if="!isFetching && !hasError"
          class="text-body-main text-n-slate-11"
        >
          {{
            t('CAPTAIN.OVERVIEW.V2.DRILLDOWN.COUNT', {
              count: meta.total_count ?? 0,
            })
          }}
        </span>
      </div>
    </template>

    <div v-if="isFetching" class="flex h-40 items-center justify-center">
      <Spinner />
    </div>
    <div v-else class="flex flex-col gap-3">
      <ReportDrilldownCard
        v-for="record in records"
        :key="record.episode_id"
        :record="record"
      >
        <template #timestamp>
          <span
            v-tooltip="
              t('CAPTAIN.OVERVIEW.V2.DRILLDOWN.STARTED_AT', {
                time: formatStartedAt(record.episode_started_at),
              })
            "
            class="text-label-small text-n-slate-10"
          >
            {{ formatStartedAt(record.episode_started_at) }}
          </span>
        </template>
      </ReportDrilldownCard>
      <div v-if="hasError" class="flex flex-col items-center gap-3 py-5">
        <p class="m-0 text-body-main text-n-ruby-11">
          {{ t('CAPTAIN.OVERVIEW.DRILLDOWN.ERROR') }}
        </p>
        <Button
          slate
          faded
          :label="t('CAPTAIN.OVERVIEW.V2.DRILLDOWN.RETRY')"
          @click="hasRecords ? loadMore() : fetchRecords()"
        />
      </div>
      <p
        v-else-if="!hasRecords"
        class="py-10 text-center text-body-main text-n-slate-11"
      >
        {{ t('CAPTAIN.OVERVIEW.DRILLDOWN.EMPTY') }}
      </p>
      <Button
        v-else-if="hasMore"
        slate
        faded
        class="mx-auto"
        :label="t('CAPTAIN.OVERVIEW.DRILLDOWN.LOAD_MORE')"
        :is-loading="isFetchingMore"
        @click="loadMore"
      />
    </div>
  </SidePanel>
</template>
