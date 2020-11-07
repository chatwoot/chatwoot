<template>
  <woot-modal
    class="message-search--modal"
    :show.sync="show"
    :on-close="onClose"
  >
    <woot-modal-header :header-title="$t('CONVERSATION.SEARCH.TITLE')" />
    <div class="search--container">
      <input
        v-model="searchTerm"
        v-focus
        :placeholder="$t('CONVERSATION.SEARCH.PLACEHOLDER')"
        type="text"
      />

      <div v-if="uiFlags.isFetching" class="search--activity-message">
        <woot-spinner size="" />
        {{ $t('CONVERSATION.SEARCH.LOADING_MESSAGE') }}
      </div>

      <div
        v-if="searchTerm && conversations.length && !uiFlags.isFetching"
        class="search-results--container"
      >
        <div v-for="conversation in conversations" :key="conversation.id">
          <button
            v-for="message in conversation.messages"
            :key="message.id"
            class="search--messages"
            @click="() => onClick(conversation)"
          >
            <div class="search--messages__metadata">
              <span>#{{ conversation.id }}</span>
              <span>{{ dynamicTime(message.created_at) }}</span>
            </div>
            <div v-html="prepareContent(message.content)" />
          </button>
        </div>
      </div>

      <div
        v-else-if="
          searchTerm &&
            !conversations.length &&
            !uiFlags.isFetching &&
            hasSearched
        "
        class="search--activity-message"
      >
        {{ $t('CONVERSATION.SEARCH.NO_MATCHING_RESULTS') }}
      </div>
    </div>
  </woot-modal>
</template>

<script>
import { mapGetters } from 'vuex';
import { frontendURL, conversationUrl } from '../../../../helper/URLHelper';
import timeMixin from '../../../../mixins/time';

export default {
  directives: {
    focus: {
      inserted(el) {
        el.focus();
      },
    },
  },
  mixins: [timeMixin],
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    onClose: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return {
      searchTerm: '',
      hasSearched: false,
    };
  },
  computed: {
    ...mapGetters({
      conversations: 'conversationSearch/getConversations',
      uiFlags: 'conversationSearch/getUIFlags',
      accountId: 'getCurrentAccountId',
    }),
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
    prepareContent(content = '') {
      return content.replace(
        new RegExp(`(${this.searchTerm})`, 'ig'),
        '<span class="searchkey--highlight">$1</span>'
      );
    },
    onClick(conversation) {
      const path = conversationUrl({
        accountId: this.accountId,
        id: conversation.id,
      });
      window.location = frontendURL(path);
    },
  },
};
</script>

<style lang="scss">
.search--container {
  font-size: var(--font-size-default);
  padding: var(--space-normal) var(--space-large);
}

.search-results--container {
  max-height: 300px;
  overflow: scroll;
}

.searchkey--highlight {
  background: var(--w-500);
  color: var(--white);
}

.search--activity-message {
  color: var(--s-800);
  text-align: center;
}

.search--messages {
  border-bottom: 1px solid var(--b-100);
  color: var(--color-body);
  cursor: pointer;
  font-size: var(--font-size-small);
  line-height: 1.5;
  padding: var(--space-normal);
  text-align: left;
  width: 100%;

  &:hover {
    background: var(--w-50);
  }
}

.message-search--modal .modal-container {
  width: 800px;
  min-height: 460px;
}

.search--messages__metadata {
  display: flex;
  justify-content: space-between;
  margin-bottom: var(--space-small);
  color: var(--s-500);
}
</style>
