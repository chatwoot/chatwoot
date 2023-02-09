<template>
  <router-link :to="navigateTo" class="list-item">
    <thumbnail size="42px" :username="conversation.contact.name" />
    <div class="conversation-details">
      <div class="conversation-meta">
        <div class="left-column">
          <inbox-name :inbox="conversation.inbox" />
          <!-- <div class="agent-details">
            <thumbnail size="16px" :username="conversation.assignee.name" />
            <span>{{ conversation.assignee.name }}</span>
          </div> -->
          <span class="conversation-id">
            Conversation Id: {{ conversation.id }}
          </span>
        </div>
        <span class="timestamp">
          <time-ago :timestamp="conversation.created_at" />
        </span>
      </div>
      <p class="name">{{ conversation.contact.name }}</p>
      <div v-dompurify-html="messageContent" class="message-content" />
    </div>
  </router-link>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import InboxName from 'dashboard/components/widgets/InboxName.vue';
import timeAgo from 'dashboard/components/ui/TimeAgo';
import { mapGetters } from 'vuex';
import { frontendURL } from 'dashboard/helper/URLHelper.js';
export default {
  components: {
    Thumbnail,
    InboxName,
    timeAgo,
  },
  mixins: [messageFormatterMixin],
  props: {
    conversation: {
      type: Object,
      default: () => ({}),
    },
  },
  computed: {
    messageContent() {
      return this.formatMessage(this.conversation.message.content) || '';
    },
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
    navigateTo() {
      return frontendURL(
        `accounts/${this.accountId}/conversations/${this.conversation.id}`
      );
    },
  },
};
</script>

<style scoped lang="scss">
.list-item {
  width: 100%;
  text-align: left;
  display: flex;
  cursor: pointer;
  align-items: start;
  padding: var(--space-small);

  &:hover {
    background-color: var(--s-50);
  }

  .conversation-details {
    margin-left: var(--space-slab);
    flex-grow: 1;
    .name {
      margin: 0;
      color: var(--s-700);
      font-weight: var(--font-weight-bold);
      font-size: var(--font-size-default);
    }

    .message-content {
      margin: 0;
      color: var(--s-500);
      font-size: var(--font-size-small);
    }
    .details-meta > :not([hidden]) ~ :not([hidden]) {
      margin-right: calc(1rem * 0);
      margin-left: calc(1rem * calc(1 - 0));
    }
  }

  .conversation-meta {
    display: flex;
    align-items: center;
    justify-content: space-between;

    .left-column {
      display: flex;
      align-items: center;
      .agent-details {
        display: flex;
        align-items: center;
        margin-left: var(--space-slab);
        span {
          margin-left: var(--space-small);
        }
      }
      .conversation-id {
        margin-left: var(--space-slab);
        color: var(--s-500);
        font-size: var(--font-size-small);
      }
    }
  }
}
</style>
