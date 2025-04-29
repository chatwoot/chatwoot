<script>
import { computed, ref, watch, onMounted, onBeforeUnmount } from 'vue';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import VoiceAPI from 'dashboard/api/channels/voice';
import ContactAPI from 'dashboard/api/contacts';

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
    contactName: {
      type: String,
      default: '',
    },
    contactId: {
      type: [Number, String],
      default: null,
    },
  },
  emits: ['callEnded', 'callJoined', 'callRejected'],
  setup(props, { emit }) {
    const store = useStore();
    const { t } = useI18n();
    const callDuration = ref(0);
    const durationTimer = ref(null);
    const isCallActive = ref(!!props.callSid);
    const isMuted = ref(false);
    const showCallOptions = ref(false);
    const isFullscreen = ref(false);
    const ringtoneAudio = ref(null);
    const displayContactName = ref(props.contactName || 'Loading...');

    // Define local fallback translations in case i18n fails
    const translations = {
      'CONVERSATION.END_CALL': 'End call',
      'CONVERSATION.JOIN_CALL': 'Join call',
      'CONVERSATION.REJECT_CALL': 'Reject',
      'CONVERSATION.CALL_ENDED': 'Call ended',
      'CONVERSATION.CALL_END_ERROR': 'Failed to end call',
      'CONVERSATION.CALL_ACCEPTED': 'Joining call...',
      'CONVERSATION.CALL_REJECTED': 'Call rejected',
      'CONVERSATION.CALL_JOIN_ERROR': 'Failed to join call',
      'CONVERSATION.INCOMING_CALL': 'Incoming call',
    };

    // Computed properties
    const activeCall = computed(() => store.getters['calls/getActiveCall']);
    const incomingCall = computed(() => store.getters['calls/getIncomingCall']);
    const hasIncomingCall = computed(() => store.getters['calls/hasIncomingCall']);
    const hasActiveCall = computed(() => store.getters['calls/hasActiveCall']);
    
    const isIncoming = computed(() => {
      return hasIncomingCall.value && !hasActiveCall.value;
    });
    
    const callInfo = computed(() => {
      return isIncoming.value ? incomingCall.value : activeCall.value;
    });
    
    const isJoined = computed(() => {
      return activeCall.value && activeCall.value.isJoined;
    });

    const formattedCallDuration = computed(() => {
      const minutes = Math.floor(callDuration.value / 60);
      const seconds = callDuration.value % 60;
      return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    });

    // Methods
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

    const playRingtone = () => {
      if (!ringtoneAudio.value) {
        // Fixed path to an existing audio file
        ringtoneAudio.value = new Audio('/audio/dashboard/call-ring.mp3');
        ringtoneAudio.value.loop = true;
        
        // Preload the audio to reduce delay
        ringtoneAudio.value.preload = 'auto';
        
        // Make sure volume is set appropriately
        ringtoneAudio.value.volume = 0.7;
        
        // Log confirmation
        console.log('Ringtone audio initialized with path: /audio/dashboard/call-ring.mp3');
      }
      
      // Force play with user interaction if needed
      const playPromise = ringtoneAudio.value.play();
      
      if (playPromise !== undefined) {
        playPromise.catch(error => {
          console.error('Failed to play ringtone:', error);
          
          // If autoplay was prevented, try again on next user interaction
          document.addEventListener('click', () => {
            ringtoneAudio.value.play().catch(() => {});
          }, { once: true });
        });
      }
    };

    const stopRingtone = () => {
      if (ringtoneAudio.value) {
        ringtoneAudio.value.pause();
        ringtoneAudio.value.currentTime = 0;
      }
    };

    // Emergency force end call function - simpler and more direct
    const forceEndCall = () => {
      console.log('FORCE END CALL triggered from floating widget');

      // Try all methods to ensure call ends
      stopDurationTimer();
      stopRingtone();
      isCallActive.value = false;

      // Save the call data before potential reset
      const savedCallSid = props.callSid;
      const savedConversationId = props.conversationId;

      // First, make direct API call if we have a valid call SID and conversation ID
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

      // Also use global method to update UI states
      if (window.forceEndCall) {
        console.log('Using global forceEndCall method');
        window.forceEndCall();
      }

      // Force App state update directly
      if (window.app) {
        console.log('Forcing app state update');
        window.app.$data.showCallWidget = false;
      }

      // Emit event
      emit('callEnded');

      // Update store - using store from setup scope
      store.dispatch('calls/clearActiveCall');
      store.dispatch('calls/clearIncomingCall');

      // User feedback
      useAlert({ message: 'Call ended', type: 'success' });
    };

    // End active call
    const endCall = async () => {
      console.log('Attempting to end call with SID:', props.callSid);

      // First, always hide the UI for immediate feedback
      stopDurationTimer();
      stopRingtone();
      isCallActive.value = false;

      // Force update the app's state to hide widget
      if (typeof window !== 'undefined' && window.app && window.app.$data) {
        window.app.$data.showCallWidget = false;
      }

      // Emit the event to parent components
      emit('callEnded');

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
          await VoiceAPI.endCall(props.callSid, props.conversationId);
        } else {
          console.log('Using fake/temp call SID, skipping API call');
        }
      } catch (error) {
        console.error('Error in API call to end call:', error);
        // Don't show error to user since UI is already updated
      }

      // Clear from store as last step
      store.dispatch('calls/clearActiveCall');
      store.dispatch('calls/clearIncomingCall');
      
      // Set global call status in all possible places to ensure widget is removed
      if (window.globalCallStatus) {
        window.globalCallStatus.active = false;
        window.globalCallStatus.incoming = false;
      }
      
      // Add a timeout to ensure UI is properly reset if there are async issues
      setTimeout(() => {
        if (window.app && window.app.$data) {
          window.app.$data.showCallWidget = false;
        }
        store.dispatch('calls/clearActiveCall');
        store.dispatch('calls/clearIncomingCall');
      }, 300);
    };

    // Accept incoming call
    const acceptCall = async () => {
      console.log('Accepting incoming call with SID:', incomingCall.value?.callSid);
      
      stopRingtone();
      
      try {
        // Call the API to join the call (conference) as an agent
        if (incomingCall.value) {
          const { callSid, conversationId } = incomingCall.value;
          
          // Show user feedback
          useAlert({ message: safeTranslate('CONVERSATION.CALL_ACCEPTED'), type: 'info' });
          
          // Make API call to join the conference
          await VoiceAPI.joinCall(callSid, conversationId);
          
          // Move incoming call to active call
          store.dispatch('calls/acceptIncomingCall');
          
          // Start call duration timer
          startDurationTimer();
          
          // Emit event
          emit('callJoined');
        }
      } catch (error) {
        console.error('Error joining call:', error);
        useAlert({ message: safeTranslate('CONVERSATION.CALL_JOIN_ERROR'), type: 'error' });
        forceEndCall();
      }
    };

    // Reject incoming call
    const rejectCall = async () => {
      console.log('Rejecting incoming call with SID:', incomingCall.value?.callSid);
      
      stopRingtone();
      
      try {
        if (incomingCall.value) {
          const { callSid, conversationId } = incomingCall.value;
          
          // Show user feedback
          useAlert({ message: safeTranslate('CONVERSATION.CALL_REJECTED'), type: 'info' });
          
          // Make API call to reject the call (optional, the caller will stay in the queue)
          await VoiceAPI.rejectCall(callSid, conversationId);
          
          // Clear the incoming call from store
          store.dispatch('calls/clearIncomingCall');
          
          // Emit event
          emit('callRejected');
          
          // Update app state - checking for $data property
          if (window.app && window.app.$data) {
            window.app.$data.showCallWidget = false;
          }
        }
      } catch (error) {
        console.error('Error rejecting call:', error);
        // Clear anyway for UX purposes
        store.dispatch('calls/clearIncomingCall');
        
        // Update app state
        if (window.app) {
          window.app.$data.showCallWidget = false;
        }
      }
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
    const handleEndCallClick = async () => {
      // Save the call data before UI updates
      const callData = isIncoming.value ? incomingCall.value : activeCall.value;
      
      if (!callData) {
        console.log('No call data found');
        return;
      }
      
      const savedCallSid = callData.callSid;
      const savedConversationId = callData.conversationId;

      // Always update UI immediately for better user experience
      stopDurationTimer();
      stopRingtone();
      isCallActive.value = false;

      // Update app state - checking for $data property
      if (window.app && window.app.$data) {
        window.app.$data.showCallWidget = false;
      }

      // Update store
      store.dispatch('calls/clearActiveCall');
      store.dispatch('calls/clearIncomingCall');

      // Emit event
      emit('callEnded');

      // Make API call if we have a valid conversation ID and a real call SID (not pending)
      if (savedConversationId && savedCallSid && savedCallSid !== 'pending') {
        // Check if it's a valid Twilio call SID (starts with CA or TJ)
        const isValidTwilioSid =
          savedCallSid.startsWith('CA') || savedCallSid.startsWith('TJ');

        if (isValidTwilioSid) {
          try {
            await VoiceAPI.endCall(savedCallSid, savedConversationId);
            useAlert({ message: 'Call ended', type: 'success' });
          } catch (error) {
            console.error('Error ending call:', error);
            useAlert({
              message: 'Call ended (but server may still show as active)',
              type: 'warning',
            });
          }
        } else {
          useAlert({ message: 'Call ended', type: 'success' });
        }
      } else {
        useAlert({ message: 'Call ended', type: 'success' });
      }
      
      // Set global call status in all possible places to ensure widget is removed
      if (window.globalCallStatus) {
        window.globalCallStatus.active = false;
        window.globalCallStatus.incoming = false;
      }
      
      // Add a timeout to ensure UI is properly reset if there are async issues
      setTimeout(() => {
        if (window.app && window.app.$data) {
          window.app.$data.showCallWidget = false;
        }
        store.dispatch('calls/clearActiveCall');
        store.dispatch('calls/clearIncomingCall');
      }, 300);
    };

    // Safe translation helper with fallback
    const safeTranslate = key => {
      try {
        return t(key);
      } catch (error) {
        return translations[key] || key;
      }
    };
    
    // Function to fetch contact details if needed
    const fetchContactDetails = async () => {
      // If we already have a contact name, don't fetch
      if (displayContactName.value !== 'Loading...' && displayContactName.value !== 'Unknown Caller') {
        return;
      }
      
      // If we have a contact ID, fetch the details
      const contactId = props.contactId || callInfo.value?.contactId;
      if (contactId) {
        try {
          console.log('Fetching contact details for ID:', contactId);
          const response = await ContactAPI.show(contactId);
          if (response.data && response.data.payload) {
            const contact = response.data.payload;
            displayContactName.value = contact.name || 'Unknown Caller';
            console.log('Contact details fetched:', contact.name);
          }
        } catch (error) {
          console.error('Error fetching contact details:', error);
          displayContactName.value = 'Unknown Caller';
        }
      } else {
        displayContactName.value = 'Unknown Caller';
      }
    };

    onMounted(() => {
      // If this is an active call, start timer
      if (hasActiveCall.value) {
        startDurationTimer();
      }
      
      // If this is an incoming call, play ringtone
      if (isIncoming.value) {
        // Slight delay to ensure DOM is fully rendered
        setTimeout(() => {
          playRingtone();
        }, 300);
      }
      
      // Fetch contact details if needed (after slight delay to ensure callInfo is populated)
      setTimeout(() => {
        fetchContactDetails();
      }, 500);
    });

    onBeforeUnmount(() => {
      stopDurationTimer();
      stopRingtone();
    });

    // Watch for call store changes
    watch(
      () => isIncoming.value,
      newIsIncoming => {
        if (newIsIncoming) {
          // Immediate UI feedback with delay for audio to allow browser autoplay policies
          stopDurationTimer();
          setTimeout(() => {
            playRingtone();
          }, 300);
        } else {
          stopRingtone();
        }
      },
      { immediate: true } // Check immediately on component creation
    );
    
    watch(
      () => isJoined.value,
      newIsJoined => {
        if (newIsJoined) {
          stopRingtone();
          startDurationTimer();
        }
      }
    );
    
    // Watch for call info changes to fetch contact details if needed
    watch(
      () => callInfo.value,
      (newCallInfo) => {
        if (newCallInfo && newCallInfo.contactId) {
          // Try to fetch contact details when call info changes
          fetchContactDetails();
        }
      },
      { immediate: true }
    );

    return {
      isCallActive,
      callDuration,
      formattedCallDuration,
      isMuted,
      showCallOptions,
      isFullscreen,
      isIncoming,
      isJoined,
      activeCall,
      incomingCall,
      callInfo,
      displayContactName,
      endCall,
      forceEndCall,
      acceptCall,
      rejectCall,
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
  <div
    class="floating-call-widget"
    :class="{
      'is-minimized': !showCallOptions,
      'is-fullscreen': isFullscreen,
      'is-incoming': isIncoming,
    }"
  >
    <div class="call-header">
      <div class="flex items-center justify-between w-full">
        <div class="flex items-center gap-2">
          <div class="call-icon-wrapper">
            <span v-if="isIncoming" class="i-ph-phone-call text-xl" />
            <span v-else class="i-ph-phone text-xl" />
          </div>
          <div class="flex flex-col">
            <h3 class="call-title">
              {{ displayContactName }}
            </h3>
            <div class="call-subtitle">
              {{ isIncoming ? $t('CONVERSATION.INCOMING_CALL') : (callInfo.inboxName || 'Voice Call') }}
            </div>
          </div>
        </div>
        <div class="call-duration" v-if="!isIncoming">
          {{ formattedCallDuration }}
        </div>
      </div>
    </div>

    <div class="call-actions">
      <button
        v-if="isIncoming"
        class="control-button accept-call-button"
        @click="acceptCall"
        :title="$t('CONVERSATION.JOIN_CALL')"
      >
        <span class="i-ph-phone" />
        <span class="button-text">{{ $t('CONVERSATION.JOIN_CALL') }}</span>
      </button>

      <button
        v-if="isIncoming"
        class="control-button reject-call-button"
        @click="rejectCall"
        :title="$t('CONVERSATION.REJECT_CALL')"
      >
        <span class="i-ph-phone-x" />
        <span class="button-text">{{ $t('CONVERSATION.REJECT_CALL') }}</span>
      </button>

      <button
        v-if="!isIncoming"
        class="control-button end-call-button"
        @click="handleEndCallClick"
        :title="$t('CONVERSATION.END_CALL')"
      >
        <span class="i-ph-phone-x" />
      </button>

      <button
        v-if="!isIncoming"
        class="control-button mute-button"
        :class="{ active: isMuted }"
        @click="toggleMute"
        :title="isMuted ? 'Unmute' : 'Mute'"
      >
        <span :class="isMuted ? 'i-ph-microphone-slash' : 'i-ph-microphone'" />
      </button>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.floating-call-widget {
  position: fixed;
  bottom: 20px;
  right: 20px;
  background-color: rgba(31, 41, 55, 0.95); /* var(--b-700, #1f2937) with opacity */
  backdrop-filter: blur(4px);
  border-radius: 12px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.2);
  padding: 16px;
  z-index: 10000;
  display: flex;
  flex-direction: column;
  width: 320px;
  color: white;
  transition: all 0.3s ease;
  border: 1px solid var(--b-600, #374151);

  &.is-minimized {
    min-width: auto;
    padding: 12px;
  }

  &.is-fullscreen {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    width: 100%;
    height: 100%;
    border-radius: 0;
  }

  &.is-incoming {
    animation: pulse 1.5s infinite;
    border-color: var(--b-600, #374151);
    background-color: rgba(31, 41, 55, 0.95); /* Same background, no red */
  }
}

.call-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
  padding: 0 0 8px 0;
}

.call-icon-wrapper {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background-color: var(--b-500, #4b5563);
  color: white;
}

.call-title {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 180px;
  line-height: 1.2;
}

.call-subtitle {
  font-size: 12px;
  color: var(--s-200, #9ca3af);
  margin-top: 2px;
}

.call-duration {
  font-size: 14px;
  font-weight: 500;
  color: var(--s-100, #f3f4f6);
  background-color: var(--b-600, #374151);
  padding: 4px 8px;
  border-radius: 12px;
}

.call-actions {
  display: flex;
  gap: 12px;
  justify-content: center;

  .control-button {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 44px;
    height: 44px;
    border-radius: 50%;
    border: none;
    cursor: pointer;
    background: var(--b-600, #374151);
    color: white;
    font-size: 18px;
    transition: all 0.2s ease;
    box-shadow: 0 2px 6px rgba(0, 0, 0, 0.1);

    &:hover {
      background: var(--b-500, #4b5563);
      transform: translateY(-2px);
    }

    &:active {
      transform: translateY(0);
    }

    &.active {
      background: var(--w-500, #2563eb);
    }

    &.end-call-button {
      background: var(--r-500, #dc2626);

      &:hover {
        background: var(--r-600, #b91c1c);
      }
    }

    &.accept-call-button,
    &.reject-call-button {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      flex: 1;
      height: 44px;
      border-radius: 22px;
      border: none;
      cursor: pointer;
      font-weight: 600;
      font-size: 14px;
      box-shadow: 0 3px 10px rgba(0, 0, 0, 0.2);
    }

    &.accept-call-button {
      background: var(--g-500, #10b981);
      color: white;

      &:hover {
        background: var(--g-600, #059669);
        transform: translateY(-2px);
      }
      
      &:active {
        transform: translateY(0);
      }
    }

    &.reject-call-button {
      background: var(--r-500, #dc2626);
      color: white;

      &:hover {
        background: var(--r-600, #b91c1c);
        transform: translateY(-2px);
      }
      
      &:active {
        transform: translateY(0);
      }
    }

    .button-text {
      margin-left: 8px;
    }
  }
}

@keyframes pulse {
  0% {
    box-shadow: 0 0 0 0 rgba(220, 38, 38, 0.4);
    transform: scale(1);
  }
  50% {
    box-shadow: 0 0 0 10px rgba(220, 38, 38, 0);
    transform: scale(1.01);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(220, 38, 38, 0);
    transform: scale(1);
  }
}
</style>
