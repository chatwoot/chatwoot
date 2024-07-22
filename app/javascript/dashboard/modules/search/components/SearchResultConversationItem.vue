<template>
  <router-link :to="navigateTo" class="conversation-item">
    <div class="icon-wrap">
      <fluent-icon icon="chat-multiple" :size="14" />
    </div>
    <div class="conversation-details">
      <div class="meta-wrap">
        <div class="flex">
          <woot-label
            class="conversation-id"
            :title="`#${id}`"
            :show-close="false"
            small
          />
          <div class="inbox-name-wrap">
            <inbox-name :inbox="inbox" class="mr-2 rtl:mr-0 rtl:ml-2" />
          </div>
        </div>
        <div>
          <span class="created-at">{{ createdAtTime }}</span>
        </div>
      </div>
      <div class="user-details">
        <h5 v-if="name" class="text-sm name text-slate-800 dark:text-slate-100">
          <span class="pre-text"> {{ $t('SEARCH.FROM') }}: </span>
          {{ name }}
        </h5>
        <h5
          v-if="email"
          class="overflow-hidden text-sm email text-slate-700 dark:text-slate-200 whitespace-nowrap text-ellipsis"
        >
          <span class="pre-text">{{ $t('SEARCH.EMAIL') }}:</span>
          {{ email }}
        </h5>
      </div>
      <slot />
    </div>
  </router-link>
</template>

<script>
import { frontendURL } from 'dashboard/helper/URLHelper.js';
import { dynamicTime } from 'shared/helpers/timeHelper';
import InboxName from 'dashboard/components/widgets/InboxName.vue';

export default {
  components: {
    InboxName,
  },
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
    email: {
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
    messageId: {
      type: Number,
      default: 0,
    },
  },
  computed: {
    navigateTo() {
      const params = {};
      if (this.messageId) {
        params.messageId = this.messageId;
      }
      return frontendURL(
        `accounts/${this.accountId}/conversations/${this.id}`,
        params
      );
    },
    createdAtTime() {
      return dynamicTime(this.createdAt);
    },
  },
};
</script>

<style scoped lang="scss">
.conversation-item {
  @apply cursor-pointer flex p-2 rounded hover:bg-slate-25 dark:hover:bg-slate-800;
}

.meta-wrap {
  @apply flex items-center justify-between mb-1;
}
.icon-wrap {
  @apply w-6 h-6 flex-shrink-0  bg-woot-75 dark:bg-woot-600/50 flex items-center justify-center rounded text-woot-600 dark:text-woot-500;
}

.inbox-name-wrap {
  @apply bg-slate-25 dark:bg-slate-800 h-5 flex justify-center items-center rounded w-fit ml-1 rtl:ml-0 rtl:mr-1;
}
.conversation-details {
  @apply ml-2 flex-grow min-w-0;
}

.name {
  @apply flex-shrink-0;
}
.conversation-id,
.name,
.email {
  @apply m-0;
}
.created-at,
.pre-text {
  @apply text-slate-600 dark:text-slate-100 text-xs font-normal;
}

.user-details {
  @apply flex gap-2;
}
</style>
