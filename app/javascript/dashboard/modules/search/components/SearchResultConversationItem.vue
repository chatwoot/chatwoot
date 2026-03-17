<script setup>
import { computed } from 'vue';
import { frontendURL } from 'dashboard/helper/URLHelper.js';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { useInbox } from 'dashboard/composables/useInbox';
import { getInboxIconByType } from 'dashboard/helper/inbox';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

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

const { inbox } = useInbox(props.inbox?.id);

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

const createdAtTime = computed(() => {
  if (!props.createdAt) return '';
  return dynamicTime(props.createdAt);
});

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

const inboxName = computed(() => props.inbox?.name);

const inboxIcon = computed(() => {
  if (!inbox.value) return null;
  const { channelType, medium } = inbox.value;
  return getInboxIconByType(channelType, medium);
});
</script>

<template>
  <router-link :to="navigateTo">
    <CardLayout
      layout="col"
      class="[&>div]:justify-start [&>div]:gap-2 [&>div]:px-4 [&>div]:py-3 [&>div]:items-start hover:bg-n-slate-2 dark:hover:bg-n-solid-3"
    >
      <div
        class="flex items-center min-w-0 justify-between gap-2 w-full h-7 mb-1"
      >
        <div class="flex items-center gap-3">
          <div class="flex items-center gap-1.5 flex-shrink-0">
            <Icon
              icon="i-lucide-hash"
              class="flex-shrink-0 text-n-slate-11 size-4"
            />
            <span class="text-n-slate-12 text-sm leading-4">
              {{ id }}
            </span>
          </div>
          <div v-if="inboxName" class="w-px h-3 bg-n-strong" />
          <div v-if="inboxName" class="flex items-center gap-1.5 flex-shrink-0">
            <div
              v-if="inboxIcon"
              class="flex items-center justify-center flex-shrink-0 rounded-full bg-n-alpha-2 size-4"
            >
              <Icon
                :icon="inboxIcon"
                class="flex-shrink-0 text-n-slate-11 size-2.5"
              />
            </div>
            <span class="text-sm leading-4 text-n-slate-12">
              {{ inboxName }}
            </span>
          </div>
        </div>
        <span
          v-if="createdAtTime"
          class="text-sm font-normal min-w-0 truncate text-n-slate-11"
        >
          {{ createdAtTime }}
        </span>
      </div>
      <div class="flex flex-wrap gap-x-2 gap-y-1.5 items-center">
        <template
          v-for="(item, index) in visibleInfoItems"
          :key="`info-${index}`"
        >
          <h5 class="m-0 text-sm min-w-0 text-n-slate-12 truncate">
            <span class="text-sm leading-4 font-normal text-n-slate-11">
              {{ $t(item.label) + ':' }}
            </span>
            {{ item.value }}
          </h5>
          <div
            v-if="index < visibleInfoItems.length - 1"
            class="w-px h-3 bg-n-strong"
          />
        </template>
      </div>
      <slot />
    </CardLayout>
  </router-link>
</template>
