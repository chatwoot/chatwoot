<script>
import { computed, ref, watch, onMounted, onBeforeUnmount } from 'vue';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import VoiceAPI from 'dashboard/api/channels/voice';
import ContactAPI from 'dashboard/api/contacts';
import DashboardAudioNotificationHelper from 'dashboard/helper/AudioAlerts/DashboardAudioNotificationHelper';

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
    inboxId: {
      type: [Number, String],
      default: null,
    },
    // Always use WebRTC by default - the useWebRTC prop is kept for compatibility
    // but hardcoded to true since agents will only ever use WebRTC now
    useWebRTC: {
      type: Boolean,
      default: true, // Always true - no longer optional
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
    const isWebRTCInitialized = ref(false);
    const isWebRTCSupported = ref(true);
    const twilioDeviceStatus = ref('not_initialized');
    const microphonePermission = ref('not_requested'); // 'not_requested', 'granted', 'denied'
    const currentVolume = ref(0.7); // 0-1 scale

    // Define local fallback translations in case i18n fails
    const translations = {
      'CONVERSATION.VOICE_CALL.END_CALL': 'End call',
      'CONVERSATION.VOICE_CALL.JOIN_CALL': 'Join call',
      'CONVERSATION.VOICE_CALL.REJECT_CALL': 'Reject',
      'CONVERSATION.VOICE_CALL.CALL_ENDED': 'Call ended',
      'CONVERSATION.VOICE_CALL.CALL_END_ERROR': 'Failed to end call',
      'CONVERSATION.VOICE_CALL.CALL_ACCEPTED': 'Joining call...',
      'CONVERSATION.VOICE_CALL.CALL_REJECTED': 'Call rejected',
      'CONVERSATION.VOICE_CALL.CALL_JOIN_ERROR': 'Failed to join call',
      'CONVERSATION.VOICE_CALL.INCOMING_CALL': 'Incoming call',
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
      console.log('Attempting to stop ringtone');
      if (ringtoneAudio.value) {
        try {
          ringtoneAudio.value.pause();
          ringtoneAudio.value.currentTime = 0;
          console.log('Ringtone stopped successfully');
          
          // Also use the DashboardAudioNotificationHelper to ensure all audio stops
          if (window.DashboardAudioNotificationHelper || 
              (typeof DashboardAudioNotificationHelper !== 'undefined')) {
            try {
              DashboardAudioNotificationHelper.stopAudio('call_ring');
              console.log('🔇 Also stopped ringtone using DashboardAudioNotificationHelper');
            } catch (dashboardError) {
              console.warn('Could not stop audio via DashboardAudioNotificationHelper:', dashboardError);
            }
          }
        } catch (error) {
          console.error('Error stopping ringtone:', error);
        }
      } else {
        console.log('No ringtone audio element to stop');
        
        // Still try to stop any global audio
        if (window.DashboardAudioNotificationHelper || 
            (typeof DashboardAudioNotificationHelper !== 'undefined')) {
          try {
            DashboardAudioNotificationHelper.stopAudio('call_ring');
            console.log('🔇 Stopped ringtone using DashboardAudioNotificationHelper only');
          } catch (dashboardError) {
            console.warn('Could not stop audio via DashboardAudioNotificationHelper:', dashboardError);
          }
        }
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
      useAlert('Call ended');
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
      useAlert('Call ended');

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

    // Accept incoming call and redirect to conversation
    const acceptCall = async () => {
      console.log('Accepting incoming call with SID:', incomingCall.value?.callSid);
      
      // Check if this is an outbound call by looking for isOutbound flag
      const isOutboundCall = incomingCall.value && incomingCall.value.isOutbound === true;
      
      // Make sure to stop the ringtone - force multiple attempts for reliability
      stopRingtone();
      // Try again after a short delay to ensure it stops
      setTimeout(() => {
        stopRingtone();
      }, 100);
      
      try {
        // Call the API to join the call (conference) as an agent
        if (incomingCall.value) {
          const { callSid, conversationId } = incomingCall.value;
          
          // Show user feedback immediately
          useAlert('Joining call...');
          
          let joinSuccess = false;
          
          // WebRTC is now the only option for agents
          console.log('Attempting to join call with WebRTC (only option for agents)');
          try {
            const webRTCSuccess = await joinCallWithWebRTC();
            if (webRTCSuccess) {
              console.log('Successfully joined call with WebRTC');
              joinSuccess = true;
            } else {
              console.log('WebRTC join failed - agent must use browser interface');
              useAlert('Browser-based call connection failed. Please check your microphone permissions and try again.');
            }
          } catch (webrtcError) {
            console.error('WebRTC join error - agent must use browser for calls:', webrtcError);
            useAlert('Browser-based call connection failed. Please check your microphone permissions and try again.');
          }
          
          // If WebRTC failed, we cannot proceed - no phone fallback
          if (!joinSuccess) {
            console.log('WebRTC join failed - agents must use web interface only');
            throw new Error('WebRTC connection failed - agents must use the web interface');
          }
          
          if (joinSuccess) {
            // Force stop the ringtone again to be certain
            stopRingtone();
            
            // Start call duration timer
            startDurationTimer();
            
            // Move incoming call to active call
            store.dispatch('calls/acceptIncomingCall');
            
            // Emit event
            emit('callJoined');
            
            // IMPORTANT: Redirect to the conversation view
            if (conversationId) {
              const accountId = this.$route.params.accountId;
              const path = frontendURL(
                conversationUrl({
                  accountId,
                  id: conversationId,
                })
              );
              console.log(`Redirecting to conversation path: ${path}`);
              this.$router.push({ path });
            }
          } else {
            throw new Error('Failed to join call via WebRTC or phone');
          }
        }
      } catch (error) {
        console.error('Error joining call:', error);
        useAlert('Failed to join call. Please try again.');
        // Don't force end call immediately, let the user try again
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
          useAlert(safeTranslate('CONVERSATION.VOICE_CALL.CALL_REJECTED'));
          
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
      // If WebRTC is initialized, use that for mute/unmute
      if (isWebRTCInitialized.value) {
        toggleMuteWebRTC();
        return;
      }
      
      // Otherwise just toggle the state for UI feedback
      isMuted.value = !isMuted.value;
      useAlert(isMuted.value ? 'Call muted' : 'Call unmuted');
    };

    const toggleCallOptions = () => {
      showCallOptions.value = !showCallOptions.value;
    };

    const toggleFullscreen = () => {
      isFullscreen.value = !isFullscreen.value;
      // Would typically adjust UI accordingly
    };
    
    // WebRTC and Twilio Voice SDK methods
    
    // Get inbox ID from all possible sources
    const getAvailableInboxId = () => {
      // Try all possible sources of inbox ID in order of most reliable first
      return props.inboxId || 
             props.conversation?.inbox_id ||
             callInfo.value?.inboxId || 
             activeCall.value?.inboxId || 
             incomingCall.value?.inboxId ||
             store.getters['calls/getActiveCall']?.inboxId ||
             store.getters['calls/getIncomingCall']?.inboxId ||
             // Last resort - try to find an inbox ID from the current conversation in the store
             (props.conversationId && store.getters['getConversation']?.(props.conversationId)?.inbox_id);
    };
    
    // Initialize the Twilio device
    const initializeTwilioDevice = async () => {
      // No need to initialize if already done
      if (isWebRTCInitialized.value) return true;
      
      try {
        // Try to find an inbox ID from any available source
        const inboxId = getAvailableInboxId();
        
        // Debug available IDs
        console.log('Available IDs:', {
          propsInboxId: props.inboxId,
          callInfoInboxId: callInfo.value?.inboxId,
          activeCallInboxId: activeCall.value?.inboxId,
          incomingCallInboxId: incomingCall.value?.inboxId,
          storeActiveCallInboxId: store.getters['calls/getActiveCall']?.inboxId,
          storeIncomingCallInboxId: store.getters['calls/getIncomingCall']?.inboxId,
          conversationInboxId: props.conversation?.inbox_id,
          resolvedInboxId: inboxId
        });
        
        if (!inboxId) {
          const errorMsg = 'No inbox ID available to initialize Twilio Device. Please try again with a voice-enabled inbox.';
          console.error(errorMsg);
          useAlert(errorMsg);
          return false;
        }
        
        // Check browser support for WebRTC
        if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
          isWebRTCSupported.value = false;
          const errorMsg = 'WebRTC is not supported in this browser. Try Chrome, Firefox, or Edge.';
          console.error(errorMsg);
          useAlert(errorMsg);
          return false;
        }
        
        // Step 1: Request microphone permission with specific audio constraints
        // These help establish a better audio connection
        try {
          console.log('Requesting microphone permission with optimized audio...');
          
          // Enhanced audio constraints to resolve audio connection issues
          const audioConstraints = {
            audio: {
              echoCancellation: { exact: true },  // Force echo cancellation
              noiseSuppression: { exact: true },  // Force noise suppression
              autoGainControl: { exact: true },   // Force auto gain control
              channelCount: { ideal: 1 },         // Mono is more reliable than stereo
              latency: { ideal: 0.01 },           // Lower latency for better real-time
              sampleRate: { ideal: 48000 },       // Higher sample rate for voice clarity
              sampleSize: { ideal: 16 },          // Standard bit depth
              volume: { ideal: 1.0 }              // Maximum volume
            }
          };
          
          const stream = await navigator.mediaDevices.getUserMedia(audioConstraints);
          
          // CRITICAL: Keep the stream active to maintain audio permissions
          window.activeAudioStream = stream;
          
          microphonePermission.value = 'granted';
          console.log('✅ Microphone permission granted with optimized audio settings');
          
          // Listen for track-ended events that might indicate audio issues
          stream.getAudioTracks().forEach(track => {
            console.log('Audio track active:', track.label, track.enabled);
            track.onended = () => {
              console.warn('⚠️ Audio track ended unexpectedly');
            };
          });
        } catch (micError) {
          // Fall back to default audio constraints if specific ones fail
          try {
            console.log('Falling back to default audio constraints...');
            const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
            window.activeAudioStream = stream;
            microphonePermission.value = 'granted';
            console.log('✅ Microphone permission granted with default settings');
          } catch (fallbackError) {
            microphonePermission.value = 'denied';
            const errorMsg = `Microphone access denied: ${fallbackError.message}. Please allow microphone access in your browser settings.`;
            console.error(errorMsg, fallbackError);
            useAlert(errorMsg);
            return false;
          }
        }
        
        // Step 2: Initialize Twilio Device
        try {
          console.log('Initializing Twilio Device with inbox ID:', inboxId);
          
          // Enhanced error handling during initialization
          try {
            await VoiceAPI.initializeDevice(inboxId);
          } catch (initError) {
            // Check for specific error cases
            if (initError.message && initError.message.includes('Server error')) {
              // If we have more details from the server error, show them
              if (initError.details) {
                console.error('Server error details:', initError.details);
                
                // Check for common error patterns
                if (initError.details.includes('uninitialized constant Twilio::JWT::AccessToken')) {
                  throw new Error('Twilio gem not properly installed. Please check server configuration.');
                } else if (initError.details.includes('undefined method') && initError.details.includes('for nil:NilClass')) {
                  throw new Error('Voice channel configuration is incomplete. Please check your inbox setup.');
                } else if (initError.details.includes('Missing Twilio credentials')) {
                  throw new Error('Missing Twilio credentials. Please configure account SID and auth token in channel settings.');
                }
              }
            }
            
            // If no special case was handled, re-throw the original error
            throw initError;
          }
          
          // Check if device was actually initialized
          if (!VoiceAPI.device) {
            throw new Error('Device initialization failed silently. Please check server logs.');
          }
          
          isWebRTCInitialized.value = true;
          twilioDeviceStatus.value = VoiceAPI.getDeviceStatus();
          
          // Success notification
          console.log('Twilio Device initialized successfully with status:', twilioDeviceStatus.value);
          useAlert('Voice call device initialized successfully');
          
          return true;
        } catch (deviceError) {
          console.error('Twilio Device initialization error:', deviceError);
          
          // Construct a helpful error message based on the error details
          let errorMsg = 'Failed to initialize voice client';
          
          // Check for specific error patterns
          if (deviceError.message && deviceError.message.includes('token')) {
            errorMsg = 'Failed to get Twilio token. Check your Twilio credentials in the Voice channel settings.';
          } else if (deviceError.message && deviceError.message.includes('TwiML')) {
            errorMsg = 'Twilio configuration issue: Missing or invalid TwiML App SID in Voice channel settings.';
          } else if (deviceError.message && deviceError.message.includes('Voice channel configuration')) {
            errorMsg = deviceError.message;
          } else if (deviceError.message && deviceError.message.includes('Server error')) {
            errorMsg = 'Server error while initializing voice client. Check your Twilio configuration.';
          } else if (deviceError.message) {
            errorMsg = `Voice client initialization failed: ${deviceError.message}`;
          }
          
          useAlert(errorMsg);
          return false;
        }
      } catch (error) {
        // Handle any uncaught errors
        console.error('Unexpected error during Twilio setup:', error);
        useAlert(`Unexpected error: ${error.message}. Please check console for details.`);
        return false;
      }
    };
    
    // Join a call using the Twilio Client - this is the only option for agents now
    const joinCallWithWebRTC = async () => {
      try {
        // CRITICAL: Before anything else, set up media streams properly
        // This is the most important step to ensure audio works
        await prepareAudioDevice();
        
        // 1. Make sure device is initialized first
        if (!isWebRTCInitialized.value) {
          console.log('Twilio device not initialized, attempting to initialize...');
          const initSuccess = await initializeTwilioDevice();
          if (!initSuccess) {
            console.error('Failed to initialize Twilio device');
            return false;
          }
        }
        
        // RESET the device if it's in a weird state
        if (VoiceAPI.getDeviceStatus() !== 'ready') {
          console.log('Twilio device not in ready state, resetting...');
          await VoiceAPI.endClientCall(); // End any existing calls
          await VoiceAPI.initializeDevice(getAvailableInboxId()); // Reinitialize
        }
        
        console.log('Twilio device ready to make calls with state:', VoiceAPI.getDeviceStatus());
        
        // 2. Get call details
        if (!incomingCall.value) {
          console.error('No incoming call data available');
          return false;
        }
        
        const { callSid, conversationId, accountId: callAccountId } = incomingCall.value;
        console.log('Joining conference with callSid:', callSid);
        
        // First inform the server that agent is joining via WebRTC (using the new API function signature)
        // Create a variable to store the server response
        let serverResponse = null;
        
        try {
          // Ensure we have a valid account ID to include with the API call
          let accountId = callAccountId || 
                        (window.Current && window.Current.account && window.Current.account.id) ||
                        (typeof Current !== 'undefined' && Current.account && Current.account.id);
          
          // Try to get from URL if not available elsewhere
          if (!accountId) {
            const urlMatch = window.location.pathname.match(/\/accounts\/(\d+)/);
            if (urlMatch && urlMatch[1]) {
              accountId = urlMatch[1];
            }
          }
          
          console.log('Found account ID for API call:', accountId);
          
          // Save the server response to our variable that will be accessible in the next block
          const response = await VoiceAPI.joinCall({
            call_sid: callSid,
            conversation_id: conversationId,
            account_id: accountId
          });
          
          console.log('API joinCall response details:', {
            hasData: !!response.data,
            statusCode: response.status,
            accountIdSent: accountId
          });
          
          serverResponse = response.data;
          console.log('Server response for join_call:', serverResponse);
        } catch (apiError) {
          console.error('Error calling join_call API:', apiError);
          // Continue anyway, as we might still be able to join the conference
        }
        
        // CRUCIAL: Try to fix audio issues proactively
        await fixAudioBeforeCall();
        
        // 3. Use absolutely minimal parameters for WebRTC connections
        try {
          // Use the server response to get the conference ID
          
          // Get account ID from URL if not set yet
          let accountId = callAccountId || 
                        (window.Current && window.Current.account && window.Current.account.id) ||
                        (typeof Current !== 'undefined' && Current.account && Current.account.id);

          // Try to get from URL if still not available
          if (!accountId) {
            const urlMatch = window.location.pathname.match(/\/accounts\/(\d+)/);
            if (urlMatch && urlMatch[1]) {
              accountId = urlMatch[1];
            }
          }

          // First check specifically for conference_sid in the incomingCall object
          // This is the most direct source for outbound calls
          let conferenceId = incomingCall.value?.conference_sid;
          
          // Log if we found a conference ID directly on the incomingCall
          if (conferenceId) {
            // Found conference_sid directly from incoming call
          }
          
          // If not found in incomingCall, try the server response
          if (!conferenceId) {
            conferenceId = serverResponse?.conference_sid;
          }
          
          // First try to get conference ID from server response if still not found
          if (!conferenceId && serverResponse) {
            // For outbound calls, the conference info might be in a different format
            // Try to find it from multiple possible locations
            conferenceId = serverResponse.conference_sid || 
                         serverResponse.conferenceId || 
                         serverResponse.conference_name;
            
            // Use alternative conference ID sources
          }
          
          // If still no conference ID, try to generate it from conversation details
          if (!conferenceId && incomingCall.value) {
            const accountId = incomingCall.value.accountId || 
                            (window.Current && window.Current.account && window.Current.account.id);
            const convId = incomingCall.value.conversationId;
            
            // Check if this is an outbound call
            const isOutboundCall = incomingCall.value && incomingCall.value.isOutbound === true;
            
            // First check if the conference_sid was passed directly in the incomingCall data
            if (isOutboundCall && incomingCall.value.conference_sid) {
              conferenceId = incomingCall.value.conference_sid;
            }
            
            // If we still don't have a conference ID, try to generate it
            if (!conferenceId && accountId && convId) {
              // Generate conference ID in the standard format
              conferenceId = `conf_account_${accountId}_conv_${convId}`;
              // Use standard conference ID format based on account and conversation IDs
            }
          }
          
          if (!conferenceId) {
            console.error('No conference_sid in server response:', serverResponse);
            return false;
          }
          
          // Validate conference ID
          
          // For simplicity, use the standard endpoint - we'll fix the parameter passing
          const twimlEndpoint = `${window.location.origin}/api/v1/accounts/${accountId}/voice/twiml_for_client`;
          
          // Log what we're doing with detailed info for debugging
          // Connect to conference
          
          // accountId is already defined above, no need to redefine it
          
          // IMPORTANT: Twilio expects parameters to be in the correct case
          // The parameter MUST be 'To' (capital T) for Twilio Voice SDK
          // This is a common source of issues - where parameters get lowercased
          const enhancedParams = {
            To: conferenceId,         // KEEP THIS CAPITALIZED - it's critical!
            account_id: accountId     // This should be lowercase
          };
          
          // Double check to ensure the parameter is correctly capitalized
          if (!('To' in enhancedParams)) {
            console.error('CRITICAL ERROR: The To parameter is not correctly capitalized!');
          }
          
          // Enhanced parameters for joining the call
          
          // Explicitly initialize the device again to ensure it's ready
          // This helps when there might be issues with the device state
          if (VoiceAPI.getDeviceStatus() !== 'ready') {
            console.log('Ensuring Twilio device is ready before connecting...');
            try {
              await VoiceAPI.initializeDevice(getAvailableInboxId());
              console.log('Device reinitialized successfully');
            } catch (initError) {
              console.error('Error reinitializing device:', initError);
              // Continue anyway - the device might still work
            }
          }
          
          // Make the WebRTC call to join conference
          
          // Get the connection object back so we can verify status
          const connection = VoiceAPI.joinClientCall(enhancedParams);
          
          // Log diagnostic info and verify connection
          if (connection) {
            console.log('Conference connection established', {
              connectionObject: !!connection,
              hasOnMethod: typeof connection.on === 'function',
              connectionState: connection.status ? connection.status() : 'No status method',
              deviceState: VoiceAPI.getDeviceStatus()
            });
            
            // Attach event handlers for audio troubleshooting
            try {
              if (typeof connection.on === 'function') {
                // When call is accepted
                connection.on('accept', () => {
                  console.log('✅ Agent call accepted, conference should start now');
                  
                  // IMPORTANT: Try to unmute explicitly to ensure audio path is open
                  try {
                    if (connection.mute) {
                      connection.mute(false);
                    }
                  } catch (e) {
                    console.warn('Error unmuting connection:', e);
                  }
                  
                  // Run the two-way audio check TWICE - once immediately and once after delay
                  verifyTwoWayAudio();
                  
                  setTimeout(() => {
                    verifyTwoWayAudio();
                    
                    // If still having issues, try to re-establish the audio path
                    try {
                      if (VoiceAPI.activeConnection) {
                        console.log('Trying to refresh audio path...');
                        // Toggle mute quickly to refresh audio path
                        VoiceAPI.activeConnection.mute(true);
                        setTimeout(() => VoiceAPI.activeConnection.mute(false), 100);
                      }
                    } catch (e) {
                      console.warn('Error toggling mute:', e);
                    }
                  }, 5000);
                });
                
                // Monitor for warnings
                connection.on('warning', (warning) => {
                  console.warn('⚠️ Connection warning:', warning);
                });
              } else {
                console.log('Connection object does not have .on() method - newer Twilio SDK version');
                // Still schedule the two-way audio check
                setTimeout(() => {
                  verifyTwoWayAudio();
                }, 5000);
              }
              
              // CRITICAL: Handle volume events to ensure audio path is open
              if (typeof connection.on === 'function' && typeof connection.volume === 'function') {
                connection.on('volume', (inputVolume, outputVolume) => {
                  console.log(`🔊 Volume change - Input: ${inputVolume}, Output: ${outputVolume}`);
                });
              }
            } catch (e) {
              console.warn('Error setting up connection event handlers:', e);
            }
          }
          
          console.log('WebRTC join call initiated successfully with minimal parameters');
          return true;
        } catch (connectionError) {
          console.error('Error in VoiceAPI.joinClientCall:', connectionError);
          return false;
        }
      } catch (error) {
        console.error('Unexpected error in joinCallWithWebRTC:', error);
        return false;
      }
    };
    
    // New function to set up audio device properly before call
    const prepareAudioDevice = async () => {
      try {
        console.log('🎙️ Preparing audio device for optimal performance...');
        
        // First, ensure we have microphone permission
        if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
          console.error('📛 WebRTC not supported in this browser');
          return false;
        }
        
        // 1. Create a clean audio context to reset any audio state
        try {
          const AudioContext = window.AudioContext || window.webkitAudioContext;
          if (AudioContext) {
            const audioCtx = new AudioContext();
            
            // Force audio context to start - critical for iOS
            if (audioCtx.state === 'suspended') {
              await audioCtx.resume();
            }
            
            console.log('🔊 Audio context created and started:', audioCtx.state);
            
            // Create a test oscillator to ensure audio subsystem is active
            const oscillator = audioCtx.createOscillator();
            oscillator.type = 'sine';
            oscillator.frequency.value = 440; // A4 note
            
            const gainNode = audioCtx.createGain();
            gainNode.gain.value = 0.01; // Very quiet - just to activate the system
            
            oscillator.connect(gainNode);
            gainNode.connect(audioCtx.destination);
            
            // Start and immediately stop - just to warm up the audio system
            oscillator.start();
            setTimeout(() => {
              oscillator.stop();
              audioCtx.close();
              console.log('🔊 Audio system warmed up');
            }, 100);
          }
        } catch (e) {
          console.warn('Error creating audio context:', e);
        }
        
        // 2. Get all available audio devices to ensure they're activated
        try {
          if (navigator.mediaDevices.enumerateDevices) {
            const devices = await navigator.mediaDevices.enumerateDevices();
            const audioDevices = devices.filter(device => device.kind === 'audioinput');
            console.log(`🎙️ Available audio input devices: ${audioDevices.length}`);
            
            // If we have multiple mics, log them
            if (audioDevices.length > 0) {
              audioDevices.forEach(device => {
                console.log(`- ${device.label || 'Unnamed device'} (${device.deviceId.substring(0, 8)}...)`);
              });
            }
          }
        } catch (e) {
          console.warn('Error enumerating devices:', e);
        }
        
        // 3. Request a fresh audio stream with enhanced constraints
        try {
          // Release any previous streams
          if (window.activeAudioStream) {
            window.activeAudioStream.getTracks().forEach(track => track.stop());
          }
          
          // Request a new stream with HIGH-QUALITY audio
          const stream = await navigator.mediaDevices.getUserMedia({
            audio: {
              echoCancellation: { exact: true },
              noiseSuppression: { exact: true },
              autoGainControl: { exact: true },
              channelCount: { ideal: 1 },
              sampleRate: { ideal: 48000 },
              latency: { ideal: 0.01 },
              sampleSize: { ideal: 16 }
            }
          });
          
          // Save the stream globally
          window.activeAudioStream = stream;
          
          // Ensure tracks are active and enabled
          stream.getAudioTracks().forEach(track => {
            track.enabled = true;
            console.log(`🎙️ Audio track ready: ${track.label} (${track.readyState})`);
          });
          
          console.log('✅ High-quality audio stream acquired successfully');
          return true;
        } catch (e) {
          console.error('Error obtaining audio stream:', e);
          
          // Fall back to basic audio to ensure we at least have something
          try {
            const basicStream = await navigator.mediaDevices.getUserMedia({ audio: true });
            window.activeAudioStream = basicStream;
            console.log('⚠️ Fallback to basic audio stream successful');
            return true;
          } catch (fallbackError) {
            console.error('Critical: Failed to obtain even basic audio stream:', fallbackError);
            return false;
          }
        }
      } catch (e) {
        console.error('Error in audio device preparation:', e);
        return false;
      }
    };
    
    // Function to proactively fix audio issues before joining a call
    const fixAudioBeforeCall = async () => {
      try {
        console.log('🎯 Running proactive audio fixes before joining call');
        
        // 1. Ensure we have a fresh audio stream with optimal constraints
        if (window.activeAudioStream) {
          // Stop all current tracks to ensure we get a fresh stream
          window.activeAudioStream.getTracks().forEach(track => track.stop());
        }
        
        // 2. Request a new stream with strict audio constraints
        const stream = await navigator.mediaDevices.getUserMedia({
          audio: {
            echoCancellation: true,
            noiseSuppression: true,
            autoGainControl: true,
            // Try to force sample rate to match Twilio's preferred settings
            sampleRate: { ideal: 48000 }
          }
        });
        
        // 3. Save the new stream and log details
        window.activeAudioStream = stream;
        
        console.log('🎤 New audio stream acquired with tracks:', 
          stream.getAudioTracks().map(track => ({
            label: track.label,
            enabled: track.enabled,
            readyState: track.readyState,
            muted: track.muted,
            constraints: track.getConstraints()
          }))
        );
        
        // 4. Try to play a short beep to activate the audio subsystem
        try {
          // Create a temporary audio context
          const AudioContext = window.AudioContext || window.webkitAudioContext;
          const audioCtx = new AudioContext();
          
          // Create an oscillator for a short beep
          const oscillator = audioCtx.createOscillator();
          oscillator.type = 'sine';
          oscillator.frequency.setValueAtTime(440, audioCtx.currentTime); // 440 Hz = A4 note
          
          // Create a gain node to control volume
          const gainNode = audioCtx.createGain();
          gainNode.gain.setValueAtTime(0.1, audioCtx.currentTime); // 10% volume
          
          // Connect the oscillator to the gain node and the gain node to the destination
          oscillator.connect(gainNode);
          gainNode.connect(audioCtx.destination);
          
          // Start the oscillator and stop it after 100ms
          oscillator.start();
          setTimeout(() => {
            oscillator.stop();
            audioCtx.close();
            console.log('🔊 Audio subsystem warmed up with test tone');
          }, 100);
        } catch (audioErr) {
          console.warn('Could not play test tone, but continuing:', audioErr);
        }
        
        return true;
      } catch (err) {
        console.error('Error in audio fix routine:', err);
        // Don't block the call if fixes fail
        return false;
      }
    };
    
    // Function to check for active two-way audio in the conference
    const verifyTwoWayAudio = () => {
      console.log('🔍 Running two-way audio verification...');
      
      // 1. Check device and connection state
      const deviceState = VoiceAPI.getDeviceStatus();
      const connectionActive = VoiceAPI.activeConnection !== null;
      
      // 2. Check if audio tracks are active and not muted
      let audioTracksOk = false;
      if (window.activeAudioStream) {
        const audioTracks = window.activeAudioStream.getAudioTracks();
        audioTracksOk = audioTracks.some(track => 
          track.enabled && track.readyState === 'live' && !track.muted);
      }
      
      // 3. Check if the connection has active remote media
      let remoteMediaOk = false;
      try {
        if (VoiceAPI.activeConnection && 
            typeof VoiceAPI.activeConnection.getRemoteStream === 'function') {
          const remoteStream = VoiceAPI.activeConnection.getRemoteStream();
          if (remoteStream && remoteStream.active) {
            remoteMediaOk = true;
          }
        }
      } catch (e) {
        console.warn('Error checking remote media:', e);
      }
      
      // Logging all diagnostic info
      console.log('📊 Two-way audio check results:', {
        deviceState,
        connectionActive,
        audioTracksOk,
        remoteMediaOk,
        // Additional audio diagnostic info
        audioContext: {
          supported: !!(window.AudioContext || window.webkitAudioContext),
          // Check if we have audio output devices
          outputDevices: navigator.mediaDevices && 
            typeof navigator.mediaDevices.enumerateDevices === 'function' ? 
            'Call enumerateDevices() to check outputs' : 'Not supported'
        },
        // Microphone info
        microphone: window.activeAudioStream ? {
          trackCount: window.activeAudioStream.getAudioTracks().length,
          tracks: window.activeAudioStream.getAudioTracks().map(t => ({
            label: t.label,
            enabled: t.enabled,
            readyState: t.readyState,
            muted: t.muted
          }))
        } : 'No active stream'
      });
      
      // FIXED: Improved overall status assessment to include remoteMediaOk
      // This was causing false negative alerts even when everything was fine
      const overallStatus = deviceState === 'busy' && 
                           connectionActive && 
                           audioTracksOk &&
                           remoteMediaOk;  // Added remoteMediaOk to criteria
      
      // Simple audio path check without DTMF tones
      if (VoiceAPI.activeConnection) {
        try {
          console.log('🔄 Checking audio connection status...');
          
          // Only toggle mute on/off to refresh the audio stream
          setTimeout(() => {
            if (VoiceAPI.activeConnection) {
              console.log('✓ Toggling mute ON to reset audio...');
              VoiceAPI.activeConnection.mute(true);
              
              setTimeout(() => {
                if (VoiceAPI.activeConnection) {
                  console.log('✓ Toggling mute OFF to reset audio...');
                  VoiceAPI.activeConnection.mute(false);
                }
              }, 300);
            }
          }, 500);
          
          // Check WebRTC stats if available for diagnostics
          setTimeout(() => {
            if (VoiceAPI.activeConnection && typeof VoiceAPI.activeConnection.getStats === 'function') {
              try {
                VoiceAPI.activeConnection.getStats().then(stats => {
                  console.log('📊 WebRTC Connection Stats:', stats);
                  
                  // Look for specific audio issues in stats
                  const audioIssues = [];
                  stats.forEach(stat => {
                    if (stat.type === 'inbound-rtp' && stat.kind === 'audio') {
                      if (stat.packetsLost > 0) {
                        audioIssues.push(`Packet loss: ${stat.packetsLost} packets`);
                      }
                      if (stat.jitter > 0.05) { // High jitter
                        audioIssues.push(`High jitter: ${stat.jitter.toFixed(3)}s`);
                      }
                    }
                  });
                  
                  if (audioIssues.length > 0) {
                    console.warn('🔊 Audio quality issues detected:', audioIssues);
                  } else {
                    console.log('✓ No WebRTC audio quality issues detected');
                  }
                });
              } catch (statsError) {
                console.warn('Cannot get WebRTC stats:', statsError);
              }
            }
          }, 2000);
        } catch (e) {
          console.warn('Error checking audio connection:', e);
        }
      }
      
      if (!overallStatus) {
        console.warn('⚠️ POTENTIAL TWO-WAY AUDIO ISSUE DETECTED');
        // Alert the user about potential audio issues, but don't show every time
        // as it might be transitional and resolve itself
        if (Math.random() < 0.3) { // Only show 30% of the time to avoid too many alerts
          useAlert('Audio connection establishing. If you cannot hear the caller after a few seconds, try pressing 1 on your keyboard.');
        }
        
        // Suggest adding more status callbacks for debugging
        console.log('SUGGESTION: Add more conference status callbacks in webhook_controller.rb and voice_controller.rb to debug audio issues.');
      } else {
        console.log('✅ Two-way audio appears to be configured correctly');
      }
      
      return overallStatus;
    };
    
    // End a WebRTC call
    const endWebRTCCall = () => {
      if (!isWebRTCInitialized.value) return false;
      
      try {
        // End the call in the client
        const result = VoiceAPI.endClientCall();
        
        // Clean up UI
        stopDurationTimer();
        
        return result;
      } catch (error) {
        console.error('Error ending WebRTC call:', error);
        return false;
      }
    };
    
    // Toggle mute with WebRTC
    const toggleMuteWebRTC = () => {
      if (!isWebRTCInitialized.value) return false;
      
      try {
        isMuted.value = !isMuted.value;
        const result = VoiceAPI.setMute(isMuted.value);
        
        useAlert(isMuted.value ? 'Call muted' : 'Call unmuted');
        
        return result;
      } catch (error) {
        console.error('Error toggling mute:', error);
        return false;
      }
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
      
      // If WebRTC is initialized, end the call via WebRTC
      if (isWebRTCInitialized.value) {
        endWebRTCCall();
      }

      // Also make API call if we have a valid conversation ID and a real call SID (not pending)
      if (savedConversationId && savedCallSid && savedCallSid !== 'pending') {
        // Check if it's a valid Twilio call SID (starts with CA or TJ)
        const isValidTwilioSid =
          savedCallSid.startsWith('CA') || savedCallSid.startsWith('TJ');

        if (isValidTwilioSid) {
          try {
            await VoiceAPI.endCall(savedCallSid, savedConversationId);
            useAlert('Call ended');
          } catch (error) {
            console.error('Error ending call:', error);
            useAlert('Call ended (but server may still show as active)');
          }
        } else {
          useAlert('Call ended');
        }
      } else {
        useAlert('Call ended');
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
        const translation = t(key);
        // Check if the translation is actually the key itself (which happens when the key is not found)
        if (translation === key) {
          // Return the fallback from our local translations or the key itself
          return translations[key] || key;
        }
        return translation;
      } catch (error) {
        console.warn(`Translation error for key '${key}':`, error);
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
      console.log('FloatingCallWidget mounted, initializing components...');
      
      // If this is an active call, start timer
      if (hasActiveCall.value) {
        console.log('Active call detected, starting timer');
        startDurationTimer();
      }
      
      // Handle incoming calls
      if (isIncoming.value) {
        // Check if this is an outbound call
        const isOutboundCall = incomingCall.value && incomingCall.value.isOutbound === true;
        
        if (isOutboundCall && incomingCall.value.requiresAgentJoin) {
          // Auto-join outbound calls after a short delay to ensure everything is loaded
          setTimeout(() => {
            acceptCall();
          }, 1000);
        } else if (!isOutboundCall) {
          // Only play ringtone for true inbound calls, not outbound ones
          console.log('Inbound call detected, preparing ringtone');
          
          // Slight delay to ensure DOM is fully rendered
          setTimeout(() => {
            playRingtone();
          }, 300);
        }
      }
      
      // Fetch contact details if needed (after slight delay to ensure callInfo is populated)
      setTimeout(() => {
        fetchContactDetails();
      }, 500);
      
      // Initialize WebRTC if enabled, with staged approach
      if (props.useWebRTC) {
        // First check browser compatibility immediately
        if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
          console.log('WebRTC not supported in this browser');
          isWebRTCSupported.value = false;
        } else {
          console.log('WebRTC is supported, scheduling initialization');
          
          // Check if we have an inbox ID available
          const inboxId = getAvailableInboxId();
          
          if (!inboxId) {
            console.error('No inbox ID available during component mount. WebRTC initialization will be delayed.');
            
            // We'll wait for store updates that might populate the inbox ID
            const storeWatcher = watch(
              () => [activeCall.value?.inboxId, incomingCall.value?.inboxId, props.inboxId, store.getters['calls/getActiveCall']?.inboxId, store.getters['calls/getIncomingCall']?.inboxId],
              () => {
                const newInboxId = getAvailableInboxId();
                
                if (newInboxId) {
                  console.log(`Inbox ID is now available: ${newInboxId}, proceeding with WebRTC initialization`);
                  storeWatcher(); // Stop watching since we found an ID
                  
                  // Now continue with initialization since we have an inbox ID
                  initializeWebRTC();
                }
              },
              { immediate: true }
            );
          } else {
            console.log(`Inbox ID available at mount: ${inboxId}, proceeding with WebRTC initialization`);
            // We have an inbox ID, proceed with initialization
            initializeWebRTC();
          }
        }
      } else {
        console.log('WebRTC is disabled for this component');
      }
    });
    
    // Extracted WebRTC initialization logic to its own function
    const initializeWebRTC = () => {
      // Perform a staged initialization:
      // 1. First wait for the DOM to be fully rendered
      setTimeout(() => {
        // 2. Request microphone permissions
        navigator.mediaDevices.getUserMedia({ audio: true })
          .then(() => {
            console.log('Microphone permission granted, initializing device');
            microphonePermission.value = 'granted';
            
            // 3. Wait a bit longer before fully initializing the device
            setTimeout(() => {
              initializeTwilioDevice()
                .then(success => {
                  if (success) {
                    console.log('Twilio device initialized successfully on component mount');
                  } else {
                    console.error('Twilio device initialization failed on component mount');
                  }
                })
                .catch(error => {
                  console.error('Error during Twilio device initialization on mount:', error);
                });
            }, 500);
          })
          .catch(error => {
            console.error('Microphone permission denied during initial setup:', error);
            microphonePermission.value = 'denied';
            useAlert('Browser call requires microphone access. Please enable it in your browser settings.');
          });
      }, 1000);
    };

    onBeforeUnmount(() => {
      stopDurationTimer();
      stopRingtone();
      
      // Clean up Twilio device if it's initialized
      if (isWebRTCInitialized.value) {
        endWebRTCCall();
      }
    });

    // Watch for call store changes
    watch(
      () => isIncoming.value,
      newIsIncoming => {
        if (newIsIncoming) {
          // Check if this is an outbound call
          const isOutboundCall = incomingCall.value && incomingCall.value.isOutbound === true;
          
          // Immediate UI feedback 
          stopDurationTimer();
          
          // Only play ringtone for true inbound calls, not outbound ones
          if (!isOutboundCall) {
            setTimeout(() => {
              playRingtone();
            }, 300);
          }
        } else {
          // Make sure to always stop the ringtone when not incoming
          stopRingtone();
        }
      },
      { immediate: true } // Check immediately on component creation
    );
    
    watch(
      () => isJoined.value,
      newIsJoined => {
        if (newIsJoined) {
          // Make multiple attempts to stop the ringtone
          stopRingtone();
          // Double-check after a short delay
          setTimeout(() => {
            stopRingtone();
          }, 100);
          
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

    // Add watcher for call status changes
    watch(
      () => store.state.calls.activeCall?.status,
      (newStatus) => {
        if (newStatus === 'ended' || newStatus === 'completed' || newStatus === 'missed') {
          console.log('Call status changed to:', newStatus);
          stopDurationTimer();
          stopRingtone();
          isCallActive.value = false;
          
          // Update app state
          if (window.app && window.app.$data) {
            window.app.$data.showCallWidget = false;
          }
          
          // Emit event
          emit('callEnded');
          
          // Clear store state
          store.dispatch('calls/clearActiveCall');
          store.dispatch('calls/clearIncomingCall');
        }
      }
    );

    // Add specific watcher for outbound call status
    watch(
      () => store.state.calls.activeCall,
      (newCall) => {
        // Check if this is an outbound call
        const isOutboundCall = newCall && newCall.isOutbound === true;
        
        if (isOutboundCall) {
          console.log('Outbound call status:', newCall?.status);
          
          // Handle outbound call status changes
          if (newCall?.status === 'ended' || newCall?.status === 'completed' || newCall?.status === 'missed') {
            console.log('Outbound call ended with status:', newCall.status);
            stopDurationTimer();
            stopRingtone();
            isCallActive.value = false;
            
            // Update app state
            if (window.app && window.app.$data) {
              window.app.$data.showCallWidget = false;
            }
            
            // Emit event
            emit('callEnded');
            
            // Clear store state
            store.dispatch('calls/clearActiveCall');
            store.dispatch('calls/clearIncomingCall');
          }
        }
      },
      { deep: true } // Watch for nested changes in the call object
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
      isWebRTCInitialized,
      isWebRTCSupported,
      microphonePermission,
      twilioDeviceStatus,
      currentVolume,
      endCall,
      forceEndCall,
      acceptCall,
      rejectCall,
      handleEndCallClick,
      toggleMute,
      toggleCallOptions,
      toggleFullscreen,
      initializeTwilioDevice,
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
              {{ isIncoming ? $t('CONVERSATION.VOICE_CALL.INCOMING_CALL') : $t('CONVERSATION.VOICE_CALL.OUTGOING_CALL') }}
            </div>
          </div>
        </div>
        <div class="call-duration" v-if="!isIncoming">
          <span class="call-duration-label">{{ formattedCallDuration }}</span>
        </div>
      </div>
    </div>

    <div class="call-actions">
      <button
        v-if="isIncoming"
        class="control-button accept-call-button"
        @click="acceptCall"
        :title="$t('CONVERSATION.VOICE_CALL.JOIN_CALL')"
      >
        <span class="i-ph-phone" />
        <span class="button-text">{{ $t('CONVERSATION.VOICE_CALL.JOIN_CALL') }}</span>
      </button>

      <button
        v-if="isIncoming"
        class="control-button reject-call-button"
        @click="rejectCall"
        :title="$t('CONVERSATION.VOICE_CALL.REJECT_CALL')"
      >
        <span class="i-ph-phone-x" />
        <span class="button-text">{{ $t('CONVERSATION.VOICE_CALL.REJECT_CALL') }}</span>
      </button>

      <button
        v-if="!isIncoming"
        class="control-button end-call-button"
        @click="handleEndCallClick"
        :title="$t('CONVERSATION.VOICE_CALL.END_CALL')"
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
    
    <!-- WebRTC Status indicator -->
    <div v-if="useWebRTC" class="webrtc-status">
      <div 
        class="webrtc-indicator" 
        :class="{ 
          'is-active': isWebRTCInitialized, 
          'is-inactive': !isWebRTCInitialized && isWebRTCSupported,
          'is-unsupported': !isWebRTCSupported,
          'is-ready': isWebRTCInitialized && twilioDeviceStatus === 'ready',
          'is-busy': isWebRTCInitialized && twilioDeviceStatus === 'busy',
          'is-error': isWebRTCInitialized && twilioDeviceStatus === 'error',
        }"
      >
        <span class="webrtc-dot"></span>
        <span class="webrtc-text">
          <!-- Different messages based on status -->
          <template v-if="!isWebRTCSupported">
            Browser calls not supported
          </template>
          <template v-else-if="!isWebRTCInitialized">
            Browser call initializing...
          </template>
          <template v-else>
            Browser Call: {{ twilioDeviceStatus === 'ready' ? 'Ready' : twilioDeviceStatus }}
          </template>
          
          <!-- Mic status if initialized -->
          <template v-if="isWebRTCInitialized">
            <span class="mic-status">
              <span :class="isMuted ? 'i-ph-microphone-slash text-xs' : 'i-ph-microphone text-xs'"></span>
              {{ isMuted ? 'Muted' : 'Active' }}
            </span>
          </template>
        </span>
      </div>
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

// WebRTC indicator styles
.webrtc-status {
  margin-top: 8px;
  padding-top: 8px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  display: flex;
  justify-content: center;
}

.webrtc-indicator {
  display: flex;
  align-items: center;
  font-size: 12px;
  color: var(--s-300, #9ca3af);
  background-color: rgba(0, 0, 0, 0.2);
  border-radius: 12px;
  padding: 4px 8px;
  
  // Different states for the indicator
  &.is-active .webrtc-dot {
    background-color: var(--g-500, #10b981);
  }
  
  &.is-inactive .webrtc-dot {
    background-color: var(--y-500, #f59e0b);
    animation: webrtcPulse 1.5s infinite;
  }
  
  &.is-unsupported .webrtc-dot {
    background-color: var(--s-400, #6b7280);
  }
  
  &.is-ready .webrtc-dot {
    background-color: var(--g-500, #10b981);
  }
  
  &.is-busy .webrtc-dot {
    background-color: var(--b-400, #60a5fa);
  }
  
  &.is-error .webrtc-dot {
    background-color: var(--r-500, #dc2626);
  }
}

.webrtc-dot {
  width: 8px;
  height: 8px;
  flex-shrink: 0;
  border-radius: 50%;
  background-color: var(--r-500, #dc2626);
  margin-right: 6px;
  position: relative;
  
  &:after {
    content: '';
    position: absolute;
    top: -2px;
    left: -2px;
    right: -2px;
    bottom: -2px;
    border-radius: 50%;
    border: 1px solid currentColor;
    animation: webrtcPulse 1.5s infinite;
  }
}

.webrtc-text {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  white-space: nowrap;
}

.mic-status {
  display: flex;
  align-items: center;
  gap: 4px;
  margin-left: 8px;
  padding-left: 8px;
  border-left: 1px solid rgba(255, 255, 255, 0.2);
}

@keyframes webrtcPulse {
  0% {
    transform: scale(1);
    opacity: 0.8;
  }
  50% {
    transform: scale(1.5);
    opacity: 0;
  }
  100% {
    transform: scale(1);
    opacity: 0;
  }
}
</style>
