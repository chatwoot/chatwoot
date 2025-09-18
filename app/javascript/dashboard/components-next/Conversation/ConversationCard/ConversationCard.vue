<script setup>
import { computed, ref } from 'vue';
import { useStore } from 'vuex';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import { useRouter, useRoute } from 'vue-router';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper.js';
import { dynamicTime, shortTimestamp } from 'shared/helpers/timeHelper';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import CardMessagePreview from './CardMessagePreview.vue';
import CardMessagePreviewWithMeta from './CardMessagePreviewWithMeta.vue';
import CardPriorityIcon from './CardPriorityIcon.vue';
import AIToggleButton from 'dashboard/components/ui/AIToggleButton.vue';

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
const store = useStore();

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
  const { channelType, medium } = inbox.value;
  return getInboxIconByType(channelType, medium);
});

const lastActivityAt = computed(() => {
  const timestamp = props.conversation?.timestamp;
  return timestamp ? shortTimestamp(dynamicTime(timestamp)) : '';
});

const showMessagePreviewWithoutMeta = computed(() => {
  const { labels = [] } = props.conversation;
  return (
    !cardMessagePreviewWithMetaRef.value?.hasSlaThreshold && labels.length === 0
  );
});

const isAiEnabled = computed(() => {
  return !!currentContact.value?.custom_attributes?.ai_enabled;
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

const onToggleAi = async () => {
  const contactId = currentContact.value?.id;
  if (!contactId) return;
  const next = !isAiEnabled.value;

  await store.dispatch('contacts/toggleAi', {
    id: contactId,
    aiEnabled: next,
  });
};
</script>

<template>
  <div
    role="button"
    class="flex w-full gap-3 px-3 py-4 transition-all duration-300 ease-in-out cursor-pointer"
    @click="onCardClick"
  >
    <!-- Avatar with counter positioned at bottom-right -->
    <div class="relative flex-shrink-0">
      <Avatar
        :name="currentContactName"
        :src="currentContactThumbnail"
        :size="24"
        :status="currentContactStatus"
        rounded-full
      />
      <!-- Unread counter positioned at bottom-right of avatar -->
      <div
        v-if="conversation.unreadCount > 0"
        class="absolute -bottom-1 -right-1 inline-flex items-center justify-center rounded-full size-5 bg-n-brand border-2 border-white"
      >
        <span class="text-xs font-semibold text-white">
          {{
            conversation.unreadCount > 9
              ? $t('COMBOBOX.MORE', { count: 9 })
              : conversation.unreadCount
          }}
        </span>
      </div>
    </div>

    <div class="flex flex-col w-full gap-1 min-w-0">
      <!-- Header with username and dates aligned at top -->
      <div class="flex items-start justify-between gap-2 min-h-[24px]">
        <h4 class="text-base font-medium truncate text-n-slate-12 leading-6">
          {{ currentContactName }}
        </h4>
        <div class="flex items-start gap-2 flex-shrink-0">
          <CardPriorityIcon :priority="conversation.priority || null" />
          <div
            v-tooltip.left="inboxName"
            class="flex items-center justify-center flex-shrink-0 rounded-full bg-n-alpha-2 size-5"
          >
            <Icon
              :icon="inboxIcon"
              class="flex-shrink-0 text-n-slate-11 size-3"
            />
          </div>
          <span class="text-sm text-n-slate-10 leading-6">
            {{ lastActivityAt }}
          </span>
        </div>
      </div>

      <!-- Message preview with AI button centered vertically -->
      <div class="relative">
        <!-- AI Toggle Button positioned absolutely in center -->
        <div class="absolute right-4 top-1/2 -translate-y-1/2 z-10">
          <AIToggleButton :ai-enabled="isAiEnabled" @toggle-ai="onToggleAi" />
        </div>

        <!-- Message content with right padding to avoid AI button -->
        <div class="pr-16">
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
    </div>
  </div>
</template>
