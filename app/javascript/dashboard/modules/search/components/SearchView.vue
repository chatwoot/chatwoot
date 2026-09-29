<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useRouter, useRoute } from 'vue-router';
import { useTrack } from 'dashboard/composables';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { useAccount } from 'dashboard/composables/useAccount';
import { useI18n } from 'vue-i18n';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';
import {
  useSearchStore,
  SEARCH_ENTITIES,
  PREVIEW_PER_PAGE,
} from 'dashboard/stores/search';
import { generateURLParams, parseURLParams } from '../helpers/searchHelper';
import {
  ROLES,
  CONVERSATION_PERMISSIONS,
  MANAGE_ALL_CONVERSATION_PERMISSIONS,
  CONTACT_PERMISSIONS,
  PORTAL_PERMISSIONS,
} from 'dashboard/constants/permissions.js';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { getUserPermissions } from 'dashboard/helper/permissionsHelper';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { CONVERSATION_EVENTS } from '../../../helper/AnalyticsHelper/events';

import Policy from 'dashboard/components/policy.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SearchHeader from './SearchHeader.vue';
import SearchTabs from './SearchTabs.vue';
import SearchResultConversationsList from './SearchResultConversationsList.vue';
import SearchResultMessagesList from './SearchResultMessagesList.vue';
import SearchResultContactsList from './SearchResultContactsList.vue';
import SearchResultArticlesList from './SearchResultArticlesList.vue';

const router = useRouter();
const route = useRoute();
const store = useStore();
const searchStore = useSearchStore();
const { currentAccount } = useAccount();
const { t } = useI18n();
const { shouldShow, isFeatureFlagEnabled, checkPermissions } = usePolicy();
const currentUser = useMapGetter('getCurrentUser');

const selectedTab = ref(route.params.tab || 'all');
const query = ref(route.query.q || '');
const searchStarted = ref(false);
const filters = ref({
  from: null,
  in: null,
  dateRange: { type: null, from: null, to: null },
});

const entityRequests = () =>
  Object.fromEntries(
    SEARCH_ENTITIES.map(type => [type, useAbortableRequest()])
  );
const requests = {
  counts: useAbortableRequest(),
  results: entityRequests(),
  previews: entityRequests(),
};

const isSelectedTabAll = computed(() => selectedTab.value === 'all');

const resultsOf = type =>
  (isSelectedTabAll.value ? searchStore.previews : searchStore.results)[type];

const recordsOf = (type, recordType) =>
  computed(() =>
    resultsOf(type).records.map(item => ({
      ...useCamelCase(item, { deep: true }),
      type: recordType,
    }))
  );

const contacts = recordsOf('contacts', 'contact');
const conversations = recordsOf('conversations', 'conversation');
const messages = recordsOf('messages', 'message');
const articles = recordsOf('articles', 'article');

const searchResultSectionClass = computed(() => ({
  'mt-4': isSelectedTabAll.value,
  'mt-0.5': !isSelectedTabAll.value,
}));

const filterByTab = tab =>
  computed(() => selectedTab.value === tab || isSelectedTabAll.value);

const filterContacts = filterByTab('contacts');
const filterConversations = filterByTab('conversations');
const filterMessages = filterByTab('messages');
const filterArticles = filterByTab('articles');

const TABS_CONFIG = {
  all: {
    permissions: [
      CONTACT_PERMISSIONS,
      ...ROLES,
      ...CONVERSATION_PERMISSIONS,
      PORTAL_PERMISSIONS,
    ],
  },
  contacts: {
    permissions: [...ROLES, CONTACT_PERMISSIONS],
  },
  conversations: {
    permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
  },
  messages: {
    permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
  },
  articles: {
    permissions: [...ROLES, PORTAL_PERMISSIONS],
    featureFlag: FEATURE_FLAGS.HELP_CENTER,
  },
};

const canCountConversations = computed(() =>
  checkPermissions([...ROLES, MANAGE_ALL_CONVERSATION_PERMISSIONS])
);

