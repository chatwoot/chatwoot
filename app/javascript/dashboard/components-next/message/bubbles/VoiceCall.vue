<template>
  <div
    class="flex-col border border-slate-100 dark:border-slate-700 rounded-lg overflow-hidden w-full max-w-xs"
    :class="statusClass"
  >
    <div class="flex items-center p-3 gap-3 w-full">
      <!-- Call Icon -->
      <div
        class="shrink-0 flex items-center justify-center size-10 rounded-full"
        :class="iconBgClass"
      >
        <span
          :class="[iconName, 'text-white text-xl']"
        ></span>
      </div>
      
      <!-- Call Info -->
      <div class="flex flex-col flex-grow overflow-hidden">
        <span class="text-base font-medium" :class="labelTextClass">
          {{ labelText }}
        </span>
        <span class="text-xs text-slate-500">
          {{ subtextWithDuration }}
        </span>
      </div>
    </div>
    
    <template v-if="hasAudioAttachment && recordingUrl">
      <div class="w-full m-0 p-1 min-w-[260px]">
        <audio
          ref="audioPlayer"
          :src="recordingUrl"
          preload="metadata"
          @ended="handlePlaybackEnd"
          controls
          class="w-full"
        />
      </div>
    </template>
  </div>
</template>

<script>
import { useVoiceCallHelpers } from 'dashboard/composables/useVoiceCallHelpers';

