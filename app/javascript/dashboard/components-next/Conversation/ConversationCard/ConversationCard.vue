<script setup>
import { computed, ref } from 'vue';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import { useRouter, useRoute } from 'vue-router';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper.js';
import { dynamicTime, shortTimestamp } from 'shared/helpers/timeHelper';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import CardMessagePreview from './CardMessagePreview.vue';
import CardMessagePreviewWithMeta from './CardMessagePreviewWithMeta.vue';
import CardPriorityIcon from './CardPriorityIcon.vue';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
  contact: {
    type: Object,
    required: true,
  },
  stateInbox: {
    type: Object,
    required: true,
  },
  accountLabels: {
    type: Array,
    required: true,
  },
});

const router = useRouter();
const route = useRoute();

const cardMessagePreviewWithMetaRef = ref(null);

const currentContact = computed(() => props.contact);

const currentContactName = computed(() => currentContact.value?.name);
const currentContactThumbnail = computed(() => currentContact.value?.thumbnail);
const currentContactStatus = computed(
  () => currentContact.value?.availabilityStatus
);

const inbox = computed(() => props.stateInbox);

const inboxName = computed(() => inbox.value?.name);

const inboxIcon = computed(() => {
  const { phoneNumber, channelType } = inbox.value;
  return getInboxIconByType(channelType, phoneNumber);
});

const lastActivityAt = computed(() => {
  const timestamp = props.conversation?.timestamp;
  return timestamp ? shortTimestamp(dynamicTime(timestamp)) : '';
});

const showMessagePreviewWithoutMeta = computed(() => {
  const { labels = [] } = props.conversation;
  const result =
    !cardMessagePreviewWithMetaRef.value?.hasSlaThreshold &&
    labels.length === 0;

  return result;
});

const onCardClick = e => {
  const path = frontendURL(
    conversationUrl({
      accountId: route.params.accountId,
      id: props.conversation.id,
    })
  );

  if (e.metaKey || e.ctrlKey) {
    window.open(
      window.chatwootConfig.hostURL + path,
      '_blank',
      'noopener noreferrer nofollow'
    );
    return;
  }
  router.push({ path });
};
</script>

<template>
  <div
    role="button"
    class="relative flex w-full px-3 py-4 transition-all duration-300 ease-in-out cursor-pointer"
    @click="onCardClick"
  >
    <!-- Avatar with counter positioned at bottom-right -->
    <div class="relative flex-shrink-0 mr-3">
      <Avatar
        :name="currentContactName"
        :src="currentContactThumbnail"
        :size="24"
        :status="currentContactStatus"
        rounded-full
      />
      <!-- Unread counter half-overlapping at avatar bottom-right (center on corner) -->
      <div
        v-if="conversation.unreadCount > 0"
        class="absolute bottom-0 right-0 -translate-x-1/2 -translate-y-1/2 inline-flex items-center justify-center rounded-full bg-n-brand border-2 border-white"
        :class="conversation.unreadCount > 9 ? 'min-w-8 h-5 px-1' : 'size-5'"
      >
        <span class="text-xs font-semibold text-white whitespace-nowrap">
          {{
            conversation.unreadCount > 9
              ? $t('COMBOBOX.MORE', { count: 9 })
              : conversation.unreadCount
          }}
        </span>
      </div>
    </div>

    <!-- Main content area -->
    <div class="flex flex-col w-full gap-1 min-w-0">
      <!-- Header with assignee name -->
      <div class="flex items-center gap-1 min-w-0">
        <span class="text-xs font-medium text-n-slate-11 truncate">
          {{ $t('ASSIGNEE_TYPE_TABS.assigned') }}
          <span v-if="conversation.priority === 'urgent'" class="text-n-red-9">
            !!!
          </span>
          <span
            v-else-if="conversation.priority === 'high'"
            class="text-n-orange-9"
          >
            !!
          </span>
          <span v-else class="text-n-slate-11">!</span>
        </span>
      </div>

      <!-- Contact name -->
      <h4 class="text-sm font-medium text-n-slate-12 truncate">
        {{ currentContactName }}
      </h4>

      <!-- Message preview -->
      <div class="relative">
        <CardMessagePreview
          v-show="showMessagePreviewWithoutMeta"
          :conversation="conversation"
        />
        <CardMessagePreviewWithMeta
          v-show="!showMessagePreviewWithoutMeta"
          ref="cardMessagePreviewWithMetaRef"
          :conversation="conversation"
          :account-labels="accountLabels"
        />
      </div>
    </div>

    <!-- Timestamp and icons positioned absolutely at top right -->
    <div class="absolute top-4 right-3 flex items-center gap-2 flex-shrink-0">
      <CardPriorityIcon :priority="conversation.priority || null" />
      <div
        v-tooltip.left="inboxName"
        class="flex items-center justify-center flex-shrink-0 rounded-full bg-n-alpha-2 size-4"
      >
        <Icon
          :icon="inboxIcon"
          class="flex-shrink-0 text-n-slate-11 size-2.5"
        />
      </div>
      <span class="text-sm text-n-slate-10">
        {{ lastActivityAt }}
      </span>
    </div>
  </div>
</template>
