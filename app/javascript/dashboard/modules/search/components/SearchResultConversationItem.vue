<template>
  <router-link :to="navigateTo" class="conversation-item">
    <div class="icon-wrap">
      <fluent-icon icon="chat-multiple" :size="14" />
    </div>
    <div class="conversation-details">
      <div class="meta-wrap">
        <div class="flex-container ">
          <woot-label
            class="conversation-id"
            :title="`#${id}`"
            :show-close="false"
            small
          />
          <div class="inbox-name-wrap">
            <inbox-name :inbox="inbox" class="margin-right-1" />
          </div>
        </div>
        <div>
          <span class="created-at">{{ createdAtTime }}</span>
        </div>
      </div>
      <h5 v-if="name" class="text-block-title name">
        <span class="pre-text">from:</span>
        {{ name }}
      </h5>
      <slot />
    </div>
  </router-link>
</template>

<script>
import { frontendURL } from 'dashboard/helper/URLHelper.js';
import timeMixin from 'dashboard/mixins/time';
import InboxName from 'dashboard/components/widgets/InboxName.vue';

export default {
  components: {
    InboxName,
  },
  mixins: [timeMixin],
  props: {
    id: {
      type: Number,
      default: 0,
    },
    inbox: {
      type: Object,
      default: () => ({}),
    },
    name: {
      type: String,
      default: '',
    },
    accountId: {
      type: [String, Number],
      default: '',
    },
    createdAt: {
      type: [String, Date, Number],
      default: '',
    },
  },
  computed: {
    navigateTo() {
      return frontendURL(`accounts/${this.accountId}/conversations/${this.id}`);
    },
    createdAtTime() {
      return this.dynamicTime(this.createdAt);
    },
  },
};
</script>

<style scoped lang="scss">
.conversation-item {
  cursor: pointer;
  display: flex;
  padding: var(--space-small);
  border-radius: var(--border-radius-small);

  &:hover {
    background-color: var(--s-25);
  }
}

.meta-wrap {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: var(--space-smaller);
}
.icon-wrap {
  width: var(--space-medium);
  height: var(--space-medium);
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--w-600);
  border-radius: var(--border-radius-small);
  background-color: var(--w-75);
}

.inbox-name-wrap {
  background-color: var(--s-25);
  height: var(--space-two);
  display: flex;
  justify-content: center;
  align-items: center;
  border-radius: var(--border-radius-small);
  width: fit-content;
  margin-left: var(--space-smaller);
}
.conversation-details {
  margin-left: var(--space-small);
  flex-grow: 1;
  min-width: 0;
}
.conversation-id,
.name {
  margin: 0;
}
.created-at,
.pre-text {
  color: var(--s-600);
  font-size: var(--font-size-mini);
  font-weight: var(--font-weight-normal);
}
</style>
