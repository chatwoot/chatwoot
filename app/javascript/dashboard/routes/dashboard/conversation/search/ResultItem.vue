<template>
  <div class="search-result" @click="onClick">
    <div class="result-header">
      <div class="message">
        <div>
          <span class="message-id"># {{ conversationId }}</span>
        </div>
      </div>
    </div>
    <search-message-item
      v-for="message in messages"
      :key="message.created_at"
      :user-name="message.sender_name"
      :timestamp="message.created_at"
      :message-type="message.message_type"
      :content="message.content"
      :search-term="searchTerm"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import SearchMessageItem from './SearchMessageItem.vue';

export default {
  components: { SearchMessageItem },
  mixins: [messageFormatterMixin],

  props: {
    conversationId: {
      type: Number,
      default: 0,
    },
    messages: {
      type: Array,
      default: () => [],
    },
    searchTerm: {
      type: String,
      default: '',
    },
  },

  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
  },

  methods: {
    onClick() {
      const path = conversationUrl({
        accountId: this.accountId,
        id: this.conversationId,
      });
      window.location = frontendURL(path);
    },
  },
};
</script>

<style lang="scss" scoped>
.search-result {
  display: block;
  align-items: center;
  border-bottom: 1px solid var(--color-border-light);
  color: var(--color-body);
  padding: var(--space-smaller) var(--space-normal) 0 var(--space-normal);

  &:last-child {
    border-bottom: none;
    padding-bottom: var(--space-two);
  }

  &:hover {
    background-color: var(--color-background-light);
    cursor: pointer;
  }
}

.result-header {
  display: flex;
  justify-content: space-between;
  padding: var(--space-micro) var(--space-zero) var(--space-micro) 0;
}

.message {
  display: flex;
}

.message-id {
  color: var(--w-600);
  font-size: var(--font-size-mini);
  font-weight: var(--font-weight-bold);
  background: var(--w-50);
  border-radius: var(--border-radius-normal);
  padding: var(--space-micro) var(--space-smaller);
}
</style>
