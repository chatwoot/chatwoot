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
        <search-header @search="onSearch" />
        <search-tabs
          v-if="query"
          :tabs="tabs"
          @tab-change="tab => (selectedTab = tab)"
        />
      </header>
      <div class="search-results">
        <div v-if="showResultsSection">
          <search-result-contacts-list
            v-if="filterContacts"
            :is-fetching="uiFlags.contact.isFetching"
            :contacts="contacts"
            :query="query"
            :show-title="isSelectedTabAll"
          />

          <search-result-messages-list
            v-if="filterMessages"
            :is-fetching="uiFlags.message.isFetching"
            :messages="messages"
            :query="query"
            :show-title="isSelectedTabAll"
          />

          <search-result-conversations-list
            v-if="filterConversations"
            :is-fetching="uiFlags.conversation.isFetching"
            :conversations="conversations"
            :query="query"
            :show-title="isSelectedTabAll"
          />
        </div>
        <div v-else-if="showEmptySearchResults" class="empty">
          <fluent-icon icon="info" size="16px" class="icon" />
          <p class="empty-state__text">
            {{ $t('SEARCH.EMPTY_STATE_FULL', { query }) }}
          </p>
        </div>
        <div v-else class="empty text-center">
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

<script>
import SearchHeader from './SearchHeader.vue';
import SearchTabs from './SearchTabs.vue';
import SearchResultConversationsList from './SearchResultConversationsList.vue';
import SearchResultMessagesList from './SearchResultMessagesList.vue';
import SearchResultContactsList from './SearchResultContactsList.vue';

import { mixin as clickaway } from 'vue-clickaway';
import { mapGetters } from 'vuex';
import { CONVERSATION_EVENTS } from '../../../helper/AnalyticsHelper/events';
export default {
  components: {
    SearchHeader,
    SearchTabs,
    SearchResultContactsList,
    SearchResultConversationsList,
    SearchResultMessagesList,
  },
  mixins: [clickaway],
  data() {
    return {
      selectedTab: 'all',
      query: '',
    };
  },

  computed: {
    ...mapGetters({
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
    totalSearchResultsCount() {
      return (
        this.contacts.length + this.conversations.length + this.messages.length
      );
    },
    tabs() {
      return [
        {
          key: 'all',
          name: this.$t('SEARCH.TABS.ALL'),
          count: this.totalSearchResultsCount,
        },
        {
          key: 'contacts',
          name: this.$t('SEARCH.TABS.CONTACTS'),
          count: this.contacts.length,
        },
        {
          key: 'conversations',
          name: this.$t('SEARCH.TABS.CONVERSATIONS'),
          count: this.conversations.length,
        },
        {
          key: 'messages',
          name: this.$t('SEARCH.TABS.MESSAGES'),
          count: this.messages.length,
        },
      ];
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
  beforeDestroy() {
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
      this.$track(CONVERSATION_EVENTS.SEARCH_CONVERSATION);
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

<style lang="scss" scoped>
.search-page {
  display: flex;
  flex-direction: column;
  width: 100%;
}
.page-header {
  display: flex;
  padding: var(--space-normal);
}
.search-root {
  margin: 0 auto;
  max-width: 72rem;
  min-height: 32rem;
  width: 100%;
  height: 100%;
  padding: var(--space-normal);
  display: flex;
  position: relative;
  flex-direction: column;
  background: white;
  margin-top: var(--space-medium);

  .search-results {
    flex-grow: 1;
    height: 100%;
    overflow-y: auto;
    padding: 0 var(--space-small);
  }
}

.empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: var(--space-medium) var(--space-normal);
  border-radius: var(--border-radius-medium);
  margin-top: var(--space-large);
  .icon {
    color: var(--s-500);
  }
  .empty-state__text {
    text-align: center;
    color: var(--s-500);
    margin: var(--space-small);
  }
}
</style>
