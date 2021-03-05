<template>
  <div v-on-clickaway="closeSearch" class="search-wrap">
    <div class="search" :class="{ 'is-active': showSearchBox }">
      <div class="icon">
        <i class="ion-ios-search-strong search--icon" />
      </div>
      <input
        v-model="searchTerm"
        class="search--input"
        :placeholder="$t('CONVERSATION.SEARCH_MESSAGES')"
        @focus="onSearch"
      />
    </div>
    <div v-if="showSearchBox" class="results-wrap">
      <div class="results">
        <div>
          <div class="result-view">
            <p class="result">
              Search Results
              <span class="message-counter">({{ resultsCount }})</span>
            </p>
            <div v-if="uiFlags.isFetching" class="search--activity-message">
              <woot-spinner size="" />
              {{ $t('CONVERSATION.SEARCH.LOADING_MESSAGE') }}
            </div>
          </div>

          <div v-if="showSearchResult" class="search-results--container">
            <result-item
              v-for="conversation in conversations"
              :key="conversation.messageId"
              :conversation-id="conversation.id"
              :user-name="conversation.sender_name"
              :timestamp="conversation.created_at"
              :message="conversation.content"
              :search-term="conversation.content"
              :message-type="conversation.message_type"
            />
          </div>
          <div v-else-if="showEmptyResult" class="search--activity-no-message">
            {{ $t('CONVERSATION.SEARCH.NO_MATCHING_RESULTS') }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';
import { mapGetters } from 'vuex';
import timeMixin from '../../../../mixins/time';
import ResultItem from './ResultItem';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';

export default {
  components: {
    ResultItem,
  },

  directives: {
    focus: {
      inserted(el) {
        el.focus();
      },
    },
  },

  mixins: [timeMixin, messageFormatterMixin, clickaway],

  data() {
    return {
      searchTerm: '',
      showSearchBox: false,
    };
  },

  computed: {
    ...mapGetters({
      conversations: 'conversationSearch/getConversations',
      uiFlags: 'conversationSearch/getUIFlags',
    }),
    resultsCount() {
      return this.conversations.length;
    },
    showSearchResult() {
      return (
        this.searchTerm && this.conversations.length && !this.uiFlags.isFetching
      );
    },
    showEmptyResult() {
      return (
        this.searchTerm &&
        !this.conversations.length &&
        !this.uiFlags.isFetching
      );
    },
  },

  watch: {
    searchTerm(newValue) {
      if (this.typingTimer) {
        clearTimeout(this.typingTimer);
      }

      this.typingTimer = setTimeout(() => {
        this.hasSearched = true;
        this.$store.dispatch('conversationSearch/get', { q: newValue });
      }, 1000);
    },
  },

  mounted() {
    this.$store.dispatch('conversationSearch/get', { q: '' });
  },

  methods: {
    onSearch() {
      this.showSearchBox = true;
    },
    closeSearch() {
      this.showSearchBox = false;
    },
  },
};
</script>

<style lang="scss" scoped>
.search-wrap {
  position: relative;
}

.search {
  display: flex;
  padding: 0;
  border-bottom: 1px solid transparent;

  &.is-active {
    border-bottom: 1px solid var(--b-200);
  }
}

.search--input {
  align-items: center;
  border: 0;
  color: var(--s-400);
  cursor: pointer;
  width: 100%;
  display: flex;
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-normal);
  padding: var(--space-normal) var(--space-smaller) var(--space-slab);
  text-align: left;
  line-height: var(--font-size-large);

  &:hover {
    .search--icon {
      color: var(--w-500);
    }
  }
}

.search--icon {
  color: var(--s-600);
  font-size: var(--font-size-large);
  padding: var(--space-normal) var(--space-small) var(--space-slab)
    var(--space-normal);
}

.icon {
  display: flex;
}

.results-wrap {
  position: absolute;
  z-index: 9999;
  box-shadow: var(--shadow-large);
  background: white;
  width: 100%;
  max-height: 42rem;
  overflow: scroll;
}

.results {
  list-style-type: none;
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-normal);
}

.result-view {
  display: flex;
  justify-content: space-between;
}

.result {
  padding: var(--space-normal) var(--space-smaller) var(--space-smaller)
    var(--space-normal);
  color: var(--s-700);
  font-size: var(--font-size-medium);
  font-weight: var(--font-weight-bold);

  .message-counter {
    color: var(--s-500);
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-bold);
  }
}

.search--activity-message {
  padding: var(--space-normal) var(--space-medium) var(--space-smaller)
    var(--space-zero);
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-medium);
  color: var(--s-500);
}

.search--activity-no-message {
  display: flex;
  justify-content: center;
  padding: var(--space-one) var(--space-zero) var(--space-two) var(--space-zero);
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-medium);
  color: var(--s-500);
}
</style>
