<script setup>
import { computed, ref } from 'vue';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import { useRouter, useRoute } from 'vue-router';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper.js';
import { dynamicTime, shortTimestamp } from 'shared/helpers/timeHelper';
import { useI18n } from 'vue-i18n';

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
const { t } = useI18n();

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

// Simple check: Is this a voice channel conversation?
const isVoiceChannel = computed(() => {
  return props.conversation?.meta?.inbox?.channel_type === 'Channel::Voice';
});

// Get call direction: inbound or outbound
const isIncomingCall = computed(() => {
  if (!isVoiceChannel.value) return false;
  
  const direction = props.conversation?.additional_attributes?.call_direction;
  return direction === 'inbound';
});

// Simple function to normalize call status
const normalizedCallStatus = computed(() => {
  if (!isVoiceChannel.value) return null;
  
  // Get the raw status directly from conversation
  const status = props.conversation?.additional_attributes?.call_status;
  
  // Simple mapping of call statuses
  if (status === 'in-progress') return 'active';
  if (status === 'completed') return 'ended';
  if (status === 'canceled') return 'ended';
  if (status === 'failed') return 'ended';
  if (status === 'busy') return 'no-answer';
  if (status === 'no-answer') return isIncomingCall.value ? 'missed' : 'no-answer';
  
  // Return the status as is for explicit values
  if (status === 'active') return 'active';
  if (status === 'missed') return 'missed';
  if (status === 'ended') return 'ended';
  if (status === 'ringing') return 'ringing';
  
  // If no status is set, default to 'ended'
  return 'ended';
});

const isRingingCall = computed(() => {
  return normalizedCallStatus.value === 'ringing';
});

const isActiveCall = computed(() => {
  return normalizedCallStatus.value === 'active';
});

// Get formatted call status text for voice channel conversations
const callStatusText = computed(() => {
  if (!isVoiceChannel.value) return '';
  
  const status = normalizedCallStatus.value;
  const isIncoming = isIncomingCall.value;
  
  if (status === 'active') {
    return t('CONVERSATION.VOICE_CALL.CALL_IN_PROGRESS');
  }
  
  if (isIncoming) {
    if (status === 'ringing') {
      return t('CONVERSATION.VOICE_CALL.INCOMING_CALL');
    }
    
    if (status === 'missed') {
      return t('CONVERSATION.VOICE_CALL.MISSED_CALL');
    }
    
    if (status === 'ended') {
      return t('CONVERSATION.VOICE_CALL.CALL_ENDED');
    }
  } else {
    if (status === 'ringing') {
      return t('CONVERSATION.VOICE_CALL.OUTGOING_CALL');
    }
    
    if (status === 'no-answer') {
      return t('CONVERSATION.VOICE_CALL.NO_ANSWER');
    }
    
    if (status === 'ended') {
      return t('CONVERSATION.VOICE_CALL.CALL_ENDED');
    }
  }
  
  return isIncoming 
    ? t('CONVERSATION.VOICE_CALL.INCOMING_CALL') 
    : t('CONVERSATION.VOICE_CALL.OUTGOING_CALL');
});

