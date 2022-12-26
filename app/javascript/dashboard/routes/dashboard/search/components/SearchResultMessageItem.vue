<template>
  <router-link :to="navigateTo" class="list-item">
    <thumbnail :src="getThumbnail" size="42px" :username="getName" />
    <div class="message-details">
      <div class="conversation-meta">
        <p class="inbox-name">
          <inbox-name :inbox="message.inbox" />
        </p>
        <div>
          <span class="timestamp">
            <time-ago :timestamp="message.created_at" />
          </span>
          <p class="conversation-id">Conv: {{ message.conversation_id }}</p>
        </div>
      </div>
      <p class="name">{{ getName }}</p>
      <read-more :shrink="isOverflowing" @expand="isOverflowing = false">
        <div
          ref="messageContainer"
          v-dompurify-html="messageContent"
          class="message-content"
        />
      </read-more>
    </div>
  </router-link>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import InboxName from 'dashboard/components/widgets/InboxName.vue';
import timeAgo from 'dashboard/components/ui/TimeAgo';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import { mapGetters } from 'vuex';
import { frontendURL } from 'dashboard/helper/URLHelper.js';
import ReadMore from './ReadMore';
export default {
  components: {
    Thumbnail,
    ReadMore,
    InboxName,
    timeAgo,
  },
  mixins: [messageFormatterMixin],
  props: {
    message: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      isOverflowing: false,
    };
  },
  computed: {
    messageContent() {
      return this.formatMessage(this.message.content);
    },
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
    navigateTo() {
      return frontendURL(
        `accounts/${this.accountId}/conversations/${this.message.conversation_id}`
      );
    },
    getThumbnail() {
      return this.message.sender && this.message.sender.thumbnail
        ? this.message.sender.thumbnail
        : this.$t('SEARCH.BOT_LABEL');
    },
    getName() {
      return this.message && this.message.sender && this.message.sender.name
        ? this.message.sender.name
        : this.$t('SEARCH.BOT_LABEL');
    },
  },
  mounted() {
    this.$nextTick(() => {
      this.isOverflowing = this.$refs.messageContainer.offsetHeight > 150;
    });
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

  .message-details {
    margin-left: var(--space-slab);
    flex: 1;
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
  &:hover {
    background-color: var(--s-50);
    ::v-deep {
      &::after {
        background: linear-gradient(
          to bottom,
          rgba(255, 255, 255, 0),
          var(--s-50) 100%
        );
      }
    }
  }

  .conversation-meta {
    display: flex;
    align-items: start;
    justify-content: space-between;
    .timestamp {
      color: var(--s-500);
      font-size: var(--font-size-small);
    }
    .conversation-id {
      text-align: right;
    }

    .inbox-name {
      margin: var(--space-small) 0;
    }
  }
}
</style>
