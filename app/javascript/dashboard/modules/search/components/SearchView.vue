<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useRouter } from 'vue-router';
import { useTrack } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import {
  ROLES,
  CONVERSATION_PERMISSIONS,
  CONTACT_PERMISSIONS,
} from 'dashboard/constants/permissions.js';
import {
  getUserPermissions,
  filterItemsByPermission,
} from 'dashboard/helper/permissionsHelper.js';
import { CONVERSATION_EVENTS } from '../../../helper/AnalyticsHelper/events';

import Policy from 'dashboard/components/policy.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SearchHeader from './SearchHeader.vue';
import SearchTabs from './SearchTabs.vue';
import SearchResultConversationsList from './SearchResultConversationsList.vue';
import SearchResultMessagesList from './SearchResultMessagesList.vue';
import SearchResultContactsList from './SearchResultContactsList.vue';

const router = useRouter();
const store = useStore();
const { t } = useI18n();

const PER_PAGE = 15; // Results per page
const selectedTab = ref('all');
const query = ref('');
const pages = ref({
  contacts: 1,
  conversations: 1,
  messages: 1,
});

const currentUser = useMapGetter('getCurrentUser');
const currentAccountId = useMapGetter('getCurrentAccountId');
const contactRecords = useMapGetter('conversationSearch/getContactRecords');
const conversationRecords = useMapGetter(
  'conversationSearch/getConversationRecords'
);
const messageRecords = useMapGetter('conversationSearch/getMessageRecords');
const uiFlags = useMapGetter('conversationSearch/getUIFlags');

const addTypeToRecords = (records, type) =>
  records.value.map(item => ({ ...item, type }));

const mappedContacts = computed(() =>
  addTypeToRecords(contactRecords, 'contact')
);
const mappedConversations = computed(() =>
  addTypeToRecords(conversationRecords, 'conversation')
);
const mappedMessages = computed(() =>
  addTypeToRecords(messageRecords, 'message')
);

const isSelectedTabAll = computed(() => selectedTab.value === 'all');

const sliceRecordsIfAllTab = items =>
  isSelectedTabAll.value ? items.value.slice(0, 5) : items.value;

const contacts = computed(() => sliceRecordsIfAllTab(mappedContacts));
const conversations = computed(() => sliceRecordsIfAllTab(mappedConversations));
const messages = computed(() => sliceRecordsIfAllTab(mappedMessages));

const filterByTab = tab =>
  computed(() => selectedTab.value === tab || isSelectedTabAll.value);

const filterContacts = filterByTab('contacts');
const filterConversations = filterByTab('conversations');
const filterMessages = filterByTab('messages');

const userPermissions = computed(() =>
  getUserPermissions(currentUser.value, currentAccountId.value)
);

const TABS_CONFIG = {
  all: {
    permissions: [CONTACT_PERMISSIONS, ...ROLES, ...CONVERSATION_PERMISSIONS],
    count: () => null, // No count for all tab
  },
  contacts: {
    permissions: [...ROLES, CONTACT_PERMISSIONS],
    count: () => mappedContacts.value.length,
  },
  conversations: {
    permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
    count: () => mappedConversations.value.length,
  },
  messages: {
    permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
    count: () => mappedMessages.value.length,
  },
};

const tabs = computed(() => {
  const configs = Object.entries(TABS_CONFIG).map(([key, config]) => ({
    key,
    name: t(`SEARCH.TABS.${key.toUpperCase()}`),
    count: config.count(),
    showBadge: key !== 'all',
    permissions: config.permissions,
  }));

  return filterItemsByPermission(
    configs,
    userPermissions.value,
    item => item.permissions
  );
});

const totalSearchResultsCount = computed(() => {
  const permissionCounts = {
    contacts: {
      permissions: [...ROLES, CONTACT_PERMISSIONS],
      count: () => contacts.value.length,
    },
    conversations: {
      permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
      count: () => conversations.value.length + messages.value.length,
    },
  };
  return filterItemsByPermission(
    permissionCounts,
    userPermissions.value,
    item => item.permissions,
    (_, item) => item.count
  ).reduce((total, count) => total + count(), 0);
});

const activeTabIndex = computed(() => {
  const index = tabs.value.findIndex(tab => tab.key === selectedTab.value);
  return index >= 0 ? index : 0;
});

const isFetchingAny = computed(() => {
  const { contact, message, conversation, isFetching } = uiFlags.value;
  return (
    isFetching ||
    contact.isFetching ||
    message.isFetching ||
    conversation.isFetching
  );
});

const showEmptySearchResults = computed(
  () =>
    totalSearchResultsCount.value === 0 &&
    uiFlags.value.isSearchCompleted &&
    isSelectedTabAll.value &&
    !isFetchingAny.value &&
    query.value
);

