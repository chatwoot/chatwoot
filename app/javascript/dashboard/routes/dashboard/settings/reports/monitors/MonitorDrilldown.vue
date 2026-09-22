<script setup>
import { onBeforeUnmount, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import MonitorsAPI from 'dashboard/api/monitors';
import { useReportDrilldown } from '../composables/useReportDrilldown';
import ReportDrilldownCard from '../components/ReportDrilldownCard.vue';
import SidePanel from 'dashboard/components-next/side-panel/SidePanel.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  request: { type: Object, default: null },
  label: { type: String, default: '' },
});
const emit = defineEmits(['close', 'changed']);
const { t } = useI18n();
const panel = ref(null);
const fetcher = async params => {
  try {
    return await MonitorsAPI.conversations(params);
  } catch (error) {
    if (error.response?.status === 409) emit('changed');
    throw error;
  }
};
const {
  records,
  isFetching,
  isFetchingMore,
  hasError,
  hasMore,
  open,
  close,
  loadMore,
} = useReportDrilldown(fetcher);
onBeforeUnmount(close);
watch(
  () => props.request,
  request => {
    close();
    if (!request) {
      panel.value?.close();
      return;
    }
    panel.value?.open();
    open(request);
  }
);
</script>

<template>
  <SidePanel ref="panel" :title="label" width="xl" @close="emit('close')">
    <div v-if="isFetching" class="flex justify-center py-20"><Spinner /></div>
    <p v-else-if="hasError" role="alert" class="text-n-ruby-11">
      {{ t('MONITORS.ERRORS.fetch_failed') }}
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
