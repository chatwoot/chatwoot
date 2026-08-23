<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import DecisionTrace from 'dashboard/components-next/captain/assistant/DecisionTrace.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const { t } = useI18n();
const route = useRoute();
const store = useStore();

const assistantId = computed(() => Number(route.params.assistantId));

const traces = useMapGetter('captainTraces/getTraces');
const meta = useMapGetter('captainTraces/getMeta');
const isFetching = useMapGetter('captainTraces/isFetching');

const currentPage = ref(1);
const conversationFilter = ref('');
const expandedIds = ref(new Set());

const hasTraces = computed(() => (traces.value || []).length > 0);
const totalCount = computed(() => meta.value.count || 0);

const fetchTraces = page => {
  currentPage.value = page;
  store.dispatch('captainTraces/fetch', {
    assistantId: assistantId.value,
    conversationId: conversationFilter.value || undefined,
    page,
  });
};

const applyConversationFilter = () => {
  currentPage.value = 1;
  fetchTraces(1);
};

const toggleExpanded = id => {
  const next = new Set(expandedIds.value);
  if (next.has(id)) {
    next.delete(id);
  } else {
    next.add(id);
  }
  expandedIds.value = next;
};

const OUTCOME_KEYS = {
  answered: 'CAPTAIN.TRACES.OUTCOME_ANSWERED',
  simple_reply: 'CAPTAIN.TRACES.OUTCOME_SIMPLE_REPLY',
  handoff: 'CAPTAIN.TRACES.OUTCOME_HANDOFF',
  offer: 'CAPTAIN.TRACES.OUTCOME_HANDOFF_OFFER',
  error: 'CAPTAIN.TRACES.OUTCOME_ERROR',
};

const outcomeLabel = outcome => {
  const key = OUTCOME_KEYS[outcome];
  return key ? t(key) : outcome || '';
};

watch(assistantId, () => {
  conversationFilter.value = '';
  expandedIds.value = new Set();
  fetchTraces(1);
});

onMounted(() => fetchTraces(1));
</script>

<template>
  <PageLayout
    :header-title="t('CAPTAIN.TRACES.TITLE')"
    :is-fetching="isFetching"
    :is-empty="!hasTraces && !isFetching"
    :show-pagination-footer="hasTraces"
    :show-know-more="false"
    :total-count="totalCount"
    :current-page="currentPage"
    @update:current-page="fetchTraces"
  >
    <template #body>
      <div class="flex flex-col gap-3">
        <div class="flex justify-end">
          <Input
            v-model="conversationFilter"
            :placeholder="t('CAPTAIN.TRACES.CONVERSATION_FILTER')"
            class="max-w-xs w-full"
            @change="applyConversationFilter"
          />
        </div>

        <template v-if="hasTraces">
          <div
            v-for="trace in traces"
            :key="trace.id"
            class="border border-n-weak rounded-xl bg-n-solid-1"
          >
            <button
              type="button"
              class="flex items-center justify-between w-full px-4 py-3 text-start cursor-pointer bg-transparent border-0"
              @click="toggleExpanded(trace.id)"
            >
              <div class="flex items-center gap-3 min-w-0">
                <span class="text-sm font-medium text-n-slate-12">
                  {{
                    t('CAPTAIN.TRACES.CONVERSATION', {
                      id: trace.conversationDisplayId,
                    })
                  }}
                </span>
                <span v-if="trace.contactName" class="text-xs text-n-slate-11">
                  {{ trace.contactName }}
                </span>
              </div>
              <div class="flex items-center gap-3">
                <span
                  class="text-xs px-2 py-0.5 rounded-full bg-n-alpha-2 text-n-slate-11"
                >
                  {{ outcomeLabel(trace.outcome) }}
                </span>
                <span class="text-xs text-n-slate-11">
                  {{ new Date(trace.createdAt).toLocaleString() }}
                </span>
              </div>
            </button>
            <div
              v-if="expandedIds.has(trace.id)"
              class="px-4 pb-4 border-t border-n-weak"
            >
              <DecisionTrace :nodes="trace.trace" class="pt-4" />
            </div>
          </div>
        </template>

        <div
          v-else-if="!isFetching"
          class="flex flex-col items-center justify-center min-h-80 gap-2 text-center"
        >
          <span class="text-base font-medium text-n-slate-12">
            {{ t('CAPTAIN.TRACES.EMPTY_TITLE') }}
          </span>
          <span class="max-w-md text-sm text-n-slate-11">
            {{ t('CAPTAIN.TRACES.EMPTY_SUBTITLE') }}
          </span>
        </div>
      </div>
    </template>
  </PageLayout>
</template>
