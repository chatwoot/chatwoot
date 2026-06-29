<script setup>
import { computed, nextTick, onBeforeUnmount, ref, watch } from 'vue';
import { useEventListener } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { useReportDrilldown } from '../composables/useReportDrilldown';
import ReportDrilldownCard from './ReportDrilldownCard.vue';

const props = defineProps({
  request: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['close']);

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
  open,
  close,
  loadMore,
} = useReportDrilldown();

let previousActiveElement = null;

const isOpen = computed(() => !!props.request);

const title = computed(() => {
  if (!props.request) return '';

  return t('REPORT.DRILLDOWN.TITLE', {
    metric: props.request.metricName,
  });
});

const subtitle = computed(() => props.request?.bucketLabel || '');

const resultCount = computed(() => {
  if (!meta.value.total_count) return '';

  return t('REPORT.DRILLDOWN.RESULT_COUNT', {
    count: meta.value.total_count,
  });
});

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

const onKeydown = event => {
  if (!isOpen.value || event.key !== 'Escape') return;

  event.preventDefault();
  event.stopPropagation();
  closeDrawer();
};

useEventListener(document, 'keydown', onKeydown);

watch(
  () => props.request,
  request => {
    if (request) {
      rememberActiveElement();
      open(request);
      focusDrawer();
    } else {
      close();
      restoreFocus();
    }
  },
  { immediate: true }
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
              <p class="mt-1 text-sm text-n-slate-11">
                {{ subtitle }}
              </p>
              <p v-if="resultCount" class="mt-1 text-xs text-n-slate-10">
                {{ resultCount }}
              </p>
            </div>
            <Button
              ghost
              slate
              size="sm"
              icon="i-ph-x"
              :aria-label="$t('REPORT.DRILLDOWN.CLOSE')"
              @click="closeDrawer"
            />
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
