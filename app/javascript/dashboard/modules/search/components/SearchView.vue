<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useRouter, useRoute } from 'vue-router';
import { useTrack } from 'dashboard/composables';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { SEARCH_ENTITIES, PREVIEW_PER_PAGE } from '../constants';
import { useAccount } from 'dashboard/composables/useAccount';
import { useI18n } from 'vue-i18n';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';
import { generateURLParams, parseURLParams } from '../helpers/searchHelper';
import {
  ROLES,
  CONVERSATION_PERMISSIONS,
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
const { currentAccount } = useAccount();
const { t } = useI18n();

const selectedTab = ref(route.params.tab || 'all');
const query = ref(route.query.q || '');
const isSelectedTabAll = computed(() => selectedTab.value === 'all');

const currentUser = useMapGetter('getCurrentUser');
const searchState = useMapGetter('conversationSearch/getSearchState');
const countRequest = useAbortableRequest();
const resultRequests = Object.fromEntries(
  SEARCH_ENTITIES.map(type => [type, useAbortableRequest()])
);
const searchStarted = ref(false);

const contactRecords = useMapGetter('conversationSearch/getContactRecords');
const conversationRecords = useMapGetter(
  'conversationSearch/getConversationRecords'
);
const messageRecords = useMapGetter('conversationSearch/getMessageRecords');
const articleRecords = useMapGetter('conversationSearch/getArticleRecords');
const uiFlags = useMapGetter('conversationSearch/getUIFlags');

const addTypeToRecords = (records, type) => {
  const entity = `${type}s`;
  const items =
    isSelectedTabAll.value && !searchState.value.pages[entity]
      ? searchState.value.previews[entity] || []
      : records.value;
  return items.map(item => ({ ...useCamelCase(item, { deep: true }), type }));
};

const mappedContacts = computed(() =>
  addTypeToRecords(contactRecords, 'contact')
);
const mappedConversations = computed(() =>
  addTypeToRecords(conversationRecords, 'conversation')
);
const mappedMessages = computed(() =>
  addTypeToRecords(messageRecords, 'message')
);
const mappedArticles = computed(() =>
  addTypeToRecords(articleRecords, 'article')
);

const searchResultSectionClass = computed(() => ({
  'mt-4': isSelectedTabAll.value,
  'mt-0.5': !isSelectedTabAll.value,
}));

const sliceRecordsIfAllTab = items =>
  isSelectedTabAll.value ? items.value.slice(0, PREVIEW_PER_PAGE) : items.value;

const contacts = computed(() => sliceRecordsIfAllTab(mappedContacts));
const conversations = computed(() => sliceRecordsIfAllTab(mappedConversations));
const messages = computed(() => sliceRecordsIfAllTab(mappedMessages));
const articles = computed(() => sliceRecordsIfAllTab(mappedArticles));

const filterByTab = tab =>
  computed(() => selectedTab.value === tab || isSelectedTabAll.value);

const filterContacts = filterByTab('contacts');
const filterConversations = filterByTab('conversations');
const filterMessages = filterByTab('messages');
const filterArticles = filterByTab('articles');

const { shouldShow, isFeatureFlagEnabled } = usePolicy();
const countBackendMismatch = computed(() =>
  Boolean(
    searchState.value.messageBackend &&
      searchState.value.countBackend &&
      searchState.value.messageBackend !== searchState.value.countBackend
  )
);
const entityCount = type =>
  type === 'messages' && countBackendMismatch.value
    ? null
    : (searchState.value.totals[type] ?? null);

const TABS_CONFIG = {
  all: {
    permissions: [
      CONTACT_PERMISSIONS,
      ...ROLES,
      ...CONVERSATION_PERMISSIONS,
      PORTAL_PERMISSIONS,
    ],
    count: () => null, // No count for all tab
  },
  contacts: {
    permissions: [...ROLES, CONTACT_PERMISSIONS],
    count: () => entityCount('contacts'),
  },
  conversations: {
    permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
    count: () => entityCount('conversations'),
  },
  messages: {
    permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
    count: () => entityCount('messages'),
  },
  articles: {
    permissions: [...ROLES, PORTAL_PERMISSIONS],
    featureFlag: FEATURE_FLAGS.HELP_CENTER,
    count: () => entityCount('articles'),
  },
};

const tabs = computed(() => {
  return Object.entries(TABS_CONFIG)
    .map(([key, config]) => ({
      key,
      name: t(`SEARCH.TABS.${key.toUpperCase()}`),
      count: config.count(),
      showBadge: key !== 'all',
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

const totalSearchResultsCount = computed(
  () =>
    contacts.value.length +
    conversations.value.length +
    messages.value.length +
    articles.value.length
);

const activeTabIndex = computed(() => {
  const index = tabs.value.findIndex(tab => tab.key === selectedTab.value);
  return index >= 0 ? index : 0;
});

const visibleEntities = computed(() =>
  tabs.value.map(tab => tab.key).filter(key => key !== 'all')
);
const focusedEntities = computed(() =>
  visibleEntities.value.filter(
    type => isSelectedTabAll.value || type === selectedTab.value
  )
);
const isFetchingAny = computed(() =>
  focusedEntities.value.some(
    type => uiFlags.value[type.slice(0, -1)].isFetching
  )
);
const hasResultError = computed(() =>
  focusedEntities.value.some(type => uiFlags.value[type.slice(0, -1)].hasError)
);
const showEmptySearchResults = computed(
  () =>
    searchStarted.value &&
    query.value &&
    isSelectedTabAll.value &&
    !isFetchingAny.value &&
    !hasResultError.value &&
    totalSearchResultsCount.value === 0
);
const showResultsSection = computed(
  () => searchStarted.value && query.value && !showEmptySearchResults.value
);
const showLoadMore = computed(
  () =>
    !isSelectedTabAll.value &&
    query.value &&
    !isFetchingAny.value &&
    searchState.value.pages[selectedTab.value] &&
    uiFlags.value[selectedTab.value.slice(0, -1)].hasMore
);
const showViewMore = computed(() =>
  Object.fromEntries(
    visibleEntities.value.map(type => {
      const count = entityCount(type);
      const records = searchState.value.pages[type]
        ? searchState.value[`${type.slice(0, -1)}Records`]
        : searchState.value.previews[type] || [];
      return [
        type,
        isSelectedTabAll.value &&
          (count === null
            ? records.length >= PREVIEW_PER_PAGE
            : count > PREVIEW_PER_PAGE),
      ];
    })
  )
);

const filters = ref({
  from: null,
  in: null,
  dateRange: { type: null, from: null, to: null },
});

const clearSearchResult = () => {
  countRequest.abort();
  Object.values(resultRequests).forEach(request => request.abort());
  searchStarted.value = false;
  store.dispatch('conversationSearch/clearSearchResults');
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
    ...(query.value?.trim() && { q: query.value.trim() }),
    ...generateURLParams(
      filters.value,
      isFeatureFlagEnabled(FEATURE_FLAGS.ADVANCED_SEARCH)
    ),
  };

  router.replace({ name: 'search', params, query: queryParams });
};

const fetchCounts = () =>
  countRequest.run(signal =>
    store.dispatch('conversationSearch/fetchCounts', {
      ...buildSearchPayload({ q: query.value, types: visibleEntities.value }),
      signal,
    })
  );

const fetchResults = (type, page = 1) =>
  resultRequests[type].run(signal =>
    store.dispatch(`conversationSearch/${type.slice(0, -1)}Search`, {
      ...buildSearchPayload(
        {
          q: query.value,
          page,
          ...(isSelectedTabAll.value && { perPage: PREVIEW_PER_PAGE }),
        },
        type
      ),
      signal,
    })
  );

const fetchFocusedResults = () => {
  Object.values(resultRequests).forEach(request => request.abort());
  store.dispatch('conversationSearch/cancelResultRequests');
  if (!query.value) return;
  focusedEntities.value.forEach(type => {
    const loaded =
      searchState.value.pages[type] ||
      (isSelectedTabAll.value &&
        Object.hasOwn(searchState.value.previews, type));
    if (!loaded) fetchResults(type);
  });
};

const retryResults = () => {
  focusedEntities.value.forEach(type => {
    if (uiFlags.value[type.slice(0, -1)].hasError) {
      fetchResults(
        type,
        isSelectedTabAll.value ? 1 : (searchState.value.pages[type] || 0) + 1
      );
    }
  });
};

const onSearch = q => {
  query.value = q.trim();
  clearSearchResult();
  if (!tabs.value.some(tab => tab.key === selectedTab.value))
    selectedTab.value = 'all';
  updateURL();
  if (!query.value || !visibleEntities.value.length) return;
  searchStarted.value = true;
  useTrack(CONVERSATION_EVENTS.SEARCH_CONVERSATION);
  fetchFocusedResults();
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
  if (!showLoadMore.value) return;
  fetchResults(
    selectedTab.value,
    searchState.value.pages[selectedTab.value] + 1
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
            :is-fetching-counts="uiFlags.isFetchingCounts"
            @tab-change="onTabChange"
          />
          <div
            v-if="query && (uiFlags.hasCountError || countBackendMismatch)"
            class="flex items-center gap-2 text-sm text-n-slate-11 mb-2"
          >
            <span>{{ t('SEARCH.COUNTS_UNAVAILABLE') }}</span>
            <NextButton
              :label="t('SEARCH.RETRY')"
              sm
              link
              :is-loading="uiFlags.isFetchingCounts"
              @click="fetchCounts"
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
                v-if="
                  filterContacts &&
                  (!uiFlags.contact.hasError || contacts.length)
                "
                :is-fetching="uiFlags.contact.isFetching"
                :contacts="contacts"
                :query="query"
                :show-title="isSelectedTabAll"
                class="mt-0.5"
              />
              <NextButton
                v-if="showViewMore.contacts"
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
                v-if="
                  filterMessages &&
                  (!uiFlags.message.hasError || messages.length)
                "
                :is-fetching="uiFlags.message.isFetching"
                :messages="messages"
                :query="query"
                :show-title="isSelectedTabAll"
                :class="searchResultSectionClass"
              />
              <NextButton
                v-if="showViewMore.messages"
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
                v-if="
                  filterConversations &&
                  (!uiFlags.conversation.hasError || conversations.length)
                "
                :is-fetching="uiFlags.conversation.isFetching"
                :conversations="conversations"
                :query="query"
                :show-title="isSelectedTabAll"
                :class="searchResultSectionClass"
              />
              <NextButton
                v-if="showViewMore.conversations"
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
                v-if="
                  filterArticles &&
                  (!uiFlags.article.hasError || articles.length)
                "
                :is-fetching="uiFlags.article.isFetching"
                :articles="articles"
                :query="query"
                :show-title="isSelectedTabAll"
                :class="searchResultSectionClass"
              />
              <NextButton
                v-if="showViewMore.articles"
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
                v-if="!isSelectedTabAll"
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
