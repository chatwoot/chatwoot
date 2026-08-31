<script setup>
import { computed, nextTick, onUnmounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { debounce } from '@chatwoot/utils';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import CaptainFaqSuggestionsAPI from 'dashboard/api/captain/faqSuggestions';

import Button from 'dashboard/components-next/button/Button.vue';
import CaptainPaywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import FaqSuggestionCard from 'dashboard/components-next/captain/assistant/FaqSuggestionCard.vue';
import FaqSuggestionReviewDialog from 'dashboard/components-next/captain/pageComponents/response/FaqSuggestionReviewDialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';

const route = useRoute();
const router = useRouter();
const store = useStore();
const { t } = useI18n();

const suggestions = useMapGetter('captainFaqSuggestions/getRecords');
const suggestionMeta = useMapGetter('captainFaqSuggestions/getMeta');
const uiFlags = useMapGetter('captainFaqSuggestions/getUIFlags');

const searchQuery = ref('');
const selectedSuggestion = ref(null);
const reviewDialog = ref(null);
const activeSuggestionId = ref(null);

const selectedAssistantId = computed(() => Number(route.params.assistantId));
const isFetching = computed(() => uiFlags.value.fetchingList);
const isMutating = computed(
  () => uiFlags.value.updatingItem || uiFlags.value.deletingItem
);
const hasActiveFilters = computed(() => Boolean(searchQuery.value));

const backUrl = computed(() => ({
  name: 'captain_assistants_responses_index',
  params: {
    accountId: route.params.accountId,
    assistantId: selectedAssistantId.value,
  },
}));

const updateURL = (page, search) => {
  const query = { page: page || 1 };
  if (search) query.search = search;
  router.replace({ query });
};

const { run: runListRequest, abort: abortListRequest } = useAbortableRequest();

const fetchSuggestions = async (page = 1) => {
  updateURL(page, searchQuery.value);
  store.dispatch('captainFaqSuggestions/setFetchingList', true);

  try {
    const response = await runListRequest(signal =>
      CaptainFaqSuggestionsAPI.get({
        page,
        search: searchQuery.value,
        assistantId: selectedAssistantId.value,
        signal,
      })
    );

    if (!response) return;

    store.dispatch('captainFaqSuggestions/setRecords', {
      records: response.data.payload,
      meta: response.data.meta,
    });
    store.dispatch('captainFaqSuggestions/setFetchingList', false);
  } catch (error) {
    useAlert(error?.message || t('CAPTAIN.FAQ_SUGGESTIONS.ERRORS.LOAD'));
    store.dispatch('captainFaqSuggestions/setFetchingList', false);
  }
};

const refreshCurrentPage = () => {
  const currentPage = suggestionMeta.value.page || 1;
  const page =
    suggestions.value.length || currentPage === 1
      ? currentPage
      : currentPage - 1;
  fetchSuggestions(page);
};

const handleApprove = async suggestion => {
  activeSuggestionId.value = suggestion.id;
  try {
    await store.dispatch('captainFaqSuggestions/approve', {
      id: suggestion.id,
      question: suggestion.question,
      answer: suggestion.answer,
    });
    useAlert(t('CAPTAIN.FAQ_SUGGESTIONS.SUCCESS.APPROVED'));
    refreshCurrentPage();
  } catch (error) {
    useAlert(error?.message || t('CAPTAIN.FAQ_SUGGESTIONS.ERRORS.APPROVE'));
  } finally {
    activeSuggestionId.value = null;
  }
};

const handleDismiss = async suggestion => {
  activeSuggestionId.value = suggestion.id;
  try {
    await store.dispatch('captainFaqSuggestions/dismiss', suggestion.id);
    useAlert(t('CAPTAIN.FAQ_SUGGESTIONS.SUCCESS.DISMISSED'));
    refreshCurrentPage();
  } catch (error) {
    useAlert(error?.message || t('CAPTAIN.FAQ_SUGGESTIONS.ERRORS.DISMISS'));
  } finally {
    activeSuggestionId.value = null;
  }
};

const handleReview = suggestion => {
  selectedSuggestion.value = suggestion;
  nextTick(() => reviewDialog.value.dialogRef.open());
};

const handleReviewClose = () => {
  selectedSuggestion.value = null;
};

const handleResolved = () => {
  refreshCurrentPage();
};

const debouncedSearch = debounce(() => fetchSuggestions(1), 500);

const handleSearchInput = () => {
  abortListRequest();
  debouncedSearch();
};

const clearFilters = () => {
  searchQuery.value = '';
  fetchSuggestions(1);
};

const initializeFromURL = () => {
  searchQuery.value = route.query.search || '';
  fetchSuggestions(parseInt(route.query.page, 10) || 1);
};

watch(
  selectedAssistantId,
  () => {
    selectedSuggestion.value = null;
    activeSuggestionId.value = null;
    store.dispatch('captainFaqSuggestions/setRecords', {
      records: [],
      meta: { page: 1, total_count: 0 },
    });
    initializeFromURL();
  },
  { immediate: true }
);

onUnmounted(() => {
  store.dispatch('captainFaqSuggestions/setFetchingList', false);
});
</script>

<template>
  <PageLayout
    :total-count="suggestionMeta.totalCount"
    :current-page="suggestionMeta.page"
    :header-title="$t('CAPTAIN.FAQ_SUGGESTIONS.HEADER')"
    :is-fetching="isFetching"
    :is-empty="!suggestions.length"
    :show-pagination-footer="!isFetching && !!suggestions.length"
    :show-know-more="false"
    :feature-flag="FEATURE_FLAGS.CAPTAIN"
    :back-url="backUrl"
    @update:current-page="fetchSuggestions"
  >
    <template #search>
      <Input
        v-model="searchQuery"
        :placeholder="$t('CAPTAIN.FAQ_SUGGESTIONS.SEARCH_PLACEHOLDER')"
        class="w-64"
        size="sm"
        type="search"
        autofocus
        @input="handleSearchInput"
      />
    </template>

    <template #subHeader>
      <div
        v-if="suggestions.length"
        class="mb-2 flex items-center gap-2 text-sm text-n-slate-11"
      >
        <span class="font-medium text-n-slate-12">
          {{
            $t('CAPTAIN.FAQ_SUGGESTIONS.QUEUE_COUNT', {
              count: suggestionMeta.totalCount,
            })
          }}
        </span>
        <span class="border-s border-n-weak ps-2">
          {{ $t('CAPTAIN.FAQ_SUGGESTIONS.QUEUE_HINT') }}
        </span>
      </div>
    </template>

    <template #emptyState>
      <EmptyStateLayout
        :title="$t('CAPTAIN.FAQ_SUGGESTIONS.EMPTY_STATE.TITLE')"
        :subtitle="$t('CAPTAIN.FAQ_SUGGESTIONS.EMPTY_STATE.SUBTITLE')"
        :show-backdrop="false"
      >
        <template #actions>
          <Button
            v-if="hasActiveFilters"
            :label="$t('CAPTAIN.FAQ_SUGGESTIONS.EMPTY_STATE.CLEAR_SEARCH')"
            variant="link"
            size="sm"
            @click="clearFilters"
          />
        </template>
      </EmptyStateLayout>
    </template>

    <template #paywall>
      <CaptainPaywall />
    </template>

    <template #body>
      <div class="flex flex-col gap-4 pb-6">
        <FaqSuggestionCard
          v-for="suggestion in suggestions"
          :key="suggestion.id"
          :suggestion="suggestion"
          :is-loading="isMutating && activeSuggestionId === suggestion.id"
          @approve="handleApprove"
          @dismiss="handleDismiss"
          @review="handleReview"
        />
      </div>
    </template>

    <FaqSuggestionReviewDialog
      v-if="selectedSuggestion"
      ref="reviewDialog"
      :suggestion="selectedSuggestion"
      @close="handleReviewClose"
      @resolved="handleResolved"
    />
  </PageLayout>
</template>
