<script setup>
import { computed, nextTick, onBeforeUnmount, ref, watch } from 'vue';
import { useEventListener } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import CaptainAssistant from 'dashboard/api/captain/assistant';
import { useReportDrilldown } from 'dashboard/routes/dashboard/settings/reports/composables/useReportDrilldown';
import ReportDrilldownCard from 'dashboard/routes/dashboard/settings/reports/components/ReportDrilldownCard.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';

const props = defineProps({
  open: { type: Boolean, default: false },
  assistantId: { type: [String, Number], default: null },
  metric: { type: String, default: '' },
  metricName: { type: String, default: '' },
  metricValue: { type: String, default: '' },
  range: { type: String, default: '' },
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
  open: openDrilldown,
  close,
  loadMore,
} = useReportDrilldown(params => CaptainAssistant.getDrilldown(params));

let previousActiveElement = null;

const isOpen = computed(() => props.open);
const title = computed(() => props.metricName || '');

const subtitle = computed(() => {
  if (!meta.value.conversation_count) return '';

  return t('CAPTAIN.OVERVIEW.DRILLDOWN.RESULT_COUNT_CONVERSATION', {
    count: meta.value.conversation_count,
  });
});

const recordKey = record => `${record.conversation?.id}-${record.occurred_at}`;

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
  if (!props.metric || !props.assistantId) return;

  openDrilldown({
    assistantId: props.assistantId,
    metric: props.metric,
    range: props.range,
  });
};

const onKeydown = event => {
  if (!isOpen.value) return;

  if (event.key === 'Escape') {
    event.preventDefault();
    event.stopPropagation();
    closeDrawer();
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
  () => [props.metric, props.range],
  () => {
    if (props.open) fetchDrilldown();
  }
);

// The drawer's headline value is a snapshot of the previous assistant's card,
// so switching assistants (e.g. browser Back/Forward) closes it instead of
// refetching records that would no longer match the header.
watch(
  () => props.assistantId,
  () => {
    if (props.open) closeDrawer();
  }
);

onBeforeUnmount(() => {
  restoreFocus();
});
</script>

<template>
  <TeleportWithDirection to="body">
    <Transition name="report-drilldown-fade">
      <div
        v-if="isOpen"
        class="fixed inset-0 z-50 bg-black/30"
        role="presentation"
        @click.self="closeDrawer"
      >
        <aside
          ref="drawerRef"
          class="fixed inset-y-0 end-0 flex w-full max-w-xl flex-col bg-n-solid-1 shadow-xl outline outline-1 outline-n-container"
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
                v-if="metricValue"
                class="mt-1 text-xl font-semibold text-n-slate-12"
              >
                {{ metricValue }}
              </p>
              <div
                class="text-sm text-n-slate-11"
                :class="{
                  'mt-2': metricValue,
                  'mt-1': !metricValue,
                }"
              >
                {{ subtitle }}
              </div>
            </div>
            <Button
              ghost
              slate
              size="sm"
              icon="i-ph-x"
              :aria-label="$t('CAPTAIN.OVERVIEW.DRILLDOWN.CLOSE')"
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
              {{ $t('CAPTAIN.OVERVIEW.DRILLDOWN.ERROR') }}
            </div>

            <div
              v-else-if="!hasRecords"
              class="flex h-40 items-center justify-center text-sm text-n-slate-10"
            >
              {{ $t('CAPTAIN.OVERVIEW.DRILLDOWN.EMPTY') }}
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
          </div>
        </aside>
      </div>
    </Transition>
  </TeleportWithDirection>
</template>
