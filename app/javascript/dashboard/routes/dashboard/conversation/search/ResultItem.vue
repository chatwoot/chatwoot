<template>
  <div class="content">
    <div class="time-ticket-wrap">
      <div class="ticket-wrap">
        <div>
          <span class="ticket"># {{ conversationId }}</span>
        </div>
        <div class="user-wrap">
          <span class="user-name">{{ userName }}</span>
          <i class="ion-headphone" />
        </div>
      </div>
      <span class="timestamp">{{ readableTime }}</span>
    </div>
    <div>
      <p class="search-messages">
        {{ message }}
      </p>
    </div>
  </div>
</template>

<script>
// import { mapGetters } from 'vuex';
import timeMixin from '../../../../mixins/time';

export default {
  mixins: [timeMixin],
  props: {
    conversationId: {
      type: String,
      default: '',
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
      type: String,
      default: '',
    },
  },
  computed: {
    readableTime() {
      if (!this.timestamp) {
        return '';
      }
      return this.dynamicTime(this.timestamp);
    },
  },
};
</script>

<style lang="scss" scoped>
.content {
  display: block;
  align-items: center;
  border-bottom: 1px solid var(--color-border-light);
  color: var(--color-body);
  padding: 0.3rem var(--space-micro) var(--space-zero) 1.7rem;
}
.content:last-child {
  border-bottom: none;
  padding-bottom: var(--space-two);
}

.content:hover {
  background-color: var(--color-background);
}

.time-ticket-wrap {
  display: flex;
  justify-content: space-between;
  padding: var(--space-small) var(--space-normal) var(--space-smaller)
    var(--space-zero);
}
.ticket-wrap {
  display: flex;
}
.ticket {
  color: var(--w-600);
  font-size: var(--font-size-mini);
  font-weight: var(--font-weight-bold);
  background: var(--w-50);
  border-radius: 4px;
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
  color: var(--color-heading);
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
.search-messages {
  padding: var(--space-micro) var(--space-normal) var(--space-zero)
    var(--space-zero);
}
</style>
