<script>
import SearchHeader from './SearchHeader.vue';
import SearchTabs from './SearchTabs.vue';
import SearchResultConversationsList from './SearchResultConversationsList.vue';
import SearchResultMessagesList from './SearchResultMessagesList.vue';
import SearchResultContactsList from './SearchResultContactsList.vue';
import { useTrack } from 'dashboard/composables';
import Policy from 'dashboard/components/policy.vue';
import {
  ROLES,
  CONVERSATION_PERMISSIONS,
  CONTACT_PERMISSIONS,
} from 'dashboard/constants/permissions.js';
import {
  getUserPermissions,
  filterItemsByPermission,
} from 'dashboard/helper/permissionsHelper.js';

import { mapGetters } from 'vuex';
import { CONVERSATION_EVENTS } from '../../../helper/AnalyticsHelper/events';

export default {
  components: {
    SearchHeader,
    SearchTabs,
    SearchResultContactsList,
    SearchResultConversationsList,
    SearchResultMessagesList,
    Policy,
  },
  data() {
    return {
      selectedTab: 'all',
      query: '',
      contactPermissions: CONTACT_PERMISSIONS,
      conversationPermissions: CONVERSATION_PERMISSIONS,
      rolePermissions: ROLES,
    };
  },

  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      currentAccountId: 'getCurrentAccountId',
      contactRecords: 'conversationSearch/getContactRecords',
      conversationRecords: 'conversationSearch/getConversationRecords',
      messageRecords: 'conversationSearch/getMessageRecords',
      uiFlags: 'conversationSearch/getUIFlags',
    }),
    contacts() {
      return this.contactRecords.map(contact => ({
        ...contact,
        type: 'contact',
      }));
    },
    conversations() {
      return this.conversationRecords.map(conversation => ({
        ...conversation,
        type: 'conversation',
      }));
    },
    messages() {
      return this.messageRecords.map(message => ({
        ...message,
        type: 'message',
      }));
    },
    all() {
      return [...this.contacts, ...this.conversations, ...this.messages];
    },
    filterContacts() {
      return this.selectedTab === 'contacts' || this.isSelectedTabAll;
    },
    filterConversations() {
      return this.selectedTab === 'conversations' || this.isSelectedTabAll;
    },
    filterMessages() {
      return this.selectedTab === 'messages' || this.isSelectedTabAll;
    },
    userPermissions() {
      return getUserPermissions(this.currentUser, this.currentAccountId);
    },
    totalSearchResultsCount() {
      const permissionCounts = {
        contacts: {
          permissions: [...this.rolePermissions, this.contactPermissions],
          count: () => this.contacts.length,
        },
        conversations: {
          permissions: [
            ...this.rolePermissions,
            ...this.conversationPermissions,
          ],
          count: () => this.conversations.length + this.messages.length,
        },
      };

      const filteredCounts = filterItemsByPermission(
        permissionCounts,
        this.userPermissions,
        item => item.permissions,
        (_, item) => item.count
      );

      return filteredCounts.reduce((total, count) => total + count(), 0);
    },
    tabs() {
      const allTabsConfig = {
        all: {
          key: 'all',
          name: this.$t('SEARCH.TABS.ALL'),
          count: this.totalSearchResultsCount,
          permissions: [
            this.contactPermissions,
            ...this.rolePermissions,
            ...this.conversationPermissions,
          ],
        },
        contacts: {
          key: 'contacts',
          name: this.$t('SEARCH.TABS.CONTACTS'),
          count: this.contacts.length,
          permissions: [...this.rolePermissions, this.contactPermissions],
        },
        conversations: {
          key: 'conversations',
          name: this.$t('SEARCH.TABS.CONVERSATIONS'),
          count: this.conversations.length,
          permissions: [
            ...this.rolePermissions,
            ...this.conversationPermissions,
          ],
        },
        messages: {
          key: 'messages',
          name: this.$t('SEARCH.TABS.MESSAGES'),
          count: this.messages.length,
          permissions: [
            ...this.rolePermissions,
            ...this.conversationPermissions,
          ],
        },
      };

      return filterItemsByPermission(
        allTabsConfig,
        this.userPermissions,
        item => item.permissions
      );
    },
    activeTabIndex() {
      const index = this.tabs.findIndex(tab => tab.key === this.selectedTab);
      return index >= 0 ? index : 0;
    },
    showEmptySearchResults() {
      return (
        this.totalSearchResultsCount === 0 &&
        this.uiFlags.isSearchCompleted &&
        !this.uiFlags.isFetching &&
        this.query
      );
    },
    showResultsSection() {
      return (
        (this.uiFlags.isSearchCompleted &&
          this.totalSearchResultsCount !== 0) ||
        this.uiFlags.isFetching
      );
    },
    isSelectedTabAll() {
      return this.selectedTab === 'all';
    },
  },
  unmounted() {
    this.query = '';
    this.$store.dispatch('conversationSearch/clearSearchResults');
  },
  mounted() {
    this.$store.dispatch('conversationSearch/clearSearchResults');
  },
  methods: {
    onSearch(q) {
      this.selectedTab = 'all';
      this.query = q;
      if (!q) {
        this.$store.dispatch('conversationSearch/clearSearchResults');
        return;
      }
      useTrack(CONVERSATION_EVENTS.SEARCH_CONVERSATION);
      this.$store.dispatch('conversationSearch/fullSearch', { q });
    },
    onBack() {
      if (window.history.length > 2) {
        this.$router.go(-1);
      } else {
        this.$router.push({ name: 'home' });
      }
    },
  },
};
</script>

