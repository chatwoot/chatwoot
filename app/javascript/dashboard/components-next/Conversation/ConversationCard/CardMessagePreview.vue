<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();
const { getPlainText } = useMessageFormatter();

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

// Return proper message content based on message type
const lastNonActivityMessageContent = computed(() => {
  const { lastNonActivityMessage = {}, customAttributes = {} } =
    props.conversation;
  const { email: { subject } = {} } = customAttributes;
  
  // Return special formatting for voice calls
  if (isVoiceChannel.value) {
    return callStatusText.value;
  }
  
  return getPlainText(
    subject || lastNonActivityMessage?.content || t('CHAT_LIST.NO_CONTENT')
  );
});

const assignee = computed(() => {
  const { meta: { assignee: agent = {} } = {} } = props.conversation;
  return {
    name: agent.name ?? agent.availableName,
    thumbnail: agent.thumbnail,
    status: agent.availabilityStatus,
  };
});

const unreadMessagesCount = computed(() => {
  const { unreadCount } = props.conversation;
  return unreadCount;
});
</script>

<template>
  <div class="flex items-end w-full gap-2 pb-1">
    <!-- Voice Call Message -->
    <div 
      v-if="isVoiceChannel" 
      class="w-full mb-0 text-sm flex items-center gap-1 pt-0.5"
      :class="{
        'text-green-600 dark:text-green-400': normalizedCallStatus === 'ringing',
        'text-woot-600 dark:text-woot-400': normalizedCallStatus === 'active',
        'text-red-600 dark:text-red-400': normalizedCallStatus === 'missed' || normalizedCallStatus === 'no-answer',
        'text-slate-600 dark:text-slate-400': normalizedCallStatus === 'ended'
      }"
    >
      <!-- Explicit icon based on call status -->
      <!-- Missed call or no answer -->
      <i v-if="normalizedCallStatus === 'missed' || normalizedCallStatus === 'no-answer'" 
         class="i-ph-phone-x-fill text-base inline-block flex-shrink-0 text-red-600 dark:text-red-400 mr-1"></i>
            
      <!-- Active call -->
      <i v-else-if="normalizedCallStatus === 'active'" 
         class="i-ph-phone-call-fill text-base inline-block flex-shrink-0 text-woot-600 dark:text-woot-400 mr-1"></i>
            
      <!-- Ended incoming call -->
      <i v-else-if="normalizedCallStatus === 'ended' && isIncomingCall" 
         class="i-ph-phone-incoming-fill text-base inline-block flex-shrink-0 text-slate-600 dark:text-slate-400 mr-1"></i>
            
      <!-- Ended outgoing call -->
      <i v-else-if="normalizedCallStatus === 'ended'" 
         class="i-ph-phone-outgoing-fill text-base inline-block flex-shrink-0 text-slate-600 dark:text-slate-400 mr-1"></i>
            
      <!-- Ringing incoming call -->
      <i v-else-if="isIncomingCall" 
         class="i-ph-phone-incoming-fill text-base inline-block flex-shrink-0 text-green-600 dark:text-green-400 mr-1"
         :class="{ 'pulse-animation': normalizedCallStatus === 'ringing' }"></i>
            
      <!-- Ringing outgoing call -->
      <i v-else 
         class="i-ph-phone-outgoing-fill text-base inline-block flex-shrink-0 text-green-600 dark:text-green-400 mr-1"
         :class="{ 'pulse-animation': normalizedCallStatus === 'ringing' }"></i>
      <span class="text-current truncate">{{ callStatusText }}</span>
      <span 
        v-if="normalizedCallStatus === 'ringing'"
        class="flex-shrink-0 text-xs font-medium text-green-600 dark:text-green-400"
      >
        ({{ t('CONVERSATION.VOICE_CALL.JOIN_CALL') }})
      </span>
    </div>
    
    <!-- Regular Message -->
    <p v-else class="w-full mb-0 text-sm leading-7 text-n-slate-12 line-clamp-2">
      {{ lastNonActivityMessageContent }}
    </p>
    
    <div class="flex items-center flex-shrink-0 gap-2 pb-2">
      <Avatar
        :name="assignee.name"
        :src="assignee.thumbnail"
        :size="20"
        :status="assignee.status"
        rounded-full
      />
      <div
        v-if="unreadMessagesCount > 0"
        class="inline-flex items-center justify-center rounded-full size-5 bg-n-brand"
      >
        <span class="text-xs font-semibold text-white">
          {{ unreadMessagesCount }}
        </span>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
/* Animation for ringing calls */
.pulse-animation {
  animation: icon-pulse 1.5s infinite;
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
