<template>
  <div class="voice-call-widget" :class="statusClass">
    <div class="status-icon">
      <span :class="statusIcon"></span>
    </div>
    <div class="call-info">
      <div class="call-status">{{ callStatusText }}</div>
      <div v-if="statusSubtext" class="call-subtext">{{ statusSubtext }}</div>
    </div>
    <NextButton
      v-if="showJoinButton"
      size="sm"
      icon="i-lucide-phone"
      variant="success"
      :label="$t('CONVERSATION.VOICE_CALL.JOIN_CALL')"
      :is-loading="isLoading"
      @click="joinCall"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import VoiceAPI from 'dashboard/api/channels/voice';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  props: {
    message: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
      status: this.message.content_attributes?.data?.status || 'ringing',
      joinedAt: null,
      duration: this.message.content_attributes?.data?.duration || null,
    };
  },
  watch: {
    // Watch for changes to message content_attributes to update call status
    'message.content_attributes.data': {
      handler(newData) {
        if (newData) {
          if (newData.status && newData.status !== this.status) {
            const oldStatus = this.status;
            this.status = newData.status;
            
            // If call status changes to 'ended' or 'missed', close the floating call widget
            if ((newData.status === 'ended' || newData.status === 'missed') && 
                ['ringing', 'active'].includes(oldStatus)) {
              this.closeCallWidget();
            }
          }
          if (newData.duration && newData.duration !== this.duration) {
            this.duration = newData.duration;
          }
        }
      },
      deep: true,
    },
  },
  computed: {
    ...mapGetters({
      currentConversationId: 'getSelectedChatConversationId',
    }),
    hasActiveCall() {
      return this.$store.getters['calls/hasActiveCall'];
    },
    callData() {
      return this.message.content_attributes?.data || {};
    },
    callStatusText() {
      switch (this.status) {
        case 'ringing':
          return this.$t('CONVERSATION.VOICE_CALL.RINGING');
        case 'active':
          return this.$t('CONVERSATION.VOICE_CALL.ACTIVE');
        case 'missed':
          return this.$t('CONVERSATION.VOICE_CALL.MISSED');
        case 'ended':
          return this.$t('CONVERSATION.VOICE_CALL.ENDED');
        default:
          return this.$t('CONVERSATION.VOICE_CALL.INCOMING_CALL');
      }
    },
    statusIcon() {
      switch (this.status) {
        case 'ringing':
          return 'i-lucide-phone-incoming';
        case 'active':
          return 'i-lucide-phone';
        case 'missed':
          return 'i-lucide-phone-missed';
        case 'ended':
          return 'i-lucide-phone-off';
        default:
          return 'i-lucide-phone-incoming';
      }
    },
    statusClass() {
      return {
        'ringing': this.status === 'ringing',
        'active': this.status === 'active',
        'missed': this.status === 'missed',
        'ended': this.status === 'ended',
      };
    },
    callConversationId() {
      return this.callData.conversation_id;
    },
    showJoinButton() {
      // Show join button only if the call is ringing or active and we're on the same conversation
      return (['ringing', 'active'].includes(this.status)) && 
             (this.callConversationId === this.currentConversationId);
    },
    formattedDuration() {
      if (!this.duration) return '';
      
      const minutes = Math.floor(this.duration / 60);
      const seconds = this.duration % 60;
      return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    },
    statusSubtext() {
      if (this.status === 'ended' && this.formattedDuration) {
        return this.$t('CONVERSATION.VOICE_CALL.DURATION', { duration: this.formattedDuration });
      }
      if (this.status === 'missed') {
        return this.$t('CONVERSATION.VOICE_CALL.MISSED_CALL');
      }
      return '';
    },
    isIncoming() {
      return this.message.message_type === 0; // 0 = incoming
    },
    isOutgoing() {
      return this.message.message_type === 1; // 1 = outgoing
    },
    senderText() {
      if (this.isIncoming) {
        return this.$t('CONVERSATION.VOICE_CALL.INCOMING_FROM', { name: this.message.sender?.name || 'Unknown' });
      }
      if (this.isOutgoing) {
        return this.$t('CONVERSATION.VOICE_CALL.OUTGOING_FROM', { name: this.message.sender?.name || 'Unknown' });
      }
      return '';
    },
  },
  mounted() {
    // We don't need custom subscriptions anymore as we'll
    // get updates through Chatwoot's standard message update system
    // Just check if we have an active call with the same call_sid
    this.checkActiveCall();
  },
  methods: {
    async joinCall() {
      this.isLoading = true;
      try {
        // Update UI immediately
        this.status = 'active';
        this.joinedAt = new Date();
        
        // Get the current conversation
        const conversation = await this.$store.dispatch('getConversation', {
          conversationId: this.callConversationId,
        });
        
        const callSid = this.callData.call_sid;
        
        if (!callSid) {
          throw new Error('No call SID found');
        }
        
        // Show floating call widget
        this.$store.dispatch('calls/setActiveCall', {
          callSid,
          conversationId: this.callConversationId,
          inboxId: this.message.inbox_id,
          contactId: conversation.contact_id,
          contactName: conversation.contact?.name || 'Unknown',
          messageId: this.message.id,
        });
        
        // Join the call via API
        await VoiceAPI.joinCall({
          call_sid: callSid,
          conversation_id: this.callConversationId,
        });
        
        // Success notification
        useAlert(this.$t('CONVERSATION.VOICE_CALL.CALL_JOINED'));
      } catch (err) {
        console.error('Failed to join call:', err);
        useAlert(this.$t('CONVERSATION.VOICE_CALL.JOIN_ERROR'));
        // Reset status if join failed
        this.status = 'ringing';
      } finally {
        this.isLoading = false;
      }
    },
    
    // We don't need custom subscription methods anymore as we'll use
    // Chatwoot's standard message update events
    
    checkActiveCall() {
      // If there's an active call in the store with the same conversation ID
      // update our local state to match
      const activeCall = this.$store.getters['calls/getActiveCall'];
      if (activeCall && activeCall.conversationId === this.callConversationId) {
        this.status = 'active';
        this.joinedAt = new Date();
      }
    },
    
    updateStatus(newStatus, duration = null) {
      this.status = newStatus;
      
      if (newStatus === 'ended') {
        if (duration) {
          this.duration = duration;
        } else if (this.joinedAt) {
          this.duration = Math.floor((new Date() - this.joinedAt) / 1000);
        }
        // Close the floating call widget when call ends
        this.closeCallWidget();
      }
    },
    
    closeCallWidget() {
      // Get the call SID from the message data
      const callSid = this.callData.call_sid;
      if (!callSid) return;
      
      // Handle the call status change directly
      this.$store.dispatch('calls/handleCallStatusChanged', {
        callSid,
        status: 'ended'
      });
    },
  },
};
</script>