<template>
  <div class="search-page">
    <div class="page-header">
      <woot-button
        icon="chevron-left"
        variant="smooth"
        size="small "
        class="back-button"
        @click="onBack"
      >
        {{ $t('GENERAL_SETTINGS.BACK') }}
      </woot-button>
    </div>
    <section class="search-root">
      <header>
        <SearchHeader @search="onSearch" />
        <SearchTabs
          v-if="query"
          :tabs="tabs"
          :selected-tab="activeTabIndex"
          @tab-change="tab => (selectedTab = tab)"
        />
      </header>
      <div class="search-results">
        <div v-if="showResultsSection">
          <Policy :permissions="[...rolePermissions, contactPermissions]">
            <SearchResultContactsList
              v-if="filterContacts"
              :is-fetching="uiFlags.contact.isFetching"
              :contacts="contacts"
              :query="query"
              :show-title="isSelectedTabAll"
            />
          </Policy>

          <Policy
            :permissions="[...rolePermissions, ...conversationPermissions]"
          >
            <SearchResultMessagesList
              v-if="filterMessages"
              :is-fetching="uiFlags.message.isFetching"
              :messages="messages"
              :query="query"
              :show-title="isSelectedTabAll"
            />
          </Policy>

          <Policy
            :permissions="[...rolePermissions, ...conversationPermissions]"
          >
            <SearchResultConversationsList
              v-if="filterConversations"
              :is-fetching="uiFlags.conversation.isFetching"
              :conversations="conversations"
              :query="query"
              :show-title="isSelectedTabAll"
            />
          </Policy>
        </div>
        <div v-else-if="showEmptySearchResults" class="empty">
          <fluent-icon icon="info" size="16px" class="icon" />
          <p class="empty-state__text">
            {{ $t('SEARCH.EMPTY_STATE_FULL', { query }) }}
          </p>
        </div>
        <div v-else class="text-center empty">
          <p class="text-center margin-bottom-0">
            <fluent-icon icon="search" size="24px" class="icon" />
          </p>
          <p class="empty-state__text">
            {{ $t('SEARCH.EMPTY_STATE_DEFAULT') }}
          </p>
        </div>
      </div>
    </section>
  </div>
</template>

<style lang="scss" scoped>
.search-page {
  @apply flex flex-col w-full bg-white dark:bg-slate-900;
}
.page-header {
  @apply flex p-4;
}
.search-root {
  @apply flex my-0 p-4 relative mx-auto max-w-[45rem] min-h-[20rem] flex-col w-full h-full bg-white dark:bg-slate-900;

  .search-results {
    @apply flex-grow h-full overflow-y-auto py-0 px-2;
  }
}

.empty {
  @apply flex flex-col items-center justify-center py-6 px-4 rounded-md mt-8;
  .icon {
    @apply text-slate-500 dark:text-slate-400;
  }
  .empty-state__text {
    @apply text-center text-slate-500 dark:text-slate-400 m-2;
  }
}
</style>
