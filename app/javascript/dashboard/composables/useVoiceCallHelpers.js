import { computed } from 'vue';

export const useVoiceCallHelpers = (props, { t }) => {
  // Check if the conversation is from a voice channel
  const isVoiceChannelConversation = computed(() => {
    return props.conversation?.meta?.inbox?.channel_type === 'Channel::Voice';
  });
  
  // Helper function to find call information from various sources
  const getCallData = (conversation) => {
    if (!conversation) return {};
    
    // First check for data directly in conversation attributes
    const conversationAttributes = conversation.custom_attributes || conversation.additional_attributes || {};
    if (conversationAttributes.call_data) {
      return conversationAttributes.call_data;
    }
    
    return {};
  };
  
  // Check if a message has an arrow prefix
  const hasArrow = (message) => {
    if (!message?.content) return false;
    
    return (
      typeof message.content === 'string' && 
      (message.content.startsWith('←') || 
       message.content.startsWith('→') ||
       message.content.startsWith('↔️'))
    );
  };
  
  // Determine if it's an incoming call
  const isIncomingCall = (callData, message) => {
    if (!message) return null;
    
    // Check for arrow in content
    if (hasArrow(message)) {
      return message.content.startsWith('←');
    }
    
    // Try to use the direction stored in the call data
    if (callData?.call_direction) {
      return callData.call_direction === 'inbound';
    }
    
    // Fall back to message_type
    return message.message_type === 0;
  };
  
  // Get normalized call status from multiple sources
  const normalizeCallStatus = (status, isIncoming) => {
    // Map from Twilio status to our UI status
    const statusMap = {
      'in-progress': 'active',
      'completed': 'ended',
      'canceled': 'ended',
      'failed': 'ended',
      'busy': 'no-answer',
      'no-answer': isIncoming ? 'missed' : 'no-answer',
      'active': 'active',
      'missed': 'missed',
      'ended': 'ended',
      'ringing': 'ringing'
    };
    
    return statusMap[status] || status;
  };
  
  // Get the appropriate icon for a call status
  const getCallIconName = (status, isIncoming) => {
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
  };
  
  // Get the appropriate text for a call status
  const getStatusText = (status, isIncoming) => {
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
  };
  
  // Process message content with arrow prefix
  const processArrowContent = (content, isIncoming, normalizedStatus) => {
    // Remove arrows and clean up the text
    let text = content.replace(/^[←→↔️]/, '').trim();
    
    // If it only says "Voice Call" or "jo", add more descriptive status info
    if (text === 'Voice Call' || text === 'jo' || text === '') {
      return getStatusText(normalizedStatus, isIncoming);
    }
    
    return text;
  };
  
  return {
    isVoiceChannelConversation,
    getCallData,
    hasArrow,
    isIncomingCall,
    normalizeCallStatus,
    getCallIconName,
    getStatusText,
    processArrowContent,
  };
};