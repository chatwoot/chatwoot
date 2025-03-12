<script>
import SearchHeader from './SearchHeader.vue';
import SearchTabs from './SearchTabs.vue';
import SearchResultConversationsList from './SearchResultConversationsList.vue';
import SearchResultMessagesList from './SearchResultMessagesList.vue';
import SearchResultContactsList from './SearchResultContactsList.vue';
import ButtonV4 from 'dashboard/components-next/button/Button.vue';
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
    ButtonV4,
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
  <div class="flex flex-col w-full bg-n-background">
    <div class="flex p-4">
      <ButtonV4
        :label="$t('GENERAL_SETTINGS.BACK')"
        icon="i-lucide-chevron-left"
        faded
        primary
        sm
        @click="onBack"
      />
    </div>
    <section
      class="flex my-0 p-4 relative mx-auto max-w-[45rem] min-h-[20rem] flex-col w-full h-full bg-n-background"
    >
      <header>
        <SearchHeader @search="onSearch" />
        <SearchTabs
          v-if="query"
          :tabs="tabs"
          :selected-tab="activeTabIndex"
          @tab-change="tab => (selectedTab = tab)"
        />
      </header>
      <div class="flex-grow h-full px-2 py-0 overflow-y-auto">
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
        <div
          v-else-if="showEmptySearchResults"
          class="flex flex-col items-center justify-center px-4 py-6 mt-8 rounded-md"
        >
          <fluent-icon icon="info" size="16px" class="text-n-slate-11" />
          <p class="m-2 text-center text-n-slate-11">
            {{ $t('SEARCH.EMPTY_STATE_FULL', { query }) }}
          </p>
        </div>
        <div
          v-else
          class="flex flex-col items-center justify-center px-4 py-6 mt-8 text-center rounded-md"
        >
          <p class="text-center margin-bottom-0">
            <fluent-icon icon="search" size="24px" class="text-n-slate-11" />
          </p>
          <p class="m-2 text-center text-n-slate-11">
            {{ $t('SEARCH.EMPTY_STATE_DEFAULT') }}
          </p>
        </div>
      </div>
    </section>
  </div>
</template>
