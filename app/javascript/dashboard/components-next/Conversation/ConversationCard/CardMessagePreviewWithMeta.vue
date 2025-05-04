<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { useVoiceCallHelpers } from 'dashboard/composables/useVoiceCallHelpers';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import CardLabels from 'dashboard/components-next/Conversation/ConversationCard/CardLabels.vue';
import SLACardLabel from 'dashboard/components-next/Conversation/ConversationCard/SLACardLabel.vue';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
  accountLabels: {
    type: Array,
    required: true,
  },
});

const { t } = useI18n();

const slaCardLabelRef = ref(null);

const { getPlainText } = useMessageFormatter();

// Use our voice call helpers composable
const {
  isVoiceChannelConversation,
  hasArrow,
  isIncomingCall: checkIsIncoming,
  normalizeCallStatus,
  getCallIconName,
  getStatusText,
  processArrowContent,
} = useVoiceCallHelpers(props, { t });

// Force voice call view for voice channel conversations
const isVoiceCall = computed(() => {
  if (isVoiceChannelConversation.value) {
    return true;
  }
  
  // Check if conversation has a call_status in additional_attributes
  if (props.conversation?.additional_attributes?.call_status) {
    return true;
  }
  
  // Check for voice call in last message
  const { lastNonActivityMessage } = props.conversation || {};
  if (lastNonActivityMessage?.content_type === 'voice_call' || 
      lastNonActivityMessage?.content_type === 'voice') {
    return true;
  }
  
  // Look for voice call content with expanded terms
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
      return true;
    }
  }
  
  return false;
});

// Check if content has arrow prefix using our helper
const messageHasArrow = computed(() => {
  const { lastNonActivityMessage } = props.conversation || {};
  return hasArrow(lastNonActivityMessage);
});

// Get call data from multiple sources
const callData = computed(() => {
  // First check for data directly in conversation attributes
  const conversationAttributes = props.conversation?.custom_attributes || {};
  if (conversationAttributes.call_data) {
    return conversationAttributes.call_data;
  }
  
  // Then check message content attributes
  const { lastNonActivityMessage } = props.conversation || {};
  if (lastNonActivityMessage?.content_attributes?.data) {
    return lastNonActivityMessage.content_attributes.data;
  }
  
  return {};
});

const isIncomingCall = computed(() => {
  if (!isVoiceCall.value) return null;
  
  const { lastNonActivityMessage } = props.conversation || {};
  return checkIsIncoming(callData.value, lastNonActivityMessage);
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
  if (messageHasArrow.value) {
    const { lastNonActivityMessage } = props.conversation || {};
    const content = lastNonActivityMessage?.content || '';
    
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
    
    // Default to 'ended' for any legacy messages without clear status
    return 'ended';
  }
  
  // Apply status mapping logic to call data status
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
  
  // For legacy messages with arrows, process using our helper
  if (messageHasArrow.value) {
    const { lastNonActivityMessage } = props.conversation || {};
    const content = lastNonActivityMessage?.content || '';
    
    // Process arrow content with our helper
    return processArrowContent(content, isIncomingCall.value, normalizedCallStatus.value);
  }
  
  // For voice channel conversations, use our helper for descriptive text
  if (isVoiceChannelConversation.value) {
    return getStatusText(normalizedCallStatus.value, isIncomingCall.value);
  }
  
  // Generate the correct status text based on call status and direction
  return getStatusText(normalizedCallStatus.value, isIncomingCall.value);
});

const lastNonActivityMessageContent = computed(() => {
  // If it's a voice call, use the voice call text with icon
  if (isVoiceCall.value) {
    return callStatusText.value;
  }
  
  // Otherwise use the regular message content
  const { lastNonActivityMessage = {}, customAttributes = {} } =
    props.conversation;
  const { email: { subject } = {} } = customAttributes;
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

const hasSlaThreshold = computed(() => {
  return (
    slaCardLabelRef.value?.hasSlaThreshold && props.conversation?.slaPolicyId
  );
});

defineExpose({
  hasSlaThreshold,
});
</script>

<template>
  <div class="flex flex-col w-full gap-1">
    <div class="flex items-center justify-between w-full gap-2 py-1 h-7">
      <!-- Voice Call Message display with icon -->
      <div 
        v-if="isVoiceCall" 
        class="flex items-center gap-1 mb-0 text-sm line-clamp-1"
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
      </div>
      
      <!-- Regular Message display -->
      <p v-else class="mb-0 text-sm leading-7 text-n-slate-12 line-clamp-1">
        {{ lastNonActivityMessageContent }}
      </p>

      <div
        v-if="unreadMessagesCount > 0"
        class="inline-flex items-center justify-center flex-shrink-0 rounded-full size-5 bg-n-brand"
      >
        <span class="text-xs font-semibold text-white">
          {{ unreadMessagesCount }}
        </span>
      </div>
    </div>

    <div
      class="grid items-center gap-2.5 h-7"
      :class="
        hasSlaThreshold
          ? 'grid-cols-[auto_auto_1fr_20px]'
          : 'grid-cols-[1fr_20px]'
      "
    >
      <SLACardLabel
        v-show="hasSlaThreshold"
        ref="slaCardLabelRef"
        :conversation="conversation"
      />
      <div v-if="hasSlaThreshold" class="w-px h-3 bg-n-slate-4" />
      <div class="overflow-hidden">
        <CardLabels
          :conversation-labels="conversation.labels"
          :account-labels="accountLabels"
        />
      </div>
      <Avatar
        :name="assignee.name"
        :src="assignee.thumbnail"
        :size="20"
        :status="assignee.status"
        rounded-full
      />
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
