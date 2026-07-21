<script setup>
import { computed, ref, watch, onMounted } from 'vue';
import { until } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { isVoiceCallEnabled } from 'dashboard/helper/inbox';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useCallHistoryStore } from 'dashboard/stores/callHistory';

import CallListItem from 'dashboard/components-next/Calls/CallListItem.vue';
import CallsEmptyState from 'dashboard/components-next/Calls/CallsEmptyState.vue';
import CallsFilterBar from 'dashboard/components-next/Calls/CallsFilterBar.vue';
import { CALL_ACTIVITY_PARAMS } from 'dashboard/components-next/Calls/constants';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const RESULTS_PER_PAGE = 25;

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();
const callHistoryStore = useCallHistoryStore();

const inboxes = useMapGetter('inboxes/getInboxes');
const accountId = useMapGetter('getCurrentAccountId');
const currentUserId = useMapGetter('getCurrentUserID');
const agents = useMapGetter('agents/getVerifiedAgents');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

// CallFinder scopes non-admins to their own accepted calls, so the assignee
// filter is only meaningful for admins; everyone else defaults to themselves.
const { isAdmin } = useAdmin();

const voiceInboxes = computed(() => inboxes.value.filter(isVoiceCallEnabled));

const isVoiceEnabled = computed(
  () =>
    isFeatureEnabledonAccount.value(
      accountId.value,
      FEATURE_FLAGS.CHANNEL_VOICE
    ) && voiceInboxes.value.length > 0
);

const calls = computed(() => callHistoryStore.records);
const meta = computed(() => callHistoryStore.meta);
const isFetching = computed(() => callHistoryStore.uiFlags.isFetching);
const accountUiFlags = useMapGetter('accounts/getUIFlags');

const isInitializing = ref(true);

// Filters are seeded from the URL so a shared link restores the same view.
const activity = ref(
  CALL_ACTIVITY_PARAMS[route.query.activity] ? route.query.activity : null
);

const assigneeId = ref(
  isAdmin.value ? Number(route.query.assignee_id) || null : currentUserId.value
);
const inboxId = ref(Number(route.query.inbox_id) || null);
const currentPage = ref(Number(route.query.page) || 1);

const syncFiltersToUrl = () => {
  router.replace({
    query: {
      ...(activity.value && { activity: activity.value }),
      ...(isAdmin.value &&
        assigneeId.value && { assignee_id: assigneeId.value }),
      ...(inboxId.value && { inbox_id: inboxId.value }),
      ...(currentPage.value > 1 && { page: currentPage.value }),
    },
  });
};

const fetchCalls = async () => {
  syncFiltersToUrl();
  try {
    await callHistoryStore.fetchCalls({
      page: currentPage.value,
      ...(CALL_ACTIVITY_PARAMS[activity.value] || {}),
      ...(assigneeId.value ? { agent_id: assigneeId.value } : {}),
      ...(inboxId.value ? { inbox_id: inboxId.value } : {}),
    });
  } catch (error) {
    useAlert(error.message);
  }
};

watch([activity, assigneeId, inboxId], () => {
  currentPage.value = 1;
  fetchCalls();
});

const onPageChange = page => {
  currentPage.value = page;
  fetchCalls();
};

onMounted(async () => {
  try {
    await Promise.all([
      store.dispatch('inboxes/get'),
      until(() => accountUiFlags.value.isFetchingItem).toBe(false),
    ]);
    if (!isVoiceEnabled.value) return;
    // Only admins see the assignee filter, so only they need the agent list.
    if (isAdmin.value) store.dispatch('agents/get');
    await fetchCalls();
  } finally {
    isInitializing.value = false;
  }
});
</script>

<template>
  <div
    v-if="isInitializing"
    class="flex items-center justify-center w-full h-full bg-n-surface-1"
  >
    <Spinner :size="24" />
  </div>
  <CallsEmptyState v-else-if="!isVoiceEnabled" />
  <section
    v-else
    class="flex flex-col w-full h-full overflow-hidden bg-n-surface-1"
  >
    <header class="px-6 pt-6 pb-4 shrink-0">
      <div class="w-full">
        <h1 class="text-xl font-medium text-n-slate-12">
          {{ t('CALLS_PAGE.HEADER') }}
        </h1>
        <CallsFilterBar
          v-model:activity="activity"
          v-model:assignee-id="assigneeId"
          v-model:inbox-id="inboxId"
          class="mt-5"
          :total-count="isFetching ? null : meta.count"
          :agents="agents"
          :inboxes="voiceInboxes"
          :show-assignee="isAdmin"
        />
      </div>
    </header>
    <main class="flex-1 px-6 overflow-y-auto">
      <div class="w-full">
        <div v-if="isFetching" class="flex items-center justify-center py-16">
          <Spinner :size="24" />
        </div>
        <div
          v-else-if="!calls.length"
          class="flex items-center justify-center py-16"
        >
          <span class="text-base text-n-slate-11">
            {{ t('CALLS_PAGE.EMPTY_STATE') }}
          </span>
        </div>
        <template v-else>
          <CallListItem v-for="call in calls" :key="call.id" :call="call" />
        </template>
      </div>
    </main>
    <footer v-if="calls.length" class="sticky bottom-0 shrink-0">
      <PaginationFooter
        :current-page="currentPage"
        :total-items="meta.count"
        :items-per-page="RESULTS_PER_PAGE"
        @update:current-page="onPageChange"
      />
    </footer>
  </section>
</template>
