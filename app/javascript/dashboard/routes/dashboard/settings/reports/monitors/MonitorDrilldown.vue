<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import MonitorsAPI from 'dashboard/api/monitors';
import { useReportDrilldown } from '../composables/useReportDrilldown';
import ReportDrilldownCard from '../components/ReportDrilldownCard.vue';
import SidePanel from 'dashboard/components-next/side-panel/SidePanel.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  request: { type: Object, required: true },
  title: { type: String, required: true },
  count: { type: Number, required: true },
});
const emit = defineEmits(['close', 'changed']);
const { t } = useI18n();
const panel = ref(null);
const {
  records,
  isFetching,
  isFetchingMore,
  hasError,
  hasMore,
  open,
  close,
  loadMore,
} = useReportDrilldown(params =>
  MonitorsAPI.conversations(params).catch(error => {
    if (error.response?.status === 409) emit('changed');
    throw error;
  })
);

onMounted(() => {
  panel.value.open();
  open(props.request);
});
onBeforeUnmount(close);
</script>

<template>
  <SidePanel
    ref="panel"
    :title="title"
    :description="t('REPORT.DRILLDOWN.RESULT_COUNT_CONVERSATION', { count })"
    width="xl"
    @after-leave="emit('close')"
  >
    <div v-if="isFetching" class="flex justify-center py-20"><Spinner /></div>
    <p v-else-if="hasError" role="alert" class="text-n-ruby-11">
      {{ t('REPORT.DRILLDOWN.ERROR') }}
    </p>
    <p v-else-if="!records.length" class="text-n-slate-11">
      {{ t('REPORT.DRILLDOWN.EMPTY') }}
    </p>
    <div v-else class="flex flex-col gap-2">
      <ReportDrilldownCard
        v-for="record in records"
        :key="record.conversation.id"
        :record="record"
      />
      <Button
        v-if="hasMore"
        slate
        faded
        :label="t('REPORT.DRILLDOWN.LOAD_MORE')"
        :is-loading="isFetchingMore"
        @click="loadMore"
      />
    </div>
  </SidePanel>
</template>