const tabs = computed(() => {
  return Object.entries(TABS_CONFIG)
    .map(([key, config]) => ({
      key,
      name: t(`SEARCH.TABS.${key.toUpperCase()}`),
      count: searchStore.countFor(key, isSelectedTabAll.value),
      showBadge:
        key !== 'all' &&
        (!['conversations', 'messages'].includes(key) ||
          canCountConversations.value),
      permissions: config.permissions,
      featureFlag: config.featureFlag,
    }))
    .filter(config => {
      // why the double check, glad you asked.
      // Some features are marked as premium features, that means
      // the feature will be visible, but a Paywall will be shown instead
      // this works for pages and routes, but fails for UI elements like search here
      // so we explicitly check if the feature is enabled
      return (
        shouldShow(config.featureFlag, config.permissions, null) &&
        isFeatureFlagEnabled(config.featureFlag)
      );
    });
});

const activeTabIndex = computed(() => {
  const index = tabs.value.findIndex(tab => tab.key === selectedTab.value);
  return index >= 0 ? index : 0;
});

const visibleEntities = computed(() =>
  tabs.value.map(tab => tab.key).filter(key => key !== 'all')
);

const countableEntities = computed(() =>
  tabs.value.filter(tab => tab.showBadge).map(tab => tab.key)
);

const focusedEntities = computed(() =>
  visibleEntities.value.filter(
    type => isSelectedTabAll.value || type === selectedTab.value
  )
);

const isFetching = computed(() =>
  focusedEntities.value.some(type => resultsOf(type).isFetching)
);

const hasResultError = computed(() =>
  focusedEntities.value.some(type => resultsOf(type).hasError)
);

const isMessageCountStale = computed(() =>
  searchStore.isMessageCountStale(isSelectedTabAll.value)
);

const showCountError = computed(
  () => searchStore.hasCountError || isMessageCountStale.value
);

const totalSearchResultsCount = computed(
  () =>
    contacts.value.length +
    conversations.value.length +
    messages.value.length +
    articles.value.length
);

const showEmptySearchResults = computed(
  () =>
    searchStarted.value &&
    isSelectedTabAll.value &&
    !isFetching.value &&
    !hasResultError.value &&
    totalSearchResultsCount.value === 0
);

const showResultsSection = computed(
  () => searchStarted.value && !showEmptySearchResults.value
);

const showLoadMore = computed(() => {
  const results = searchStore.results[selectedTab.value];
  return Boolean(results?.hasMore && !results.isFetching && !results.hasError);
});

const showViewMore = type => {
  if (!isSelectedTabAll.value) return false;
  const count = searchStore.countFor(type, true);
  return count === null
    ? searchStore.previews[type].hasMore
    : count > PREVIEW_PER_PAGE;
};

const showList = type =>
  !resultsOf(type).hasError || resultsOf(type).records.length > 0;

const clearSearchResult = () => {
  [
    requests.counts,
    ...Object.values(requests.results),
    ...Object.values(requests.previews),
  ].forEach(request => request.abort());
  searchStarted.value = false;
  searchStore.$reset();
};

const buildSearchPayload = (basePayload = {}, searchType = 'messages') => {
  const payload = { ...basePayload };

  // Only include filters if advanced search is enabled
  if (isFeatureFlagEnabled(FEATURE_FLAGS.ADVANCED_SEARCH)) {
    // Date filters apply to all search types
    if (filters.value.dateRange.from) {
      payload.since = filters.value.dateRange.from;
    }
    if (filters.value.dateRange.to) {
      payload.until = filters.value.dateRange.to;
    }

    // Only messages support 'from' and 'inboxId' filters
    if (searchType === 'messages') {
      if (filters.value.from) payload.from = filters.value.from;
      if (filters.value.in) payload.inboxId = filters.value.in;
    }
  }

  return payload;
};

const updateURL = () => {
  const params = {
    accountId: route.params.accountId,
    ...(selectedTab.value !== 'all' && { tab: selectedTab.value }),
  };

  const queryParams = {
    ...(query.value && { q: query.value }),
    ...generateURLParams(
      filters.value,
      isFeatureFlagEnabled(FEATURE_FLAGS.ADVANCED_SEARCH)
    ),
  };

  router.replace({ name: 'search', params, query: queryParams });
};

const fetchCounts = () => {
  if (!countableEntities.value.length) return;
  requests.counts.run(signal =>
    searchStore.fetchCounts(
      buildSearchPayload({ q: query.value, types: countableEntities.value }),
      { signal }
    )
  );
};

const fetchResults = (type, page = 1) =>
  requests.results[type].run(signal =>
    searchStore.fetchResults(
      type,
      buildSearchPayload({ q: query.value, page }, type),
      { signal }
    )
  );

