<template>
  <div class="search-result" @click="onClick">
    <div class="result-header">
      <div class="message">
        <div>
          <span class="message-id"># {{ conversationId }}</span>
        </div>
        <div class="user-wrap">
          <span class="user-name">{{ userName }}</span>
          <i v-if="isOutgoingMessage" class="ion-headphone" />
        </div>
      </div>
      <span class="timestamp">{{ readableTime }}</span>
    </div>
    <div>
      <p class="message-content" v-html="prepareContent(message)"></p>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import timeMixin from 'dashboard/mixins/time';
import { MESSAGE_TYPE } from 'shared/constants/messages';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';

export default {
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
    message: {
      type: String,
      default: '',
    },
    timestamp: {
      type: Number,
      default: 0,
    },
    searchTerm: {
      type: String,
      default: '',
    },
    messageType: {
      type: Number,
      default: 0,
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
    isOutgoingMessage() {
      return this.messageType === MESSAGE_TYPE.OUTGOING;
    },
  },

  methods: {
    prepareContent(content = '') {
      const plainTextContent = this.getPlainText(content);
      return plainTextContent.replace(
        new RegExp(`(${this.searchTerm})`, 'ig'),
        '<span class="searchkey--highlight">$1</span>'
      );
    },
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
  padding: var(--space-smaller) var(--space-micro) var(--space-zero)
    var(--space-normal);
}

.search-result:last-child {
  border-bottom: none;
  padding-bottom: var(--space-two);
}

.search-result:hover {
  background-color: var(--color-background);
}

.result-header {
  display: flex;
  justify-content: space-between;
  padding: var(--space-small) var(--space-normal) var(--space-smaller)
    var(--space-zero);
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

.user-wrap {
  display: flex;
  align-items: last baseline;
}

.user-name {
  padding-right: var(--space-smaller);
  padding-left: var(--space-smaller);
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-bold);
  color: var(--b-800);
}

.ion-headphone {
  color: var(--w-500);
  padding: var(--space-micro);
  padding-right: var(--space-smaller);
  font-size: var(--font-size-mini);
}

.timestamp {
  font-size: var(--font-size-mini);
}

p {
  max-width: 100%;
}

.message-content {
  padding: var(--space-micro) var(--space-normal) var(--space-zero)
    var(--space-zero);
}

.message-content::v-deep .searchkey--highlight {
  background: var(--g-50);
  color: var(--color-heading);
  font-weight: var(--font-weight-medium);
  padding: (var(--space-zero) var(--space-micro));
}
</style>
