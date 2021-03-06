<template>
  <div class="message-item">
    <div class="search-message">
      <div class="user-wrap">
        <div class="name-wrap">
          <span class="user-name">{{ userName }}</span>
          <i v-if="isOutgoingMessage" class="ion-headphone" />
        </div>
        <span class="timestamp">{{ readableTime }} </span>
      </div>
      <p class="message-content" v-html="prepareContent(content)"></p>
    </div>
  </div>
</template>

<script>
import { MESSAGE_TYPE } from 'shared/constants/messages';
import timeMixin from 'dashboard/mixins/time';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';

export default {
  mixins: [timeMixin, messageFormatterMixin],

  props: {
    userName: {
      type: String,
      default: '',
    },
    timestamp: {
      type: Number,
      default: 0,
    },
    messageType: {
      type: Number,
      default: 0,
    },
    content: {
      type: String,
      default: '',
    },
    searchTerm: {
      type: String,
      default: '',
    },
  },

  computed: {
    isOutgoingMessage() {
      return this.messageType === MESSAGE_TYPE.OUTGOING;
    },
    readableTime() {
      if (!this.timestamp) {
        return '';
      }
      return this.dynamicTime(this.timestamp);
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
  },
};
</script>
<style lang="scss" scoped>
.message-item {
  padding: 0 var(--space-small) 0 var(--space-small);
  &:last-child {
    .search-message {
      border-bottom: none;
    }
  }
}

.search-message {
  border-bottom: 1px solid #eee;
}

.user-wrap {
  display: flex;
  align-items: last baseline;
  justify-content: space-between;
}

.name-wrap {
  padding: var(--space-smaller) var(--space-smaller) 0 0;
}

.user-name {
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
  padding: var(--space-micro) var(--space-zero) var(--space-zero)
    var(--space-zero);
  &:hover {
    color: var(--s-400);
  }
}

.message-content::v-deep .searchkey--highlight {
  background: var(--w-50);
  color: var(--color-heading);
  font-weight: var(--font-weight-medium);
  padding: (var(--space-zero) var(--space-zero));
}
</style>
