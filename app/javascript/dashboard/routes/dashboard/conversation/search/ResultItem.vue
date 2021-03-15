<template>
  <div class="search-result" @click="onClick">
    <div class="result-header">
      <div class="message">
        <i class="ion-ios-chatboxes-outline" />
        <div class="conversation">
          <div class="name-wrap">
            <span class="user-name">{{ userName }}</span>
            <div>
              <span class="conversation-id"># {{ conversationId }}</span>
            </div>
          </div>
          <span class="inbox-name">{{ inboxName }}</span>
        </div>
      </div>
      <span class="timestamp">{{ readableTime }} </span>
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
import timeMixin from 'dashboard/mixins/time';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import SearchMessageItem from './SearchMessageItem.vue';

export default {
  components: { SearchMessageItem },
  mixins: [timeMixin, messageFormatterMixin],

  props: {
    conversationId: {
      type: Number,
      default: 0,
    },
    userName: {
      type: String,
      default: '',
    },
    inboxName: {
      type: String,
      default: '',
    },
    timestamp: {
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
    readableTime() {
      if (!this.timestamp) {
        return '';
      }

      return this.dynamicTime(this.timestamp);
    },
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
  cursor: pointer;
  color: var(--color-body);
  padding: var(--space-smaller) var(--space-two) 0 var(--space-normal);

  &:last-child {
    border-bottom: none;
    padding-bottom: var(--space-normal);
  }
}

.result-header {
  display: flex;
  justify-content: space-between;
  background: var(--color-background);
  padding: var(--space-smaller) var(--space-slab);
  margin-bottom: var(--space-small);
  border-radius: var(--border-radius-medium);

  &:hover {
    background: var(--w-400);
    color: var(--white);
    .inbox-name {
      color: var(--white);
    }
    .timestamp {
      color: var(--white);
    }
    .ion-ios-chatboxes-outline {
      color: var(--white);
    }
    .conversation-id {
      background: var(--w-50);
      color: var(--s-500);
    }
  }
}

.message {
  display: flex;
}

.ion-ios-chatboxes-outline {
  align-items: center;
  display: flex;
  font-size: var(--font-size-large);
  color: var(--w-500);
}

.conversation {
  align-items: flex-start;
  display: flex;
  flex-direction: column;
  padding: var(--space-smaller) var(--space-one);
}

.name-wrap {
  display: flex;
  width: 20rem;

  .user-name {
    font-size: var(--font-size-default);
    font-weight: var(--font-weight-bold);
    margin-right: var(--space-micro);
    text-overflow: ellipsis;
    overflow: hidden;
    white-space: nowrap;
  }

  .conversation-id {
    background: var(--w-400);
    border-radius: var(--border-radius-normal);
    color: var(--w-50);
    align-items: center;
    font-size: var(--font-size-mini);
    font-weight: var(--font-weight-bold);
    padding: 0 var(--space-smaller);
    white-space: nowrap;
  }
}

.inbox-name {
  border-radius: var(--border-radius-normal);
  color: var(--s-500);
  font-size: var(--font-size-normal);
  font-weight: var(--font-weight-medium);
}

.timestamp {
  color: var(--s-500);
  font-weight: var(--font-weight-medium);
  font-size: var(--font-size-mini);
  margin-top: var(--space-smaller);
  text-align: right;
}
</style>
