<script>
import { computed, ref, watch, onMounted, onBeforeUnmount } from 'vue';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import VoiceAPI from 'dashboard/api/channels/voice';

export default {
  name: 'FloatingCallWidget',
  props: {
    callSid: {
      type: String,
      default: '',
    },
    inboxName: {
      type: String,
      default: 'Primary',
    },
    conversationId: {
      type: [Number, String],
      default: null,
    },
  },
  emits: ['call-ended'],
  setup(props, { emit }) {
    const store = useStore();
    const { t } = useI18n();
    const callDuration = ref(0);
    const durationTimer = ref(null);
    const isCallActive = ref(!!props.callSid);
    const isMuted = ref(false);
    const showCallOptions = ref(false);
    const isFullscreen = ref(false);

    // Define local fallback translations in case i18n fails
    const translations = {
      'CONVERSATION.END_CALL': 'End call',
      'CONVERSATION.CALL_ENDED': 'Call ended',
      'CONVERSATION.CALL_END_ERROR': 'Failed to end call',
    };

    const formattedCallDuration = computed(() => {
      const minutes = Math.floor(callDuration.value / 60);
      const seconds = callDuration.value % 60;
      return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    });

    const startDurationTimer = () => {
      console.log('Starting duration timer');
      if (durationTimer.value) clearInterval(durationTimer.value);

      durationTimer.value = setInterval(() => {
        callDuration.value += 1;
      }, 1000);
    };

    const stopDurationTimer = () => {
      if (durationTimer.value) {
        clearInterval(durationTimer.value);
        durationTimer.value = null;
      }
    };

    // Emergency force end call function - simpler and more direct
    const forceEndCall = () => {
      console.log('FORCE END CALL triggered from floating widget');

      // Try all methods to ensure call ends

      // 1. Local component state
      stopDurationTimer();
      isCallActive.value = false;

      // Save the call data before potential reset
      const savedCallSid = props.callSid;
      const savedConversationId = props.conversationId;

      // 2. First, make direct API call if we have a valid call SID and conversation ID
      if (savedConversationId && savedCallSid && savedCallSid !== 'pending') {
        // Check if it's a valid Twilio call SID (starts with CA or TJ)
        const isValidTwilioSid =
          savedCallSid.startsWith('CA') || savedCallSid.startsWith('TJ');

        if (isValidTwilioSid) {
          console.log(
            'FloatingCallWidget: Making direct API call to end Twilio call with SID:',
            savedCallSid,
            'for conversation:',
            savedConversationId
          );

          // Use the direct API call without using global method
          VoiceAPI.endCall(savedCallSid, savedConversationId)
            .then(response => {
              console.log(
                'FloatingCallWidget: Call ended successfully via API:',
                response
              );
            })
            .catch(error => {
              console.error(
                'FloatingCallWidget: Error ending call via API:',
                error
              );
            });
        } else {
          console.log(
            'FloatingCallWidget: Invalid Twilio call SID format:',
            savedCallSid
          );
        }
      } else if (savedCallSid === 'pending') {
        console.log(
          'FloatingCallWidget: Call was still in pending state, no API call needed'
        );
      } else if (!savedConversationId) {
        console.log(
          'FloatingCallWidget: No conversation ID available for ending call'
        );
      } else {
        console.log('FloatingCallWidget: Missing required data for API call');
      }

      // 3. Also use global method to update UI states
      if (window.forceEndCall) {
        console.log('Using global forceEndCall method');
        window.forceEndCall();
      }

      // Fallbacks if global method not available

      // 4. Force App state update directly
      if (window.app) {
        console.log('Forcing app state update');
        window.app.$data.showCallWidget = false;
      }

      // 5. Emit event
      emit('call-ended');

      // 6. Update store - using store from setup scope
      store.dispatch('calls/clearActiveCall');

      // 7. User feedback
      useAlert({ message: 'Call ended', type: 'success' });
    };

    // Original more careful implementation
    const endCall = async () => {
      console.log('Attempting to end call with SID:', props.callSid);

      // First, always hide the UI for immediate feedback
      stopDurationTimer();
      isCallActive.value = false;

      // Force update the app's state
      if (typeof window !== 'undefined' && window.app && window.app.$data) {
        window.app.$data.showCallWidget = false;
      }

      // Emit the event to parent components
      emit('call-ended');

      // Show success message to user
      useAlert({ message: 'Call ended', type: 'success' });

      // Now try the API call (after UI is updated)
      try {
        // Skip actual API call if it's a test or temp call SID
        if (
          props.callSid &&
          !props.callSid.startsWith('test-') &&
          !props.callSid.startsWith('temp-') &&
          !props.callSid.startsWith('debug-')
        ) {
          console.log('Ending real call with SID:', props.callSid);
          await VoiceAPI.endCall(props.callSid);
        } else {
          console.log('Using fake/temp call SID, skipping API call');
        }
      } catch (error) {
        console.error('Error in API call to end call:', error);
        // Don't show error to user since UI is already updated
      }

      // Clear from store as last step
      const store = useStore();
      store.dispatch('calls/clearActiveCall');
    };

    const toggleMute = () => {
      // This would typically connect to Twilio's mute functionality
      // For now we'll just toggle the state
      isMuted.value = !isMuted.value;
      useAlert({
        message: isMuted.value ? 'Call muted' : 'Call unmuted',
        type: 'info',
      });

      // In a real implementation, you'd call Twilio's API to mute the call
      // Example: window.twilioDevice.activeConnection().mute(isMuted.value);
    };

    const toggleCallOptions = () => {
      showCallOptions.value = !showCallOptions.value;
    };

    const toggleFullscreen = () => {
      isFullscreen.value = !isFullscreen.value;
      // Would typically adjust UI accordingly
    };

    // Explicit debug handler for end call click
    const handleEndCallClick = () => {
      console.log('END CALL BUTTON CLICKED in FloatingCallWidget');
      console.log(
        'Current call SID:',
        props.callSid,
        'Conversation ID:',
        props.conversationId
      );

      // Save the call data before UI updates
      const savedCallSid = props.callSid;
      const savedConversationId = props.conversationId;

      // Always update UI immediately for better user experience
      stopDurationTimer();
      isCallActive.value = false;

      // Update app state
      if (window.app) {
        window.app.$data.showCallWidget = false;
      }

      // Update store
      store.dispatch('calls/clearActiveCall');

      // Emit event
      emit('call-ended');

      // Make API call if we have a valid conversation ID and a real call SID (not pending)
      if (savedConversationId && savedCallSid && savedCallSid !== 'pending') {
        // Check if it's a valid Twilio call SID (starts with CA or TJ)
        const isValidTwilioSid =
          savedCallSid.startsWith('CA') || savedCallSid.startsWith('TJ');

        if (isValidTwilioSid) {
          console.log(
            'handleEndCallClick: Making API call to end Twilio call with SID:',
            savedCallSid,
            'for conversation:',
            savedConversationId
          );

          // Make the API call after UI is updated
          VoiceAPI.endCall(savedCallSid, savedConversationId)
            .then(response => {
              console.log(
                'handleEndCallClick: Call ended successfully via API:',
                response
              );
              useAlert({ message: 'Call ended', type: 'success' });
            })
            .catch(error => {
              console.error(
                'handleEndCallClick: Error ending call via API:',
                error
              );
              useAlert({
                message: 'Call ended (but server may still show as active)',
                type: 'warning',
              });
            });
        } else {
          console.log(
            'handleEndCallClick: Invalid Twilio call SID format:',
            savedCallSid
          );
          useAlert({ message: 'Call ended', type: 'success' });
        }
      } else {
        if (savedCallSid === 'pending') {
          console.log(
            'handleEndCallClick: Call was still in pending state, no API call needed'
          );
        } else if (!savedConversationId) {
          console.log(
            'handleEndCallClick: No conversation ID available for ending call'
          );
        } else {
          console.log('handleEndCallClick: Missing required data for API call');
        }

        useAlert({ message: 'Call ended', type: 'success' });
      }
    };

    // Safe translation helper with fallback
    const safeTranslate = key => {
      try {
        return t(key);
      } catch (error) {
        return translations[key] || key;
      }
    };

    onMounted(() => {
      console.log('FloatingCallWidget mounted with callSid:', props.callSid);
      // Always start the timer, regardless of callSid
      startDurationTimer();
    });

    onBeforeUnmount(() => {
      stopDurationTimer();
    });

    // Watch for call SID changes
    watch(
      () => props.callSid,
      newCallSid => {
        isCallActive.value = !!newCallSid;

        if (newCallSid) {
          startDurationTimer();
        } else {
          stopDurationTimer();
        }
      }
    );

    return {
      isCallActive,
      callDuration,
      formattedCallDuration,
      isMuted,
      showCallOptions,
      isFullscreen,
      endCall,
      forceEndCall,
      handleEndCallClick,
      toggleMute,
      toggleCallOptions,
      toggleFullscreen,
      safeTranslate,
    };
  },
};
</script>