export default {
  name: 'VoiceCallBubble',
  components: {
  },
  inject: ['$emit'],
  props: {
    message: {
      type: Object,
      default: () => ({}),
    },
    isInbox: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      internalStatus: '',
      refreshInterval: null,
      statusCheckInterval: null,
      isAnimating: false,
      recordingUrl: '',
      isPlaying: false,
      hasAudioAttachment: false,
    };
  },
  setup(props) {
    // Initialize our composable for use in methods
    const { 
      normalizeCallStatus,
      isIncomingCall,
      getCallIconName,
      getStatusText 
    } = useVoiceCallHelpers({ conversation: props.message?.conversation }, { 
      t: (key) => { 
        // This is a simple passthrough for the t function since we're in options API
        // In setup() we can't access this.$t directly
        return key; 
      }
    });

    // Expose these helpers to the component instance
    return {
      normalizeCallHelper: normalizeCallStatus,
      checkIsIncoming: isIncomingCall,
      getCallIconHelper: getCallIconName,
      getStatusTextHelper: getStatusText
    };
  },
  computed: {
    callData() {
      return this.message?.contentAttributes?.data || {};
    },
    
    directionalStatus() {
      const direction = this.callData?.call_direction;
      if (direction) {
        return direction === 'inbound' ? 'inbound' : 'outbound';
      }
      return this.message?.messageType === 0 ? 'inbound' : 'outbound';
    },
    
    isIncoming() {
      return this.directionalStatus === 'inbound';
    },
    
    isOutgoing() {
      return this.directionalStatus === 'outbound';
    },
    
    status() {
      // Use internal status if we have one (from UI updates)
      if (this.internalStatus) {
        return this.internalStatus;
      }
      
      // First check for direct call_status in the conversation additional_attributes
      // This is the most authoritative source for call status
      const conversationCallStatus = this.message?.conversation?.additional_attributes?.call_status;
      if (conversationCallStatus) {
        // Use our composable helper for status normalization
        return this.normalizeCallHelper(conversationCallStatus, this.isIncoming);
      }
      
      // Use the status from call data if present
      const callStatus = this.callData?.status;
      if (callStatus) {
        // Use our composable helper for status normalization
        return this.normalizeCallHelper(callStatus, this.isIncoming);
      }
      
      // Determine status from timestamps
      if (this.callData?.ended_at) {
        return 'ended';
      }
      if (this.callData?.missed) {
        return this.isIncoming ? 'missed' : 'no-answer';
      }
      
      // Check both message data and conversation data for started_at
      if (this.callData?.started_at || 
          this.message?.conversation?.additional_attributes?.call_started_at) {
        return 'active';
      }
      
      // Default to ringing
      return 'ringing';
    },
    
    formattedDuration() {
      if (
        this.callData?.started_at &&
        (this.status === 'active' || this.status === 'ended')
      ) {
        const startTime = new Date(this.callData.started_at);
        const endTime = this.callData?.ended_at
          ? new Date(this.callData.ended_at)
          : new Date();
        
        const durationMs = endTime - startTime;
        return this.formatDuration(durationMs);
      }
      return '';
    },
    
    statusClass() {
      return {
        'bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100': !this.isInbox,
        'bg-slate-50 dark:bg-slate-900 text-slate-900 dark:text-slate-100': this.isInbox,
        'call-ringing': this.status === 'ringing',
      };
    },
    
    iconName() {
      // Use our composable helper for icon selection
      return this.getCallIconHelper(this.status, this.isIncoming);
    },
    
    iconBgClass() {
      // Icon background colors based on status
      if (this.status === 'active') {
        return 'bg-green-500'; // Green for calls in progress
      }
      
      if (this.status === 'missed' || this.status === 'no-answer') {
        return 'bg-red-500'; // Red for missed calls
      }
      
      if (this.status === 'ended') {
        return 'bg-purple-500'; // Purple for ended calls
      }
      
      // Default green for ringing
      return 'bg-green-500 pulse-animation';
    },
    
    labelText() {
      // Use our composable helper to get status text
      // We need to convert the key to the actual text since we're in options API
      const key = this.getStatusTextHelper(this.status, this.isIncoming);
      
      // Special cases for floating widget compatibility
      if (this.status === 'ringing') {
        if (this.isIncoming) {
          return this.$t('CONVERSATION.VOICE_CALL.INCOMING');
        } else {
          return this.$t('CONVERSATION.VOICE_CALL.OUTGOING');
        }
      }
      
      // Map the key to the translated text
      return this.$t(key);
    },
    
    labelTextClass() {
      if (this.status === 'missed' || this.status === 'no-answer') {
        return 'text-red-500';
      }
      return '';
    },
    
    subtext() {
      // Checking call direction and status
      const direction = this.isIncoming ? 'incoming' : 'outgoing';
      
      // Check if we have agent_joined flag to determine if agent answered
      const agentJoined = this.message?.conversation?.additional_attributes?.agent_joined === true;
      const callStarted = !!this.message?.conversation?.additional_attributes?.call_started_at;
      
      // Special handling for incoming calls that were previously joined but now ended
      // This avoids showing "You didn't answer" when agent actually did answer
      if (this.isIncoming && this.status === 'missed' && (agentJoined || callStarted)) {
        return this.$t('CONVERSATION.VOICE_CALL.YOU_ANSWERED');
      }
      
      // Common subtext for all statuses
      const subtextMap = {
        incoming: {
          ringing: this.$t('CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET'),
          active: this.$t('CONVERSATION.VOICE_CALL.YOU_ANSWERED'),
          missed: this.$t('CONVERSATION.VOICE_CALL.YOU_DIDNT_ANSWER'),
          ended: this.$t('CONVERSATION.VOICE_CALL.YOU_ANSWERED')
        },
        outgoing: {
          ringing: this.$t('CONVERSATION.VOICE_CALL.YOU_CALLED'),
          active: this.$t('CONVERSATION.VOICE_CALL.THEY_ANSWERED'),
          'no-answer': this.$t('CONVERSATION.VOICE_CALL.YOU_CALLED'),
          ended: this.$t('CONVERSATION.VOICE_CALL.YOU_CALLED'),
          completed: this.$t('CONVERSATION.VOICE_CALL.YOU_CALLED'),
          canceled: this.$t('CONVERSATION.VOICE_CALL.YOU_CALLED'),
          failed: this.$t('CONVERSATION.VOICE_CALL.YOU_CALLED'),
          busy: this.$t('CONVERSATION.VOICE_CALL.YOU_CALLED')
        }
      };
      
      // First check if we have a specific message for this status
      if (subtextMap[direction] && subtextMap[direction][this.status]) {
        return subtextMap[direction][this.status];
      }
      
      // Default for missing statuses
      if (this.isIncoming) {
        if (this.status === 'ringing') {
          return this.$t('CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET');
        } else if (agentJoined || callStarted) {
          return this.$t('CONVERSATION.VOICE_CALL.YOU_ANSWERED');
        } else {
          return this.$t('CONVERSATION.VOICE_CALL.YOU_DIDNT_ANSWER');
        }
      } else {
        return this.$t('CONVERSATION.VOICE_CALL.YOU_CALLED');
      }
    },
    
    subtextWithDuration() {
      // Checking if we have start and end timestamps for duration calculation
      let durationToShow = this.formattedDuration;
      
      // Check if we have explicit call duration from the content attributes
      if (!durationToShow && this.callData?.duration) {
        const durationSeconds = parseInt(this.callData.duration, 10);
        if (!isNaN(durationSeconds) && durationSeconds > 0) {
          const minutes = Math.floor(durationSeconds / 60);
          const seconds = durationSeconds % 60;
          durationToShow = `${minutes}:${seconds.toString().padStart(2, '0')}`;
        }
      }
      
      // For completed calls, always show the duration if we have it
      const shouldShowDuration = 
        (this.status === 'ended' || this.status === 'completed') && 
        durationToShow;
      
      if (shouldShowDuration) {
        return `${this.subtext} · ${durationToShow}`;
      }
      
      return this.subtext;
    }
  },
  watch: {
    message: {
      handler() {
        this.setupVoiceCall();
        this.setAudioAttachment();
      },
      deep: true,
    },
  },
  mounted() {
    this.setupVoiceCall();
    this.setAudioAttachment();
  },
  beforeUnmount() {
    // Clean up all intervals to prevent memory leaks
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval);
      this.refreshInterval = null;
    }
    
    if (this.statusCheckInterval) {
      clearInterval(this.statusCheckInterval);
      this.statusCheckInterval = null;
    }
  },
  methods: {
    formatDuration(milliseconds) {
      // Convert milliseconds to seconds
      const totalSeconds = Math.floor(milliseconds / 1000);
      
      // Calculate minutes and remaining seconds
      const minutes = Math.floor(totalSeconds / 60);
      const seconds = totalSeconds % 60;
      
      // Format as MM:SS with leading zeros
      return `${minutes}:${seconds.toString().padStart(2, '0')}`;
    },
    setupVoiceCall() {
      if (this.refreshInterval) {
        clearInterval(this.refreshInterval);
      }
      
      // Create refresh interval for active calls to update duration
      if (this.status === 'active') {
        this.refreshInterval = setInterval(() => {
          this.$forceUpdate();
        }, 1000);
        
        // Set animation flag
        this.isAnimating = true;
      } else {
        this.isAnimating = false;
      }
      
      // Always check for call status changes, not just when ringing
      if (true) { // Always run status checks
        // Create a separate interval to check if the call status has changed
        this.statusCheckInterval = setInterval(() => {
          // Check if content_attributes has been updated with new status
          const updatedStatus = this.callData?.status;
          const statusUpdatedAt = this.callData?.status_updated;
          
          // Also check the conversation's call status (which might be more authoritative)
          const conversationStatus = this.message?.conversation?.additional_attributes?.call_status;
          
          // Check for any status changes from either source
          const hasMessageStatusChanged = updatedStatus && 
                                         updatedStatus !== this.internalStatus && 
                                         statusUpdatedAt;
                                         
          const hasConversationStatusChanged = conversationStatus && 
                                              conversationStatus !== this.internalStatus;
          
          // If either status has changed, update UI
          if (hasMessageStatusChanged || hasConversationStatusChanged) {
            // Prefer the conversation status if available (more reliable)
            const newStatus = conversationStatus || updatedStatus;
            
            // Status has changed, update UI
            this.updateStatus(newStatus);
            this.$forceUpdate();
            
            // If call is now active or ended, update UI
            if (newStatus === 'active' || newStatus === 'in-progress') {
              this.setupVoiceCall();
            }
          }
        }, 1000); // Check more frequently - every 1 second
      } else if (this.statusCheckInterval) {
        clearInterval(this.statusCheckInterval);
        this.statusCheckInterval = null;
      }
    },
    updateStatus(newStatus) {
      if (
        newStatus &&
        newStatus !== this.status &&
        newStatus !== this.internalStatus
      ) {
        this.internalStatus = newStatus;
      }
    },
    handlePlaybackEnd() {
      this.isPlaying = false;
    },
    setAudioAttachment() {
      // Look for audio attachment in message.attachments or message.contentAttributes.attachments
      let attachments = [];
      if (this.message?.attachments && Array.isArray(this.message.attachments)) {
        attachments = this.message.attachments;
      } else if (this.message?.contentAttributes?.attachments && Array.isArray(this.message.contentAttributes.attachments)) {
        attachments = this.message.contentAttributes.attachments;
      }
      // Find the first audio attachment, supporting both camelCase and snake_case fields
      const audio = attachments.find(att => {
        if (!att) return false;
        // Check file_type or fileType
        if ((att.file_type && att.file_type.startsWith('audio')) ||
            (att.fileType && att.fileType.startsWith('audio'))) return true;
        // Check content_type or contentType
        if ((att.content_type && att.content_type.startsWith('audio')) ||
            (att.contentType && att.contentType.startsWith('audio'))) return true;
        // Check data_url or dataUrl
        if ((att.data_url && att.data_url.match(/\.(mp3|wav|ogg|m4a)$/i)) ||
            (att.dataUrl && att.dataUrl.match(/\.(mp3|wav|ogg|m4a)$/i))) return true;
        // Check file_url or fileUrl
        if ((att.file_url && att.file_url.match(/\.(mp3|wav|ogg|m4a)$/i)) ||
            (att.fileUrl && att.fileUrl.match(/\.(mp3|wav|ogg|m4a)$/i))) return true;
        return false;
      });
      if (audio) {
        this.recordingUrl = audio.data_url || audio.file_url || audio.dataUrl || audio.fileUrl || '';
        this.hasAudioAttachment = true;
      } else {
        this.recordingUrl = '';
        this.hasAudioAttachment = false;
      }
    }
  },
};
</script>

<style lang="scss" scoped>
/* Voice call styling */
.pulse-animation {
  animation: pulse 1.5s infinite;
}

.call-ringing {
  animation: border-pulse 1.5s infinite;
}

@keyframes pulse {
  0% {
    box-shadow: 0 0 0 0 rgba(34, 197, 94, 0.4); /* Green for ringing */
  }
  70% {
    box-shadow: 0 0 0 10px rgba(34, 197, 94, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(34, 197, 94, 0);
  }
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