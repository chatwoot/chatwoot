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

const lastNonActivityMessage = computed(() => {
  return props.conversation?.lastNonActivityMessage || {};
});

const isVoiceCall = computed(() => {
  return lastNonActivityMessage.value?.content_type === 'voice_call' || 
         lastNonActivityMessage.value?.content_type === 'voice';
});

const callData = computed(() => {
  if (!isVoiceCall.value) return null;
  return lastNonActivityMessage.value?.content_attributes?.data || {};
});

const isIncomingCall = computed(() => {
  if (!isVoiceCall.value) return false;
  
  const direction = callData.value?.call_direction;
  if (direction) {
    return direction === 'inbound';
  }
  
  return lastNonActivityMessage.value?.message_type === 0;
});

const normalizedCallStatus = computed(() => {
  if (!isVoiceCall.value) return null;
  
  // Apply the same status mapping as in VoiceCall component
  const callStatus = callData.value?.status;
  if (callStatus) {
    const statusMap = {
      'in-progress': 'active',
      'completed': 'ended',
      'canceled': 'ended',
      'failed': 'ended',
      'busy': 'no-answer',
      'no-answer': isIncomingCall.value ? 'missed' : 'no-answer'
    };
    
    return statusMap[callStatus] || callStatus;
  }
  
  // Determine status from timestamps
  if (callData.value?.ended_at) {
    return 'ended';
  }
  if (callData.value?.missed) {
    return isIncomingCall.value ? 'missed' : 'no-answer';
  }
  if (callData.value?.started_at) {
    return 'active';
  }
  
  // Default to ringing
  return 'ringing';
});

const isRingingCall = computed(() => {
  return normalizedCallStatus.value === 'ringing';
});

const isActiveCall = computed(() => {
  return normalizedCallStatus.value === 'active';
});

const showMessagePreviewWithoutMeta = computed(() => {
  const { labels = [] } = props.conversation;
  return (
    !cardMessagePreviewWithMetaRef.value?.hasSlaThreshold && labels.length === 0
  );
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
    class="flex w-full gap-3 px-3 py-4 transition-all duration-300 ease-in-out cursor-pointer relative"
    :class="{ 
      'border-l-2 border-green-500 dark:border-green-400': isRingingCall,
      'border-l-2 border-woot-500 dark:border-woot-400': isActiveCall,
      'border-l-2 border-red-500 dark:border-red-400': normalizedCallStatus === 'missed' || normalizedCallStatus === 'no-answer',
      'conversation-ringing': isRingingCall
    }"
    @click="onCardClick"
  >
    <!-- Ringing call indicator (pulse effect) -->
    <div 
      v-if="isRingingCall" 
      class="absolute left-0 top-0 bottom-0 w-0.5 bg-green-500 dark:bg-green-400 animate-pulse"
    ></div>
  
    <Avatar
      :name="currentContactName"
      :src="currentContactThumbnail"
      :size="24"
      :status="currentContactStatus"
      rounded-full
    />
    <div class="flex flex-col w-full gap-1 min-w-0">
      <div class="flex items-center justify-between h-6 gap-2">
        <h4 class="text-base font-medium truncate text-n-slate-12">
          {{ currentContactName }}
        </h4>
        <div class="flex items-center gap-2">
          <CardPriorityIcon :priority="conversation.priority || null" />
          <div
            v-tooltip.left="inboxName"
            class="flex items-center justify-center flex-shrink-0 rounded-full bg-n-alpha-2 size-5"
          >
            <!-- Special handling for voice channel -->
            <span
              v-if="inbox.channelType === 'Channel::Voice'"
              class="i-ph-phone-fill text-n-slate-11 size-3 inline-block"
            />
            <Icon
              v-else
              :icon="inboxIcon"
              class="flex-shrink-0 text-n-slate-11 size-3"
            />
          </div>
          <span class="text-sm text-n-slate-10">
            {{ lastActivityAt }}
          </span>
        </div>
      </div>
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
</template>

<style lang="scss" scoped>
.conversation-ringing {
  animation: border-pulse 1.5s infinite;
}

@keyframes border-pulse {
  0% {
    border-color: rgba(34, 197, 94, 0.8); /* Green for ringing */
  }
  50% {
    border-color: rgba(34, 197, 94, 0.2);
  }
  100% {
    border-color: rgba(34, 197, 94, 0.8);
  }
}
</style>