// Get icon class based on call status
const callIconClass = computed(() => {
  if (!isVoiceChannel.value) return '';
  
  const status = normalizedCallStatus.value;
  const isIncoming = isIncomingCall.value;
  
  if (status === 'missed' || status === 'no-answer') {
    return 'i-ph-phone-x-fill';
  }
  
  if (status === 'active') {
    return 'i-ph-phone-call-fill';
  }
  
  if (status === 'ended' || status === 'completed') {
    return 'i-ph-phone-fill';
  }
  
  // Default phone icon for ringing state
  return isIncoming
    ? 'i-ph-phone-incoming-fill'
    : 'i-ph-phone-outgoing-fill';
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
            <!-- Special handling for voice channel with specific icons based on call status -->
            <span
              v-if="isVoiceChannel && normalizedCallStatus === 'missed'"
              class="i-ph-phone-x-fill text-red-600 dark:text-red-400 size-3 inline-block"
            ></span>
            <span
              v-else-if="isVoiceChannel && normalizedCallStatus === 'active'"
              class="i-ph-phone-call-fill text-woot-600 dark:text-woot-400 size-3 inline-block"
            ></span>
            <span
              v-else-if="isVoiceChannel && normalizedCallStatus === 'ended' && isIncomingCall"
              class="i-ph-phone-incoming-fill text-n-slate-11 size-3 inline-block"
            ></span>
            <span
              v-else-if="isVoiceChannel && normalizedCallStatus === 'ended'"
              class="i-ph-phone-outgoing-fill text-n-slate-11 size-3 inline-block"
            ></span>
            <span
              v-else-if="isVoiceChannel && isIncomingCall"
              class="i-ph-phone-incoming-fill text-green-600 dark:text-green-400 size-3 inline-block"
              :class="{ 'pulse-animation': normalizedCallStatus === 'ringing' }"
            ></span>
            <span
              v-else-if="isVoiceChannel"
              class="i-ph-phone-outgoing-fill text-green-600 dark:text-green-400 size-3 inline-block"
              :class="{ 'pulse-animation': normalizedCallStatus === 'ringing' }"
            ></span>
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
      
      <!-- Special preview for voice channel conversations -->
      <div 
        v-if="isVoiceChannel"
        class="flex items-center py-1 h-7 gap-1 mb-0 text-sm line-clamp-1"
        :class="{
          'text-green-600 dark:text-green-400': normalizedCallStatus === 'ringing',
          'text-woot-600 dark:text-woot-400': normalizedCallStatus === 'active',
          'text-red-600 dark:text-red-400': normalizedCallStatus === 'missed' || normalizedCallStatus === 'no-answer',
          'text-slate-600 dark:text-slate-400': normalizedCallStatus === 'ended'
        }"
      >
        <!-- Icon based on call status -->
        <i v-if="normalizedCallStatus === 'missed' || normalizedCallStatus === 'no-answer'" 
           class="i-ph-phone-x-fill text-base inline-block flex-shrink-0 text-red-600 dark:text-red-400 mr-1"></i>
              
        <i v-else-if="normalizedCallStatus === 'active'" 
           class="i-ph-phone-call-fill text-base inline-block flex-shrink-0 text-woot-600 dark:text-woot-400 mr-1"></i>
              
        <i v-else-if="normalizedCallStatus === 'ended'" 
           class="i-ph-phone-fill text-base inline-block flex-shrink-0 text-slate-600 dark:text-slate-400 mr-1"></i>
              
        <i v-else-if="isIncomingCall" 
           class="i-ph-phone-incoming-fill text-base inline-block flex-shrink-0 text-green-600 dark:text-green-400 mr-1"
           :class="{ 'pulse-animation': normalizedCallStatus === 'ringing' }"></i>
              
        <i v-else 
           class="i-ph-phone-outgoing-fill text-base inline-block flex-shrink-0 text-green-600 dark:text-green-400 mr-1"
           :class="{ 'pulse-animation': normalizedCallStatus === 'ringing' }"></i>
              
        <span class="text-current truncate">{{ callStatusText }}</span>
        
        <!-- Join now prompt for ringing calls -->
        <span 
          v-if="normalizedCallStatus === 'ringing'"
          class="flex-shrink-0 text-xs font-medium text-green-600 dark:text-green-400"
        >
          ({{ t('CONVERSATION.VOICE_CALL.JOIN_CALL') }})
        </span>
      </div>
      
      <!-- Regular message previews for non-voice channel conversations -->
      <template v-else>
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
      </template>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.conversation-ringing {
  animation: border-pulse 1.5s infinite;
}

.pulse-animation {
  animation: icon-pulse 1.5s infinite;
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

@keyframes icon-pulse {
  0% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
  100% {
    opacity: 1;
  }
}
</style>
