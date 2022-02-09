<template>
  <div class="message-item">
    <div class="search-message">
      <div class="user-wrap">
        <div class="name-wrap">
          <span class="text-block-title">{{ userName }}</span>
          <div>
            <fluent-icon
              v-if="isOutgoingMessage"
              icon="arrow-reply"
              class="icon-outgoing"
            />
          </div>
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
  background: var(--color-background-light);
  border-radius: var(--border-radius-medium);
  color: var(--color-body);
  margin-bottom: var(--space-small);
  margin-left: var(--space-one);
  padding: 0 var(--space-small);

  &:hover {
    background: var(--w-400);
    color: var(--white);
    .message-content::v-deep .searchkey--highlight {
      color: var(--white);
      text-decoration: underline;
    }
    .icon-outgoing {
      color: var(--white);
    }
  }
  &:last-child {
    .search-message {
      border-bottom: none;
    }
  }
}

.search-message {
  padding: var(--space-smaller) var(--space-smaller);
  &:hover {
    color: var(--white);
  }
}

.user-wrap {
  display: flex;
  justify-content: space-between;
}

.name-wrap {
  display: flex;
  max-width: 22rem;

  .text-block-title {
    font-weight: var(--font-weight-bold);
    text-overflow: ellipsis;
    overflow: hidden;
    white-space: nowrap;
  }
}

.icon-outgoing {
  color: var(--w-500);
  padding: var(--space-micro);
  padding-right: var(--space-smaller);
}

.timestamp {
  font-size: var(--font-size-mini);
  top: var(--space-micro);
  position: relative;
  text-align: right;
}

p {
  max-width: 100%;
}

.message-content {
  font-size: var(--font-size-small);
  margin-bottom: var(--space-micro);
  margin-top: var(--space-micro);
  padding: 0;
  line-height: 1.35;
  overflow-wrap: break-word;
}

.message-content::v-deep .searchkey--highlight {
  color: var(--w-600);
  font-weight: var(--font-weight-bold);
  font-size: var(--font-size-small);
  padding: (var(--space-zero) var(--space-zero));
}
</style>
