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

<template>
  <router-link
    :to="navigateTo"
    class="flex p-2 rounded-md cursor-pointer hover:bg-n-slate-3 dark:hover:bg-n-solid-3"
  >
    <div
      class="flex items-center justify-center flex-shrink-0 w-6 h-6 rounded bg-n-brand/10 dark:bg-n-brand/40 text-n-blue-text dark:text-n-blue-text"
    >
      <fluent-icon icon="chat-multiple" :size="14" />
    </div>
    <div class="flex-grow min-w-0 ml-2">
      <div class="flex items-center justify-between mb-1">
        <div class="flex">
          <woot-label
            class="!bg-n-slate-3 dark:!bg-n-solid-3 !border-n-weak dark:!border-n-strong m-0"
            :title="`#${id}`"
            :show-close="false"
            small
          />
          <div
            class="flex items-center justify-center h-5 ml-1 rounded bg-n-slate-3 dark:bg-n-solid-3 w-fit rtl:ml-0 rtl:mr-1"
          >
            <InboxName
              :inbox="inbox"
              class="mr-2 rtl:mr-0 rtl:ml-2 bg-n-slate-3 dark:bg-n-solid-3 text-n-slate-11 dark:text-n-slate-11"
            />
          </div>
        </div>
        <div>
          <span
            class="text-xs font-normal text-n-slate-11 dark:text-n-slate-11"
          >
            {{ createdAtTime }}
          </span>
        </div>
      </div>
      <div class="flex gap-2">
        <h5
          v-if="name"
          class="m-0 text-sm text-n-slate-12 dark:text-n-slate-12"
        >
          <span
            class="text-xs font-normal text-n-slate-11 dark:text-n-slate-11"
          >
            {{ $t('SEARCH.FROM') }}:
          </span>
          {{ name }}
        </h5>
        <h5
          v-if="email"
          class="m-0 overflow-hidden text-sm text-n-slate-12 dark:text-n-slate-12 whitespace-nowrap text-ellipsis"
        >
          <span
            class="text-xs font-normal text-n-slate-11 dark:text-n-slate-11"
          >
            {{ $t('SEARCH.EMAIL') }}:
          </span>
          {{ email }}
        </h5>
      </div>
      <slot />
    </div>
  </router-link>
</template>