const showResultsSection = computed(
  () =>
    (uiFlags.value.isSearchCompleted && totalSearchResultsCount.value !== 0) ||
    isFetchingAny.value ||
    (!isSelectedTabAll.value && query.value && !isFetchingAny.value)
);

const showLoadMore = computed(() => {
  if (!query.value || isFetchingAny.value || selectedTab.value === 'all')
    return false;

  const records = {
    contacts: mappedContacts.value,
    conversations: mappedConversations.value,
    messages: mappedMessages.value,
  }[selectedTab.value];

  return (
    records?.length > 0 &&
    records.length === pages.value[selectedTab.value] * PER_PAGE
  );
});

const showViewMore = computed(() => ({
  // Hide view more button if the number of records is less than 5
  contacts: mappedContacts.value?.length > 5 && isSelectedTabAll.value,
  conversations:
    mappedConversations.value?.length > 5 && isSelectedTabAll.value,
  messages: mappedMessages.value?.length > 5 && isSelectedTabAll.value,
}));

const clearSearchResult = () => {
  pages.value = { contacts: 1, conversations: 1, messages: 1 };
  store.dispatch('conversationSearch/clearSearchResults');
};

const onSearch = q => {
  query.value = q;
  clearSearchResult();
  if (!q) return;
  useTrack(CONVERSATION_EVENTS.SEARCH_CONVERSATION);
  store.dispatch('conversationSearch/fullSearch', { q, page: 1 });
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
  const SEARCH_ACTIONS = {
    contacts: 'conversationSearch/contactSearch',
    conversations: 'conversationSearch/conversationSearch',
    messages: 'conversationSearch/messageSearch',
  };

  if (uiFlags.value.isFetching || selectedTab.value === 'all') return;
  const tab = selectedTab.value;
  pages.value[tab] += 1;
  store.dispatch(SEARCH_ACTIONS[tab], {
    q: query.value,
    page: pages.value[tab],
  });
};

onMounted(() => {
  store.dispatch('conversationSearch/clearSearchResults');
});

onUnmounted(() => {
  query.value = '';
  store.dispatch('conversationSearch/clearSearchResults');
});
</script>

<template>
  <div class="flex flex-col w-full h-full bg-n-background">
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
      <div class="w-full max-w-4xl mx-auto">
        <div class="flex flex-col w-full px-4">
          <SearchHeader @search="onSearch" />
          <SearchTabs
            v-if="query"
            :tabs="tabs"
            :selected-tab="activeTabIndex"
            @tab-change="tab => (selectedTab = tab)"
          />
        </div>
      </div>
      <div class="flex-grow w-full h-full overflow-y-auto">
        <div class="w-full max-w-4xl mx-auto px-4 pb-6">
          <div v-if="showResultsSection">
            <Policy
              :permissions="[...ROLES, CONTACT_PERMISSIONS]"
              class="flex flex-col justify-center"
            >
              <SearchResultContactsList
                v-if="filterContacts"
                :is-fetching="uiFlags.contact.isFetching"
                :contacts="contacts"
                :query="query"
                :show-title="isSelectedTabAll"
              />
              <NextButton
                v-if="showViewMore.contacts"
                :label="t(`SEARCH.VIEW_MORE`)"
                icon="i-lucide-eye"
                slate
                sm
                outline
                @click="selectedTab = 'contacts'"
              />
            </Policy>

            <Policy
              :permissions="[...ROLES, ...CONVERSATION_PERMISSIONS]"
              class="flex flex-col justify-center"
            >
              <SearchResultMessagesList
                v-if="filterMessages"
                :is-fetching="uiFlags.message.isFetching"
                :messages="messages"
                :query="query"
                :show-title="isSelectedTabAll"
              />
              <NextButton
                v-if="showViewMore.messages"
                :label="t(`SEARCH.VIEW_MORE`)"
                icon="i-lucide-eye"
                slate
                sm
                outline
                @click="selectedTab = 'messages'"
              />
            </Policy>

            <Policy
              :permissions="[...ROLES, ...CONVERSATION_PERMISSIONS]"
              class="flex flex-col justify-center"
            >
              <SearchResultConversationsList
                v-if="filterConversations"
                :is-fetching="uiFlags.conversation.isFetching"
                :conversations="conversations"
                :query="query"
                :show-title="isSelectedTabAll"
              />
              <NextButton
                v-if="showViewMore.conversations"
                :label="t(`SEARCH.VIEW_MORE`)"
                icon="i-lucide-eye"
                slate
                sm
                outline
                @click="selectedTab = 'conversations'"
              />
            </Policy>

            <div v-if="showLoadMore" class="flex justify-center mt-4 mb-6">
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