<style lang="scss" scoped>
.voice-call-widget {
  @apply flex items-center gap-2 p-3 rounded-lg my-1;
  @apply bg-slate-50 dark:bg-slate-700;
  @apply border border-slate-200 dark:border-slate-600;
  @apply transition-all duration-200;
  
  &.ringing {
    @apply border-green-500 dark:border-green-500;
    animation: pulse 1.5s infinite;
  }
  
  &.active {
    @apply border-woot-500 dark:border-woot-500 bg-woot-50 dark:bg-woot-800;
  }
  
  &.missed {
    @apply border-red-300 dark:border-slate-600 bg-red-50 dark:bg-slate-700;
  }
  
  &.ended {
    @apply border-slate-300 dark:border-slate-600;
  }
  
  .status-icon {
    @apply flex items-center justify-center;
    @apply w-10 h-10 rounded-full;
    @apply bg-slate-200 dark:bg-slate-600;
    @apply text-slate-700 dark:text-slate-200;
    
    .i-lucide-phone-incoming {
      @apply text-green-600 dark:text-green-400;
    }
    
    .i-lucide-phone {
      @apply text-woot-600 dark:text-woot-400;
    }
    
    .i-lucide-phone-missed {
      @apply text-red-600 dark:text-red-400;
    }
    
    .i-lucide-phone-off {
      @apply text-slate-600 dark:text-slate-400;
    }
  }
  
  .call-info {
    @apply flex-1;
    
    .call-status {
      @apply font-medium text-slate-800 dark:text-slate-200;
    }
    
    .call-subtext {
      @apply text-xs text-slate-500 dark:text-slate-400;
    }
  }
}

@keyframes pulse {
  0% {
    box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.3);
  }
  70% {
    box-shadow: 0 0 0 8px rgba(16, 185, 129, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(16, 185, 129, 0);
  }
}
</style>