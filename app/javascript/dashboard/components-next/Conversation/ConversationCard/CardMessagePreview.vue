<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { useVoiceCallHelpers } from 'dashboard/composables/useVoiceCallHelpers';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();
const { getPlainText } = useMessageFormatter();

// Use our shared voice call helper
const {
  isVoiceChannelConversation,
  hasArrow: checkHasArrow,
  isIncomingCall: checkIsIncoming,
  normalizeCallStatus,
  getCallIconName,
  getStatusText,
  processArrowContent,
} = useVoiceCallHelpers(props, { t });

// Utility function to find the last voice call message in conversation
const findVoiceCallMessage = (conversation) => {
  // If conversation has messages property, look for voice call messages
  if (conversation && conversation.messages && Array.isArray(conversation.messages)) {
    // Look through messages in reverse to find the latest voice call
    for (let i = conversation.messages.length - 1; i >= 0; i--) {
      const msg = conversation.messages[i];
      if (msg.content_type === 'voice_call' || msg.content_type === 'voice') {
        return msg;
      }
    }
  }
  
  // If no voice call found in messages or messages not available, check lastNonActivityMessage
  const { lastNonActivityMessage } = conversation || {};
  
  if (lastNonActivityMessage?.content_type === 'voice_call' || 
      lastNonActivityMessage?.content_type === 'voice') {
    return lastNonActivityMessage;
  }
  
  // Check if conversation has a call_status in additional_attributes
  // This is a strong indicator of a voice call conversation
  if (conversation?.additional_attributes?.call_status) {
    // If we have a call status but no voice call message, the lastNonActivityMessage
    // might still be related to the call (even if it doesn't have the right content_type)
    if (lastNonActivityMessage) {
      return lastNonActivityMessage;
    }
  }
  
  // As a fallback, check if last message content includes "Voice Call" or common call-related terms
  if (lastNonActivityMessage?.content && 
      typeof lastNonActivityMessage.content === 'string') {
    const content = lastNonActivityMessage.content.toLowerCase();
    if (content.includes('voice call') || 
        content.includes('call ') || 
        content.includes('missed call') || 
        content.includes('incoming call') || 
        content.includes('outgoing call') ||
        content.startsWith('←') || 
        content.startsWith('→')) {
      return lastNonActivityMessage;
    }
  }
  
  return null;
};

const voiceCallMessage = computed(() => {
  return findVoiceCallMessage(props.conversation);
});

const isVoiceCall = computed(() => {
  // Force voice call view for voice channel conversations
  if (isVoiceChannelConversation.value) {
    return true;
  }
  
  // Check if conversation has a call_status in additional_attributes
  if (props.conversation?.additional_attributes?.call_status) {
    return true;
  }
  
  // Check for voice call message
  return !!voiceCallMessage.value;
});

const callData = computed(() => {
  if (!isVoiceCall.value) return {};
  
  // First check for data directly in conversation attributes
  const conversationAttributes = props.conversation?.custom_attributes || 
                                 props.conversation?.additional_attributes || {};
  if (conversationAttributes.call_data) {
    return conversationAttributes.call_data;
  }
  
  // Then check message content attributes
  if (voiceCallMessage.value?.content_attributes?.data) {
    return voiceCallMessage.value.content_attributes.data;
  }
  
  return {};
});

const hasArrow = computed(() => {
  return checkHasArrow(voiceCallMessage.value);
});

const isIncomingCall = computed(() => {
  if (!isVoiceCall.value) return null;
  
  // Get the conversation call_status
  const conversationCallStatus = props.conversation?.additional_attributes?.call_status;
  
  return checkIsIncoming(callData.value, voiceCallMessage.value);
});

