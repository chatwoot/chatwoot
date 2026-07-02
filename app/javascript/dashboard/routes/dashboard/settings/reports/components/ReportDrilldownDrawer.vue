<script setup>
import { computed, nextTick, onBeforeUnmount, ref, watch } from 'vue';
import { useEventListener } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { formatTime } from '@chatwoot/utils';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { useReportDrilldown } from '../composables/useReportDrilldown';
import ReportDrilldownCard from './ReportDrilldownCard.vue';

const props = defineProps({
  open: { type: Boolean, default: false },
  metric: { type: String, default: '' },
  metricName: { type: String, default: '' },
  bucketLabel: { type: String, default: '' },
  bucketTimestamp: { type: Number, default: null },
  from: { type: Number, default: null },
  to: { type: Number, default: null },
  type: { type: String, default: 'account' },
  id: { type: [String, Number], default: null },
  groupBy: { type: String, default: '' },
  businessHours: { type: Boolean, default: false },
  bucketValue: { type: Number, default: null },
  isAverageMetric: { type: Boolean, default: false },
  canPrev: { type: Boolean, default: false },
  canNext: { type: Boolean, default: false },
});

const emit = defineEmits(['close', 'navigate']);

const { t } = useI18n();
const drawerRef = ref(null);
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
} = useReportDrilldown();

let previousActiveElement = null;

const isOpen = computed(() => props.open);

const title = computed(() => props.metricName || '');

const bucketValue = computed(() => {
  if (props.bucketValue === null) return '';

  return props.isAverageMetric
    ? formatTime(props.bucketValue)
    : `${props.bucketValue}`;
});

// The headline stat already shows the conversation count for conversation-count
// metrics (e.g. conversations_count), so the subtitle count would be redundant.
const isStatConversationCount = computed(
  () =>
    !props.isAverageMetric &&
    meta.value.record_type === 'conversation' &&
    props.bucketValue === meta.value.conversation_count
);

const conversationCount = computed(() => {
  if (!meta.value.conversation_count || isStatConversationCount.value)
    return '';

  return t('REPORT.DRILLDOWN.RESULT_COUNT_CONVERSATION', {
    count: meta.value.conversation_count,
  });
});

// Timing metrics (e.g. reply time) show a duration as the stat, so the underlying
// message count adds context. Skip it when it just mirrors the conversation count
// (e.g. first response time has one response message per conversation).
const messageCount = computed(() => {
  if (
    !props.isAverageMetric ||
    meta.value.record_type !== 'message' ||
    !meta.value.total_count ||
    meta.value.total_count === meta.value.conversation_count
  ) {
    return '';
  }

  return t('REPORT.DRILLDOWN.RESULT_COUNT_MESSAGE', {
    count: meta.value.total_count,
  });
});

const subtitle = computed(() =>
  [props.bucketLabel, conversationCount.value, messageCount.value]
    .filter(Boolean)
    .join(' ⋅ ')
);

const restoreFocus = () => {
  if (previousActiveElement?.isConnected) {
    previousActiveElement.focus();
  }
  previousActiveElement = null;
};

const closeDrawer = () => {
  close();
  emit('close');
  restoreFocus();
};

const recordKey = record =>
  `${record.record_type}-${record.message?.id || record.conversation?.id}-${
    record.occurred_at
  }`;

const rememberActiveElement = () => {
  if (previousActiveElement) return;

  previousActiveElement =
    document.activeElement instanceof HTMLElement
      ? document.activeElement
      : null;
};

const focusDrawer = () => {
  nextTick(() => drawerRef.value?.focus());
};

const fetchDrilldown = () => {
  openDrilldown({
    metric: props.metric,
    bucketTimestamp: props.bucketTimestamp,
    from: props.from,
    to: props.to,
    type: props.type,
    id: props.id,
    groupBy: props.groupBy,
    businessHours: props.businessHours,
  });
};

const navigate = direction => {
  if (direction < 0 && !props.canPrev) return;
  if (direction > 0 && !props.canNext) return;

  emit('navigate', direction);
};

const onKeydown = event => {
  if (!isOpen.value) return;

  if (event.key === 'Escape') {
    event.preventDefault();
    event.stopPropagation();
    closeDrawer();
  } else if (event.key === 'ArrowLeft') {
    navigate(-1);
  } else if (event.key === 'ArrowRight') {
    navigate(1);
  }
};

useEventListener(document, 'keydown', onKeydown);

watch(
  () => props.open,
  isDrawerOpen => {
    if (!isDrawerOpen) {
      close();
      restoreFocus();
      return;
    }

    rememberActiveElement();
    fetchDrilldown();
    focusDrawer();
  },
  { immediate: true }
);

watch(
  () => [props.metric, props.bucketTimestamp],
  () => {
    if (props.open) fetchDrilldown();
  }
);

onBeforeUnmount(() => {
  restoreFocus();
});
</script>

<template>
  <Teleport to="body">
    <Transition name="report-drilldown-fade">
      <div
        v-if="isOpen"
        class="fixed inset-0 z-50 bg-black/30"
        role="presentation"
        @click.self="closeDrawer"
      >
        <aside
          ref="drawerRef"
          class="fixed inset-y-0 right-0 flex w-full max-w-xl flex-col bg-n-solid-1 shadow-xl outline outline-1 outline-n-container"
          role="dialog"
          aria-modal="true"
          :aria-label="title"
          tabindex="-1"
        >
          <header
            class="flex items-start justify-between gap-4 border-b border-n-weak px-6 py-5"
          >
            <div class="min-w-0">
              <h2 class="truncate text-base font-medium text-n-slate-12">
                {{ title }}
              </h2>
              <p
                v-if="bucketValue"
                class="mt-1 text-xl font-semibold text-n-slate-12"
              >
                {{ bucketValue }}
              </p>
              <div
                class="text-sm text-n-slate-11"
                :class="{
                  'mt-2': bucketValue,
                  'mt-1': !bucketValue,
                }"
              >
                {{ subtitle }}
              </div>
            </div>
            <div class="flex shrink-0 items-center gap-1">
              <Button
                ghost
                slate
                size="sm"
                icon="i-ph-caret-left"
                :disabled="!canPrev"
                :aria-label="$t('REPORT.DRILLDOWN.PREVIOUS_BUCKET')"
                @click="navigate(-1)"
              />
              <Button
                ghost
                slate
                size="sm"
                icon="i-ph-caret-right"
                :disabled="!canNext"
                :aria-label="$t('REPORT.DRILLDOWN.NEXT_BUCKET')"
                @click="navigate(1)"
              />
              <Button
                ghost
                slate
                size="sm"
                icon="i-ph-x"
                :aria-label="$t('REPORT.DRILLDOWN.CLOSE')"
                @click="closeDrawer"
              />
            </div>
          </header>

          <div class="min-h-0 flex-1 overflow-y-auto px-5 py-3">
            <div
              v-if="isFetching"
              class="flex h-40 items-center justify-center"
            >
              <Spinner />
            </div>

            <div
              v-else-if="hasError"
              class="flex h-40 items-center justify-center text-sm text-n-ruby-11"
            >
              {{ $t('REPORT.DRILLDOWN.ERROR') }}
            </div>

            <div
              v-else-if="!hasRecords"
              class="flex h-40 items-center justify-center text-sm text-n-slate-10"
            >
              {{ $t('REPORT.DRILLDOWN.EMPTY') }}
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
                :label="$t('REPORT.DRILLDOWN.LOAD_MORE')"
                :is-loading="isFetchingMore"
                @click="loadMore"
              />
            </div>
          </div>
        </aside>
      </div>
    </Transition>
  </Teleport>
</template>
