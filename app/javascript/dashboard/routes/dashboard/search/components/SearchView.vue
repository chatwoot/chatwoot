<template>
  <section class="search-root">
    <header>
      <search-header @search="search" />
      <search-tabs :tabs="tabs" @tab-change="tab => (selectedTab = tab)" />
    </header>
    <div class="search-results">
      <woot-loading-state v-if="uiFlags.isFetching" :message="'Searching'" />
      <div v-else>
        <div v-if="all.length">
          <search-result-contacts-list
            v-if="filterContacts"
            :contacts="contacts"
          />
          <search-result-messages-list
            v-if="filterMessages"
            :messages="messages"
          />
          <search-result-conversations-list
            v-if="filterConversations"
            :conversations="conversations"
          />
        </div>
      </div>
    </div>
  </section>
</template>

<script>
import SearchHeader from './SearchHeader.vue';
import SearchTabs from './SearchTabs.vue';
import SearchResultConversationsList from './SearchResultConversationsList.vue';
import SearchResultMessagesList from './SearchResultMessagesList.vue';
import SearchResultContactsList from './SearchResultContactsList.vue';
import { mapGetters } from 'vuex';

export default {
  components: {
    SearchHeader,
    SearchTabs,
    SearchResultContactsList,
    SearchResultConversationsList,
    SearchResultMessagesList,
  },
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
    tabs() {
      return [
        {
          key: 'all',
          name: this.$t('SEARCH.TABS.ALL'),
          count:
            this.contacts.length +
            this.conversations.length +
            this.messages.length,
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
  },
  methods: {
    search(q) {
      this.$store.dispatch('conversationSearch/fullSearch', { q });
    },
  },
};
</script>

<style lang="scss" scoped>
header {
  padding: var(--space-large) var(--space-normal) 0 var(--space-normal);
}
.search-root {
  max-width: 800px;
  width: 100%;
  margin: 0 auto;
  height: 100%;
  display: flex;
  flex-direction: column;
  .search-results {
    flex-grow: 1;
    height: 100%;
    overflow-y: auto;
  }
}
</style>