const fetchPreview = type =>
  requests.previews[type].run(signal =>
    searchStore.fetchResults(
      type,
      buildSearchPayload({ q: query.value }, type),
      { signal, preview: true }
    )
  );

const fetchFocused = type =>
  isSelectedTabAll.value ? fetchPreview(type) : fetchResults(type);

const fetchFocusedResults = () => {
  focusedEntities.value
    .filter(type => {
      const { page, isFetching: isLoading } = resultsOf(type);
      return !page && !isLoading;
    })
    .forEach(fetchFocused);
};

const retryResults = () => {
  focusedEntities.value
    .filter(type => resultsOf(type).hasError)
    .forEach(type =>
      isSelectedTabAll.value
        ? fetchPreview(type)
        : fetchResults(type, resultsOf(type).page + 1)
    );
};

const onSearch = q => {
  query.value = q.trim();
  clearSearchResult();
  if (!tabs.value.some(tab => tab.key === selectedTab.value)) {
    selectedTab.value = 'all';
  }
  updateURL();
  if (!query.value) return;
  searchStarted.value = true;
  useTrack(CONVERSATION_EVENTS.SEARCH_CONVERSATION);
  fetchCounts();
  fetchFocusedResults();
};

const retryCounts = () => {
  // Restart a mismatched search so cached results cannot keep a count stale.
  // Only the focused tab's results are fetched again.
  if (isMessageCountStale.value) {
    onSearch(query.value);
    return;
  }
  fetchCounts();
};

const onFilterChange = () => {
  onSearch(query.value);
};

const onBack = () => {
  if (window.history.length > 2) {
    router.go(-1);
  } else {
    router.push({ name: 'home' });
  }
  clearSearchResult();
};

const loadMore = () => {
  fetchResults(
    selectedTab.value,
    searchStore.results[selectedTab.value].page + 1
  );
};

const onTabChange = tab => {
  selectedTab.value = tab;
  updateURL();
  fetchFocusedResults();
};

onMounted(() => {
  store.dispatch('agents/get');
});

// Wait for the account before restoring URL filters: the ADVANCED_SEARCH flag
// derives from account.features (loaded async), and reading it too early strips
// the filter params from the URL. `immediate` covers the already-loaded case.
watch(
  () =>
    JSON.stringify([
      currentAccount.value?.id,
      getUserPermissions(currentUser.value, currentAccount.value?.id),
      visibleEntities.value,
      isFeatureFlagEnabled(FEATURE_FLAGS.ADVANCED_SEARCH),
    ]),
  () => {
    if (!currentAccount.value?.id) return;
    filters.value = parseURLParams(
      route.query,
      isFeatureFlagEnabled(FEATURE_FLAGS.ADVANCED_SEARCH)
    );
    onSearch(route.query.q || '');
  },
  { immediate: true }
);

onUnmounted(() => {
  query.value = '';
  clearSearchResult();
});
</script>

