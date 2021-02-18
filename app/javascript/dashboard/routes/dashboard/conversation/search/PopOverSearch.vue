<template>
  <div class="search-content">
    <div class="search-wrap">
      <div class="icon-text-wrap">
        <i class="ion-ios-search-strong search--icon" />
      </div>
      <input
        class="search--input"
        :placeholder="$t('CONVERSATION.SEARCH_MESSAGES')"
        @focus="onSearch"
        @blur="closeSearch"
      />
    </div>
    <div v-if="showSearchModal" class="list-wrap">
      <p class="result-wrap">
        Search Results
      </p>
      <div class="list-content">
        <result-item
          v-for="conversation in conversations"
          :key="conversation.id"
          conversation-id="6"
          user-name="John"
          timestamp=""
          message="Hi there"
        />
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
// import { frontendURL, conversationUrl } from '../../../../helper/URLHelper';
import timeMixin from '../../../../mixins/time';
import ResultItem from './ResultItem';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';

export default {
  components: {
    ResultItem,
  },
  mixins: [timeMixin, messageFormatterMixin],
  props: {},
  data() {
    return {
      showSearchModal: false,
    };
  },

  computed: {
    ...mapGetters({
      conversations: 'conversationSearch/getConversations',
      uiFlags: 'conversationSearch/getUIFlags',
      accountId: 'getCurrentAccountId',
    }),
  },

  mounted() {},

  methods: {
    onSearch() {
      this.showSearchModal = true;
    },
    closeSearch() {
      this.showSearchModal = false;
    },
  },
};
</script>

<style lang="scss" scoped>
.search-content {
  position: relative;
}
.search-wrap {
  display: flex;
}
.search--input {
  align-items: center;
  border: 0;
  color: var(--s-400);
  cursor: pointer;
  width: 100%;
  display: flex;
  font-size: var(--font-size-small);
  font-weight: 400;
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

.icon-text-wrap {
  display: flex;
}

.list-wrap {
  position: absolute;
  z-index: 10000;
  box-shadow: var(--shadow-large);
  background: white;
  width: 100%;
}
.list-content {
  list-style-type: none;
  font-size: var(--font-size-small);
  font-weight: 400;
}
.result-wrap {
  padding: var(--space-normal) var(--space-smaller) var(--space-smaller)
    var(--space-normal);
  border-top: 1px solid var(--b-200);
  font-size: var(--font-size-medium);
  font-weight: var(--font-weight-bold);
}
</style>