const normalizedCallStatus = computed(() => {
  if (!isVoiceCall.value) return '';
  
  // First check for direct call_status in the conversation additional_attributes
  // This is the most authoritative source for call status
  const conversationCallStatus = props.conversation?.additional_attributes?.call_status;
  if (conversationCallStatus) {
    return normalizeCallStatus(conversationCallStatus, isIncomingCall.value);
  }
  
  // If there's an arrow in the message, this is a legacy format message
  if (hasArrow.value) {
    const content = voiceCallMessage.value?.content || '';
    if (content.includes('ended') || content.includes('Call ended')) {
      return 'ended';
    }
    if (content.includes('missed') || content.includes('Missed call') || content.includes('no answer')) {
      return isIncomingCall.value ? 'missed' : 'no-answer';
    }
    if (content.includes('in progress') || content.includes('active') || content.includes('answered')) {
      return 'active';
    }
    
    // For voice channel conversations, default to ended for better display
    if (isVoiceChannelConversation.value) {
      return 'ended';
    }
    
    // Default to ended for legacy messages
    return 'ended';
  }
  
  // Apply the same status mapping logic as VoiceCall component
  const callStatus = callData.value?.status;
  if (callStatus) {
    return normalizeCallStatus(callStatus, isIncomingCall.value);
  }
  
  // Determine status from timestamps
  if (callData.value?.ended_at) {
    return 'ended';
  }
  if (callData.value?.missed) {
    return isIncomingCall.value ? 'missed' : 'no-answer';
  }
  if (callData.value?.started_at || props.conversation?.additional_attributes?.call_started_at) {
    return 'active';
  }
  
  // For voice channel conversations, default to ended for better display
  if (isVoiceChannelConversation.value) {
    return 'ended';
  }
  
  // Default to ended for any remaining cases to avoid showing incorrect status
  return 'ended';
});

const callIconName = computed(() => {
  return getCallIconName(normalizedCallStatus.value, isIncomingCall.value);
});

const callStatusText = computed(() => {
  if (!isVoiceCall.value) return '';
  
  // For voice channel conversations, force more descriptive text
  if (isVoiceChannelConversation.value) {
    return getStatusText(normalizedCallStatus.value, isIncomingCall.value);
  }
  
  // For legacy messages with arrows, just use a cleaner version of the content
  if (hasArrow.value && voiceCallMessage.value?.content) {
    return processArrowContent(
      voiceCallMessage.value.content, 
      isIncomingCall.value, 
      normalizedCallStatus.value
    );
  }
  
  // Generate the correct status text based on call status and direction
  return getStatusText(normalizedCallStatus.value, isIncomingCall.value);
});

// Return proper message content based on message type
const lastNonActivityMessageContent = computed(() => {
  const { lastNonActivityMessage = {}, customAttributes = {} } =
    props.conversation;
  const { email: { subject } = {} } = customAttributes;
  
  // Return special formatting for voice calls
  if (isVoiceCall.value) {
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
      v-if="isVoiceCall" 
      class="w-full mb-0 text-sm flex items-center gap-1 pt-0.5"
      :class="{
        'text-green-600 dark:text-green-400': normalizedCallStatus === 'ringing',
        'text-woot-600 dark:text-woot-400': normalizedCallStatus === 'active',
        'text-red-600 dark:text-red-400': normalizedCallStatus === 'missed' || normalizedCallStatus === 'no-answer',
        'text-slate-600 dark:text-slate-400': normalizedCallStatus === 'ended'
      }"
    >
      <!-- Explicit icon based on call status - force specific icons instead of computed properties -->
      <i v-if="normalizedCallStatus === 'missed' || normalizedCallStatus === 'no-answer'" 
         class="i-ph-phone-x-fill text-base inline-block flex-shrink-0 text-red-600 dark:text-red-400 mr-1"></i>
            
      <i v-else-if="normalizedCallStatus === 'active'" 
         class="i-ph-phone-call-fill text-base inline-block flex-shrink-0 text-woot-600 dark:text-woot-400 mr-1"></i>
            
      <i v-else-if="normalizedCallStatus === 'ended' || normalizedCallStatus === 'completed'" 
         class="i-ph-phone-fill text-base inline-block flex-shrink-0 text-slate-600 dark:text-slate-400 mr-1"></i>
            
      <i v-else-if="isIncomingCall" 
         class="i-ph-phone-incoming-fill text-base inline-block flex-shrink-0 text-green-600 dark:text-green-400 mr-1"
         :class="{ 'pulse-animation': normalizedCallStatus === 'ringing' }"></i>
            
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