<template>
  <div class="flex flex-col w-full h-full bg-n-surface-1">
    <div class="flex w-full p-4">
      <NextButton
        :label="t('GENERAL_SETTINGS.BACK')"
        icon="i-lucide-chevron-left"
        faded
        primary
        sm
        @click="onBack"
      />
    </div>
    <section class="flex flex-col flex-grow w-full h-full overflow-hidden">
      <div class="w-full max-w-5xl mx-auto z-30">
        <div class="flex flex-col w-full px-4">
          <SearchHeader
            v-model:filters="filters"
            :initial-query="query"
            @search="onSearch"
            @filter-change="onFilterChange"
          />
          <SearchTabs
            v-if="query"
            :tabs="tabs"
            :selected-tab="activeTabIndex"
            :is-fetching-counts="searchStore.isFetchingCounts"
            @tab-change="onTabChange"
          />
          <div
            v-if="query && showCountError"
            class="flex items-center gap-2 text-sm text-n-slate-11 mb-2"
          >
            <span>{{ t('SEARCH.COUNTS_UNAVAILABLE') }}</span>
            <NextButton
              :label="t('SEARCH.RETRY')"
              sm
              link
              :is-loading="searchStore.isFetchingCounts"
              @click="retryCounts"
            />
          </div>
        </div>
      </div>
      <div class="flex-grow w-full h-full overflow-y-auto">
        <div class="w-full max-w-5xl mx-auto px-4 pb-6">
          <div
            v-if="hasResultError"
            class="flex items-center gap-2 text-sm text-n-slate-11 py-3"
          >
            <span>{{ t('SEARCH.RESULTS_UNAVAILABLE') }}</span>
            <NextButton
              :label="t('SEARCH.RETRY')"
              sm
              link
              @click="retryResults"
            />
          </div>
          <div v-if="showResultsSection">
            <Policy
              :permissions="[...ROLES, CONTACT_PERMISSIONS]"
              class="flex flex-col justify-center"
            >
              <SearchResultContactsList
                v-if="filterContacts && showList('contacts')"
                :is-fetching="resultsOf('contacts').isFetching"
                :contacts="contacts"
                :query="query"
                :show-title="isSelectedTabAll"
                class="mt-0.5"
              />
              <NextButton
                v-if="showViewMore('contacts')"
                :label="t(`SEARCH.VIEW_MORE`)"
                icon="i-lucide-eye"
                slate
                sm
                outline
                @click="onTabChange('contacts')"
              />
            </Policy>

            <Policy
              :permissions="[...ROLES, ...CONVERSATION_PERMISSIONS]"
              class="flex flex-col justify-center"
            >
              <SearchResultMessagesList
                v-if="filterMessages && showList('messages')"
                :is-fetching="resultsOf('messages').isFetching"
                :messages="messages"
                :query="query"
                :show-title="isSelectedTabAll"
                :class="searchResultSectionClass"
              />
              <NextButton
                v-if="showViewMore('messages')"
                :label="t(`SEARCH.VIEW_MORE`)"
                icon="i-lucide-eye"
                slate
                sm
                outline
                @click="onTabChange('messages')"
              />
            </Policy>

            <Policy
              :permissions="[...ROLES, ...CONVERSATION_PERMISSIONS]"
              class="flex flex-col justify-center"
            >
              <SearchResultConversationsList
                v-if="filterConversations && showList('conversations')"
                :is-fetching="resultsOf('conversations').isFetching"
                :conversations="conversations"
                :query="query"
                :show-title="isSelectedTabAll"
                :class="searchResultSectionClass"
              />
              <NextButton
                v-if="showViewMore('conversations')"
                :label="t(`SEARCH.VIEW_MORE`)"
                icon="i-lucide-eye"
                slate
                sm
                outline
                @click="onTabChange('conversations')"
              />
            </Policy>

            <Policy
              v-if="isFeatureFlagEnabled(FEATURE_FLAGS.HELP_CENTER)"
              :permissions="[...ROLES, PORTAL_PERMISSIONS]"
              :feature-flag="FEATURE_FLAGS.HELP_CENTER"
              class="flex flex-col justify-center"
            >
              <SearchResultArticlesList
                v-if="filterArticles && showList('articles')"
                :is-fetching="resultsOf('articles').isFetching"
                :articles="articles"
                :query="query"
                :show-title="isSelectedTabAll"
                :class="searchResultSectionClass"
              />
              <NextButton
                v-if="showViewMore('articles')"
                :label="t(`SEARCH.VIEW_MORE`)"
                icon="i-lucide-eye"
                slate
                sm
                outline
                @click="onTabChange('articles')"
              />
            </Policy>

            <div v-if="showLoadMore" class="flex justify-center mt-3 mb-6">
              <NextButton
                :label="t(`SEARCH.LOAD_MORE`)"
                icon="i-lucide-cloud-download"
                slate
                sm
                faded
                @click="loadMore"
              />
            </div>
          </div>
          <div
            v-else-if="showEmptySearchResults"
            class="flex flex-col items-center justify-center px-4 py-6 mt-8 rounded-md"
          >
            <fluent-icon icon="info" size="16px" class="text-n-slate-11" />
            <p class="m-2 text-center text-n-slate-11">
              {{ t('SEARCH.EMPTY_STATE_FULL', { query }) }}
            </p>
          </div>
          <div
            v-else-if="!query"
            class="flex flex-col items-center justify-center px-4 py-6 mt-8 text-center rounded-md"
          >
            <p class="text-center margin-bottom-0">
              <fluent-icon icon="search" size="24px" class="text-n-slate-11" />
            </p>
            <p class="m-2 text-center text-n-slate-11">
              {{ t('SEARCH.EMPTY_STATE_DEFAULT') }}
            </p>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>
