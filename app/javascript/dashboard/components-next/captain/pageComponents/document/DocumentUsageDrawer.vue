<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import CaptainDocumentAPI from 'dashboard/api/captain/document';
import { useReportDrilldown } from 'dashboard/routes/dashboard/settings/reports/composables/useReportDrilldown';
import ReportDrilldownCard from 'dashboard/routes/dashboard/settings/reports/components/ReportDrilldownCard.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import SidePanel from 'dashboard/components-next/side-panel/SidePanel.vue';

const props = defineProps({
  open: { type: Boolean, default: false },
  document: { type: Object, default: null },
});

const emit = defineEmits(['close']);

const panelRef = ref(null);
const { t } = useI18n();
const {
  records,
  meta,
  isFetching,
  isFetchingMore,
  hasError,
  hasRecords,
  hasMore,
  open: openDrilldown,
  close,
  loadMore,
} = useReportDrilldown(params => CaptainDocumentAPI.getDrilldown(params));

const title = computed(
  () => props.document?.name || props.document?.external_link || ''
);

const conversationCount = computed(
  () =>
    meta.value.conversation_count ??
    props.document?.used_in_conversations_count ??
    0
);

const subtitle = computed(() =>
  t('CAPTAIN.DOCUMENTS.USED_IN_CONVERSATIONS', {
    n: conversationCount.value,
  })
);

const recordKey = record =>
  `${record.record_type}-${record.message?.id || record.conversation?.id}-${
    record.occurred_at
  }`;

const fetchDrilldown = () => {
  if (!props.document?.id) return;

  openDrilldown({ documentId: props.document.id });
};

watch(
  () => props.open,
  isDrawerOpen => {
    if (!isDrawerOpen) {
      panelRef.value?.close();
      close();
      return;
    }

    panelRef.value?.open();
    fetchDrilldown();
  }
);

watch(
  () => props.document?.id,
  () => {
    if (props.open) fetchDrilldown();
  }
);
</script>

<template>
  <SidePanel ref="panelRef" :title="title" width="xl" @close="emit('close')">
    <template #header>
      <div class="min-w-0">
        <h3 class="truncate text-base font-medium text-n-slate-12">
          {{ title }}
        </h3>
        <p class="mt-1 text-sm text-n-slate-11">
          {{ subtitle }}
        </p>
      </div>
    </template>

    <div v-if="isFetching" class="flex h-40 items-center justify-center">
      <Spinner />
    </div>

    <div
      v-else-if="hasError"
      class="flex h-40 items-center justify-center text-sm text-n-ruby-11"
    >
      {{ $t('CAPTAIN.OVERVIEW.DRILLDOWN.ERROR') }}
    </div>

    <div
      v-else-if="!hasRecords"
      class="flex h-40 items-center justify-center text-sm text-n-slate-10"
    >
      {{ $t('CAPTAIN.DOCUMENTS.NO_USED_CONVERSATIONS') }}
    </div>

    <div v-else class="flex flex-col gap-2">
      <ReportDrilldownCard
        v-for="record in records"
        :key="recordKey(record)"
        :record="record"
      />

      <Button
        v-if="hasMore"
        faded
        slate
        size="sm"
        class="mx-auto mt-2"
        :label="$t('CAPTAIN.OVERVIEW.DRILLDOWN.LOAD_MORE')"
        :is-loading="isFetchingMore"
        @click="loadMore"
      />
    </div>
  </SidePanel>
</template>