<template>
  <div class="floating-call-widget">
    <div class="call-info">
      <span class="inbox-name">{{ inboxName }}</span>
      <span class="call-duration">{{ formattedCallDuration }}</span>
    </div>

    <div class="call-controls">
      <button
        class="control-button mute-button"
        :class="{ active: isMuted }"
        :disabled="callSid === 'pending'"
        @click="toggleMute"
      >
        <span :class="isMuted ? 'i-ph-microphone-slash' : 'i-ph-microphone'" />
      </button>

      <button
        class="control-button end-call-button"
        title="End Call"
        @click.prevent.stop="handleEndCallClick"
      >
        <span class="i-ph-phone-x" />
      </button>

      <div v-if="callSid === 'pending'" class="status-indicator">
        Connecting...
      </div>

      <button
        v-else
        class="control-button settings-button"
        @click="toggleCallOptions"
      >
        <span class="i-ph-dots-three" />
      </button>
    </div>

    <div v-if="showCallOptions" class="call-options">
      <button @click="toggleFullscreen">
        {{ isFullscreen ? 'Minimize Call' : 'Expand Call' }}
      </button>
      <!-- Add more call options as needed -->
    </div>
  </div>
</template>

<style lang="scss" scoped>
.floating-call-widget {
  position: fixed;
  bottom: 20px;
  right: 20px;
  background-color: #1f2937;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  padding: 12px 16px;
  z-index: 10000;
  display: flex;
  flex-direction: column;
  min-width: 220px;
  color: white;

  .call-info {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 10px;

    .inbox-name {
      font-weight: 500;
    }

    .call-duration {
      font-variant-numeric: tabular-nums;
    }
  }

  .call-controls {
    display: flex;
    justify-content: space-around;
    gap: 8px;

    .control-button {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 40px;
      height: 40px;
      border-radius: 50%;
      border: none;
      cursor: pointer;
      background: #374151;
      color: white;
      font-size: 18px;

      &:hover {
        background: #4b5563;
      }

      &.active {
        background: #2563eb;
      }

      &.end-call-button {
        background: #dc2626;

        &:hover {
          background: #b91c1c;
        }
      }

      &:disabled {
        opacity: 0.5;
        cursor: not-allowed;

        &:hover {
          background: #374151;
        }
      }
    }

    .status-indicator {
      display: flex;
      align-items: center;
      justify-content: center;
      min-width: 40px;
      height: 40px;
      font-size: 12px;
      font-weight: 500;
      background: #2563eb;
      border-radius: 16px;
      padding: 0 12px;
      color: white;
      animation: pulse 1.5s infinite;
    }

    @keyframes pulse {
      0% {
        opacity: 0.6;
      }
      50% {
        opacity: 1;
      }
      100% {
        opacity: 0.6;
      }
    }
  }

  .call-options {
    margin-top: 8px;
    padding-top: 8px;
    border-top: 1px solid rgba(255, 255, 255, 0.1);

    button {
      display: block;
      width: 100%;
      text-align: left;
      padding: 6px 0;
      background: transparent;
      border: none;
      color: white;
      cursor: pointer;

      &:hover {
        color: #e5e7eb;
      }
    }
  }
}
</style>
