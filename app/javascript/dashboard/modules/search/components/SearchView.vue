<template>
  <div class="backdrop">
    <section v-on-clickaway="closeSearch" class="search-root">
      <woot-button
        color-scheme="secondary"
        size="large"
        icon="dismiss"
        variant="smooth"
        class="modal--close"
        @click="onBack"
      />
      <header>
        <search-header @search="search" />
        <search-tabs
          v-if="!showEmptySearchResults && all.length"
          :tabs="tabs"
          @tab-change="tab => (selectedTab = tab)"
        />
      </header>
      <div class="search-results">
        <woot-loading-state v-if="uiFlags.isFetching" :message="'Searching'" />
        <div v-else>
          <div v-if="all.length">
            <search-result-contacts-list
              v-if="filterContacts"
              :contacts="contacts"
              :query="query"
              @close-search="closeSearch"
            />
            <search-result-messages-list
              v-if="filterMessages"
              :messages="messages"
              :query="query"
              @close-search="closeSearch"
            />
            <search-result-conversations-list
              v-if="filterConversations"
              :conversations="conversations"
              :query="query"
            />
          </div>
          <div v-else-if="showEmptySearchResults && !all.length" class="empty">
            <fluent-icon icon="info" size="16px" class="icon" />
            <p class="empty-state__text">
              {{ $t('SEARCH.EMPTY_STATE_FULL', { query }) }}
            </p>
          </div>
          <div v-else class="empty text-center">
            <p class="text-center">
              <fluent-icon icon="search" size="24px" class="icon" />
            </p>
            <p class="empty-state__text">
              {{ $t('SEARCH.EMPTY_STATE_DEFAULT') }}
            </p>
          </div>
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
import { isEmptyObject } from 'dashboard/helper/commons.js';

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
      fullSearchRecords: 'conversationSearch/getFullSearchRecords',
      uiFlags: 'conversationSearch/getUIFlags',
    }),
    contacts() {
      if (this.fullSearchRecords.contacts) {
        return this.fullSearchRecords.contacts.map(contact => ({
          ...contact,
          type: 'contact',
        }));
      }
      return [];
    },
    conversations() {
      if (this.fullSearchRecords.conversations) {
        return this.fullSearchRecords.conversations.map(conversation => ({
          ...conversation,
          type: 'conversation',
        }));
      }
      return [];
    },
    messages() {
      if (this.fullSearchRecords.messages) {
        return this.fullSearchRecords.messages.map(message => ({
          ...message,
          type: 'message',
        }));
      }
      return [];
    },
    all() {
      return [...this.contacts, ...this.conversations, ...this.messages];
    },
    filterContacts() {
      return this.selectedTab === 'contacts' || this.selectedTab === 'all';
    },
    filterConversations() {
      return this.selectedTab === 'conversations' || this.selectedTab === 'all';
    },
    filterMessages() {
      return this.selectedTab === 'messages' || this.selectedTab === 'all';
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
        !isEmptyObject(this.fullSearchRecords)
      );
    },
  },
  beforeDestroy() {
    this.query = '';
    this.$store.dispatch('conversationSearch/clearSearchResults');
  },
  methods: {
    search(q) {
      this.query = q;
      this.$track(CONVERSATION_EVENTS.SEARCH_CONVERSATION);
      this.$store.dispatch('conversationSearch/fullSearch', { q });
    },
    onBack() {
      this.$emit('close');
    },
    closeSearch() {
      this.$emit('close');
    },
  },
};
</script>

<style lang="scss" scoped>
.backdrop {
  position: fixed;
  top: 0;
  width: 100%;
  height: 100%;
  background: var(--white-transparent);
  z-index: var(--z-index-very-high);
}
.search-root {
  max-width: 56rem;
  min-height: 32rem;
  width: 100%;
  height: fit-content;
  box-shadow: var(--shadow-larger);
  display: flex;
  position: relative;
  flex-direction: column;
  background: white;
  border-radius: var(--border-radius-large);
  margin-top: var(--space-normal);
  border-top: 1px solid var(--s-25);
  .search-results {
    flex-grow: 1;
    height: 100%;
    max-height: 80vh;
    overflow-y: auto;
    padding: var(--space-small) var(--space-normal);
  }
}
.modal--close {
  position: fixed;
  right: var(--space-small);
  top: var(--space-small);
}

.empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: var(--space-medium) var(--space-normal);
  border-radius: var(--border-radius-medium);
  .icon {
    color: var(--s-500);
  }
  .empty-state__text {
    text-align: center;
    color: var(--s-500);
    margin: 0 var(--space-small);
  }
}
</style>
