<script>
export default {
  name: 'VoiceCallBubble',
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
  computed: {
    callData() {
      return this.message?.contentAttributes?.data || {};
    },

    isIncoming() {
      const direction = this.callData?.call_direction;
      if (direction) {
        return direction === 'inbound';
      }
      return this.message?.messageType === 0;
    },

    status() {
      // Get call status from conversation first (most authoritative)
      const conversationCallStatus =
        this.message?.conversation?.additional_attributes?.call_status;
      if (conversationCallStatus) {
        return this.normalizeStatus(conversationCallStatus);
      }

      // Use the status from call data if present
      const callStatus = this.callData?.status;
      if (callStatus) {
        return this.normalizeStatus(callStatus);
      }

      // Determine status from timestamps
      if (this.callData?.ended_at) {
        return 'ended';
      }
      if (this.callData?.missed) {
        return this.isIncoming ? 'missed' : 'no_answer';
      }

      // Check for started calls
      if (
        this.callData?.started_at ||
        this.message?.conversation?.additional_attributes?.call_started_at
      ) {
        return 'in_progress';
      }

      // Default to ringing
      return 'ringing';
    },

    iconName() {
      if (this.status === 'missed' || this.status === 'no_answer') {
        return 'i-ph-phone-x-fill';
      }

      if (this.status === 'in_progress') {
        return 'i-ph-phone-call-fill';
      }

      if (this.status === 'ended') {
        return this.isIncoming
          ? 'i-ph-phone-incoming-fill'
          : 'i-ph-phone-outgoing-fill';
      }

      // Default phone icon for ringing state
      return this.isIncoming
        ? 'i-ph-phone-incoming-fill'
        : 'i-ph-phone-outgoing-fill';
    },

    iconBgClass() {
      if (this.status === 'in_progress') {
        return 'bg-green-500';
      }

      if (this.status === 'missed' || this.status === 'no_answer') {
        return 'bg-red-500';
      }

      if (this.status === 'ended') {
        return 'bg-purple-500';
      }

      // Default green for ringing
      return 'bg-green-500 pulse-animation';
    },

    labelText() {
      if (this.status === 'in_progress') {
        return this.$t('CONVERSATION.VOICE_CALL.CALL_IN_PROGRESS');
      }

      if (this.isIncoming) {
        if (this.status === 'ringing') {
          return this.$t('CONVERSATION.VOICE_CALL.INCOMING_CALL');
        }
        if (this.status === 'missed') {
          return this.$t('CONVERSATION.VOICE_CALL.MISSED_CALL');
        }
        if (this.status === 'ended') {
          return this.$t('CONVERSATION.VOICE_CALL.CALL_ENDED');
        }
      } else {
        if (this.status === 'ringing') {
          return this.$t('CONVERSATION.VOICE_CALL.OUTGOING_CALL');
        }
        if (this.status === 'no_answer') {
          return this.$t('CONVERSATION.VOICE_CALL.NO_ANSWER');
        }
        if (this.status === 'ended') {
          return this.$t('CONVERSATION.VOICE_CALL.CALL_ENDED');
        }
      }

      return this.isIncoming
        ? this.$t('CONVERSATION.VOICE_CALL.INCOMING_CALL')
        : this.$t('CONVERSATION.VOICE_CALL.OUTGOING_CALL');
    },

    subtext() {
      // Check if we have agent_joined flag
      const agentJoined =
        this.message?.conversation?.additional_attributes?.agent_joined ===
        true;
      const callStarted =
        !!this.message?.conversation?.additional_attributes?.call_started_at;

      if (this.isIncoming) {
        if (this.status === 'ringing') {
          return this.$t('CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET');
        }
        if (this.status === 'in_progress') {
          return this.$t('CONVERSATION.VOICE_CALL.YOU_ANSWERED');
        }
        if (this.status === 'missed' && (agentJoined || callStarted)) {
          return this.$t('CONVERSATION.VOICE_CALL.YOU_ANSWERED');
        }
        if (this.status === 'missed') {
          return this.$t('CONVERSATION.VOICE_CALL.YOU_DIDNT_ANSWER');
        }
        if (this.status === 'ended') {
          return this.$t('CONVERSATION.VOICE_CALL.YOU_ANSWERED');
        }
      } else {
        if (this.status === 'ringing') {
          return this.$t('CONVERSATION.VOICE_CALL.YOU_CALLED');
        }
        if (this.status === 'in_progress') {
          return this.$t('CONVERSATION.VOICE_CALL.THEY_ANSWERED');
        }
        if (this.status === 'no_answer' || this.status === 'ended') {
          return this.$t('CONVERSATION.VOICE_CALL.YOU_CALLED');
        }
      }

      return this.isIncoming
        ? this.$t('CONVERSATION.VOICE_CALL.YOU_DIDNT_ANSWER')
        : this.$t('CONVERSATION.VOICE_CALL.YOU_CALLED');
    },

    statusClass() {
      return {
        'bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100':
          !this.isInbox,
        'bg-slate-50 dark:bg-slate-900 text-slate-900 dark:text-slate-100':
          this.isInbox,
        'call-ringing': this.status === 'ringing',
      };
    },
  },
  methods: {
    normalizeStatus(status) {
      // Unified status mapping
      const statusMap = {
        queued: 'ringing',
        initiated: 'ringing',
        ringing: 'ringing',
        'in-progress': 'in_progress',
        active: 'in_progress',
        completed: 'ended',
        ended: 'ended',
        missed: 'missed',
        busy: 'no_answer',
        failed: 'no_answer',
        'no-answer': 'no_answer',
        canceled: 'no_answer',
      };

      return statusMap[status] || status;
    },
  },
};
</script>

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
        <span class="text-white text-xl" :class="[iconName]" />
      </div>

      <!-- Call Info -->
      <div class="flex flex-col flex-grow overflow-hidden">
        <span class="text-base font-medium">
          {{ labelText }}
        </span>
        <span class="text-xs text-slate-500">
          {{ subtext }}
        </span>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.pulse-animation {
  animation: pulse 1.5s infinite;
}

.call-ringing {
  animation: border-pulse 1.5s infinite;
}

@keyframes pulse {
  0% {
    box-shadow: 0 0 0 0 rgba(34, 197, 94, 0.4);
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
    border-color: rgba(34, 197, 94, 0.8);
  }
  50% {
    border-color: rgba(34, 197, 94, 0.2);
  }
  100% {
    border-color: rgba(34, 197, 94, 0.8);
  }
}
</style>
