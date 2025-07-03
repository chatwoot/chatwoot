<script setup>
import { computed } from 'vue';

import { frontendURL } from 'dashboard/helper/URLHelper.js';
import { dynamicTime } from 'shared/helpers/timeHelper';
import InboxName from 'dashboard/components/widgets/InboxName.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
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
  emailSubject: {
    type: String,
    default: '',
  },
});

const navigateTo = computed(() => {
  const params = {};
  if (props.messageId) {
    params.messageId = props.messageId;
  }
  return frontendURL(
    `accounts/${props.accountId}/conversations/${props.id}`,
    params
  );
});

const createdAtTime = dynamicTime(props.createdAt);

const infoItems = computed(() => [
  {
    label: 'SEARCH.FROM',
    value: props.name,
    show: !!props.name,
  },
  {
    label: 'SEARCH.EMAIL',
    value: props.email,
    show: !!props.email,
  },
  {
    label: 'SEARCH.EMAIL_SUBJECT',
    value: props.emailSubject,
    show: !!props.emailSubject,
  },
]);

const visibleInfoItems = computed(() =>
  infoItems.value.filter(item => item.show)
);
</script>

<template>
  <router-link
    :to="navigateTo"
    class="flex p-2 rounded-xl cursor-pointer hover:bg-n-slate-2"
  >
    <Avatar
      name="chats"
      :size="24"
      icon-name="i-lucide-messages-square"
      class="[&>span]:rounded"
    />
    <div class="flex-grow min-w-0 ml-2">
      <div class="flex items-center min-w-0 justify-between gap-1 mb-1">
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
        <span
          class="text-xs font-normal min-w-0 truncate text-n-slate-11 dark:text-n-slate-11"
        >
          {{ createdAtTime }}
        </span>
      </div>
      <div class="flex flex-wrap gap-x-2 gap-y-1.5">
        <h5
          v-for="item in visibleInfoItems"
          :key="item.label"
          class="m-0 text-sm min-w-0 text-n-slate-12 dark:text-n-slate-12 truncate"
        >
          <span
            class="text-xs font-normal text-n-slate-11 dark:text-n-slate-11"
          >
            {{ $t(item.label) }}:
          </span>
          {{ item.value }}
        </h5>
      </div>
      <slot />
    </div>
  </router-link>
</template>
