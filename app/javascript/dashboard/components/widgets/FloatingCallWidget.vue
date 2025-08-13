<script>
import { computed, ref, watch, onMounted, onBeforeUnmount } from 'vue';
import { useStore } from 'vuex';
import { useRouter, useRoute } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
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
    inboxId: {
      type: [Number, String],
      default: null,
    },
    inboxAvatarUrl: {
      type: String,
      default: '',
    },
    inboxPhoneNumber: {
      type: String,
      default: '',
    },
    avatarUrl: {
      type: String,
      default: '',
    },
    phoneNumber: {
      type: String,
      default: '',
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
    const router = useRouter();
    const route = useRoute();
    const { t } = useI18n();
    const callDuration = ref(0);
    const durationTimer = ref(null);
    const isCallActive = ref(!!props.callSid);
    const isMuted = ref(false);
    const showCallOptions = ref(false);
    const ringtoneAudio = ref(null);
    const displayContactName = ref('');
    // Removed phone number caching - not needed for voice calls
    // Removed complex avatar caching - voice calls use simple fallbacks

    // Computed property to get the proper display name
    const contactDisplayName = computed(() => {
      // Get the contact ID from all possible sources
      const contactId =
        props.contactId ||
        callInfo.value?.contactId ||
        activeCall.value?.contactId ||
        incomingCall.value?.contactId;

      // First check our local ref that might have been updated
      if (
        displayContactName.value &&
        displayContactName.value !== 'Loading...'
      ) {
        return displayContactName.value;
      }

      // Then try from props
      if (props.contactName) {
        displayContactName.value = props.contactName;
        return props.contactName;
      }

      // Then try from call info
      if (callInfo.value?.contactName) {
        displayContactName.value = callInfo.value.contactName;
        return callInfo.value.contactName;
      }

      if (activeCall.value?.contactName) {
        displayContactName.value = activeCall.value.contactName;
        return activeCall.value.contactName;
      }

      if (incomingCall.value?.contactName) {
        displayContactName.value = incomingCall.value.contactName;
        return incomingCall.value.contactName;
      }

      // If we have a contactId, try to get from the contacts store
      if (contactId) {
        const contact = store.getters['contacts/getContact'](contactId);

        if (contact?.name) {
          return contact.name;
        }

        // If contact exists but no name, use phone number
        if (contact?.phone_number) {
          return contact.phone_number;
        }
      }

      // If we have a phone number, use that
      if (
        callerPhoneNumber.value &&
        callerPhoneNumber.value !== 'Call in progress'
      ) {
        displayContactName.value = callerPhoneNumber.value;
        return callerPhoneNumber.value;
      }

      // If we don't have a name but props has phoneNumber, use that
      if (props.phoneNumber && props.phoneNumber !== '') {
        displayContactName.value = props.phoneNumber;
        return props.phoneNumber;
      }

      // Try to get current contact using the direct API
      if (contactId) {
        // Make a direct API call for this contact (don't wait for the result)
        // We need to do this outside the computed property for it to work properly
        setTimeout(() => {
          ContactAPI.show(contactId)
            .then(response => {
              if (response.data?.name) {
                displayContactName.value = response.data.name;
              } else if (response.data?.phone_number) {
                displayContactName.value = response.data.phone_number;
              }
            })
            .catch(() => {});
        }, 500);
      }

      // Default fallback
      return 'Call in progress';
    });
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
      'CONVERSATION.VOICE_CALL.CALL_REJECTED': 'Call rejected',
      'CONVERSATION.VOICE_CALL.INCOMING_CALL': 'Incoming call',
    };

    // Computed properties
    const activeCall = computed(() => store.getters['calls/getActiveCall']);
    const incomingCall = computed(() => store.getters['calls/getIncomingCall']);
    const hasIncomingCall = computed(
      () => store.getters['calls/hasIncomingCall']
    );
    const hasActiveCall = computed(() => store.getters['calls/hasActiveCall']);

    const isIncoming = computed(() => {
      return hasIncomingCall.value && !hasActiveCall.value;
    });

    const callInfo = computed(() => {
      const info = isIncoming.value ? incomingCall.value : activeCall.value;

      return info;
    });

    const isJoined = computed(() => {
      return activeCall.value && activeCall.value.isJoined;
    });

    const formattedCallDuration = computed(() => {
      const minutes = Math.floor(callDuration.value / 60);
      const seconds = callDuration.value % 60;
      return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    });

    // Simplified contact avatar - voice calls don't need complex avatar logic
    const contactAvatarUrl = computed(() => {
      // Try props first
      if (props.avatarUrl) return props.avatarUrl;

      // Try call data
      if (incomingCall.value?.avatarUrl) return incomingCall.value.avatarUrl;
      if (activeCall.value?.avatarUrl) return activeCall.value.avatarUrl;

      // For voice calls, we don't show contact avatars - just return null
      return null;
    });

    // Computed property to get the caller's phone number
    const callerPhoneNumber = computed(() => {
      // First try from props
      if (props.phoneNumber) {
        return props.phoneNumber;
      }

      // Then try from call data
      if (callInfo.value?.phoneNumber) {
        return callInfo.value.phoneNumber;
      }

      if (activeCall.value?.phoneNumber) {
        return activeCall.value.phoneNumber;
      }

      if (incomingCall.value?.phoneNumber) {
        return incomingCall.value.phoneNumber;
      }

      // Check for the contact name as a potential phone number format
      if (
        props.contactName &&
        /^\+?\d+$/.test(props.contactName.replace(/[\s\(\)-]/g, ''))
      ) {
        return props.contactName;
      }

      return 'Call in progress';
    });

    // Computed property to get the inbox phone number directly from call data
    const inboxPhoneNumber = computed(() => {
      // First try from props
      if (props.inboxPhoneNumber) {
        return props.inboxPhoneNumber;
      }

      // Then try from call info
      if (callInfo.value?.inboxPhoneNumber) {
        return callInfo.value.inboxPhoneNumber;
      }

      if (activeCall.value?.inboxPhoneNumber) {
        return activeCall.value.inboxPhoneNumber;
      }

      if (incomingCall.value?.inboxPhoneNumber) {
        return incomingCall.value.inboxPhoneNumber;
      }

      // Default fallback
      return '';
    });

    // Inbox avatar - simple direct lookup like conversation list
    const inboxAvatarUrl = computed(() => {
      // Try props first
      if (props.inboxAvatarUrl) return props.inboxAvatarUrl;

      // Try call data
      if (callInfo.value?.inboxAvatarUrl) return callInfo.value.inboxAvatarUrl;
      if (activeCall.value?.inboxAvatarUrl)
        return activeCall.value.inboxAvatarUrl;
      if (incomingCall.value?.inboxAvatarUrl)
        return incomingCall.value.inboxAvatarUrl;

      // No avatar available - component will show phone icon fallback
      return null;
    });

    // Computed property to get the correct inbox name
    const inboxDisplayName = computed(() => {
      // First try to get it from the props (this is what App.vue directly provides)
      if (props.inboxName) {
        return props.inboxName;
      }

      // Then try from call info
      if (callInfo.value?.inboxName) {
        return callInfo.value.inboxName;
      }

      // Then try from active or incoming call
      if (activeCall.value?.inboxName) {
        return activeCall.value.inboxName;
      }

      if (incomingCall.value?.inboxName) {
        return incomingCall.value.inboxName;
      }

      // Try to get it from the inbox ID
      const inboxId =
        props.inboxId ||
        callInfo.value?.inboxId ||
        activeCall.value?.inboxId ||
        incomingCall.value?.inboxId;

      if (inboxId) {
        const inbox = store.getters['inboxes/getInbox'](inboxId);
        if (inbox?.name) {
          return inbox.name;
        }
      }

      // Default fallback
      return 'Customer support';
    });

    // Methods
    const startDurationTimer = () => {
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
      }

      // Force play with user interaction if needed
      const playPromise = ringtoneAudio.value.play();

      if (playPromise !== undefined) {
        playPromise.catch(error => {
          // If autoplay was prevented, try again on next user interaction
          document.addEventListener(
            'click',
            () => {
              ringtoneAudio.value.play().catch(() => {});
            },
            { once: true }
          );
        });
      }
    };

    const stopRingtone = () => {
      if (ringtoneAudio.value) {
        try {
          ringtoneAudio.value.pause();
          ringtoneAudio.value.currentTime = 0;
        } catch (error) {}
      } else {
      }
    };

    // Emergency force end call function - simpler and more direct
    const forceEndCall = () => {
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
          // Use the direct API call without using global method
          VoiceAPI.endCall(savedCallSid, savedConversationId)
            .then(response => {})
            .catch(error => {});
        } else {
        }
      } else if (!savedConversationId) {
      } else {
      }

      // Also use global method to update UI states
      if (window.forceEndCall) {
        window.forceEndCall();
      }

      // Force App state update directly
      if (window.app) {
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
      stopDurationTimer();
      stopRingtone();
      isCallActive.value = false;

      emit('callEnded');
      useAlert('Call ended');

      try {
        if (props.callSid && props.conversationId) {
          await VoiceAPI.endCall(props.callSid, props.conversationId);
        }
      } catch (error) {
        // Silently handle API errors
      }

      store.dispatch('calls/clearActiveCall');
      store.dispatch('calls/clearIncomingCall');
    };

    // Accept incoming call and redirect to conversation
    const acceptCall = async () => {
      stopRingtone();

      try {
        if (incomingCall.value) {
          const { callSid, conversationId } = incomingCall.value;

          useAlert('Joining call...', 'info');

          const webRTCSuccess = await joinCallWithWebRTC();

          if (webRTCSuccess) {
            useAlert('Connected to call successfully', 'success');
            startDurationTimer();
            store.dispatch('calls/acceptIncomingCall');

            if (conversationId) {
              const accountId =
                route.params.accountId ||
                (window.Current &&
                  window.Current.account &&
                  window.Current.account.id) ||
                (store.state.auth && store.state.auth.currentAccountId);

              if (accountId) {
                const routePath = `/app/accounts/${accountId}/conversations/${conversationId}`;
                emit('callJoined', { conversationId, accountId });
                router.push(routePath);
              }
            }
          }
        }
      } catch (error) {
        if (error.name === 'NotAllowedError') {
          useAlert(
            'Microphone permission denied. Please enable your microphone to join calls.',
            'error'
          );
        }
      }
    };

    // Reject incoming call
    const rejectCall = async () => {
      stopRingtone();

      try {
        if (incomingCall.value) {
          const { callSid, conversationId } = incomingCall.value;

          useAlert(safeTranslate('CONVERSATION.VOICE_CALL.CALL_REJECTED'));
          await VoiceAPI.rejectCall(callSid, conversationId);
          store.dispatch('calls/clearIncomingCall');

          // Emit event
          emit('callRejected');

          // Update app state - checking for $data property
          if (window.app && window.app.$data) {
            window.app.$data.showCallWidget = false;
          }
        }
      } catch (error) {
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

    // Simplified avatar error handling - just hide broken images
    const handleAvatarError = event => {
      event.target.style.display = 'none';
    };

    // WebRTC and Twilio Voice SDK methods

    // Get inbox ID from all possible sources
    const getAvailableInboxId = () => {
      // Try all possible sources of inbox ID in order of most reliable first
      return (
        props.inboxId ||
        props.conversation?.inbox_id ||
        callInfo.value?.inboxId ||
        activeCall.value?.inboxId ||
        incomingCall.value?.inboxId ||
        store.getters['calls/getActiveCall']?.inboxId ||
        store.getters['calls/getIncomingCall']?.inboxId ||
        // Last resort - try to find an inbox ID from the current conversation in the store
        (props.conversationId &&
          store.getters.getConversation?.(props.conversationId)?.inbox_id)
      );
    };

    // Initialize the Twilio device
    const initializeTwilioDevice = async () => {
      // No need to initialize if already done
      if (isWebRTCInitialized.value) return true;

      try {
        // Try to find an inbox ID from any available source
        const inboxId = getAvailableInboxId();

        if (!inboxId) {
          const errorMsg =
            'No inbox ID available to initialize Twilio Device. Please try again with a voice-enabled inbox.';

          useAlert(errorMsg);
          return false;
        }

        // Check browser support for WebRTC
        if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
          isWebRTCSupported.value = false;
          const errorMsg =
            'WebRTC is not supported in this browser. Try Chrome, Firefox, or Edge.';

          useAlert(errorMsg);
          return false;
        }

        // Step 1: Request microphone permission with specific audio constraints
        // These help establish a better audio connection
        try {
          // Enhanced audio constraints to resolve audio connection issues
          const audioConstraints = {
            audio: {
              echoCancellation: { exact: true }, // Force echo cancellation
              noiseSuppression: { exact: true }, // Force noise suppression
              autoGainControl: { exact: true }, // Force auto gain control
              channelCount: { ideal: 1 }, // Mono is more reliable than stereo
              latency: { ideal: 0.01 }, // Lower latency for better real-time
              sampleRate: { ideal: 48000 }, // Higher sample rate for voice clarity
              sampleSize: { ideal: 16 }, // Standard bit depth
              volume: { ideal: 1.0 }, // Maximum volume
            },
          };

          const stream =
            await navigator.mediaDevices.getUserMedia(audioConstraints);

          // CRITICAL: Keep the stream active to maintain audio permissions
          window.activeAudioStream = stream;

          microphonePermission.value = 'granted';

          // Listen for track-ended events that might indicate audio issues
          stream.getAudioTracks().forEach(track => {
            track.onended = () => {};
          });
        } catch (micError) {
          // Fall back to default audio constraints if specific ones fail
          try {
            const stream = await navigator.mediaDevices.getUserMedia({
              audio: true,
            });
            window.activeAudioStream = stream;
            microphonePermission.value = 'granted';
          } catch (fallbackError) {
            microphonePermission.value = 'denied';
            const errorMsg = `Microphone access denied: ${fallbackError.message}. Please allow microphone access in your browser settings.`;

            useAlert(errorMsg);
            return false;
          }
        }

        // Step 2: Initialize Twilio Device
        try {
          // Enhanced error handling during initialization
          try {
            await VoiceAPI.initializeDevice(inboxId);
          } catch (initError) {
            // Check for specific error cases
            if (
              initError.message &&
              initError.message.includes('Server error')
            ) {
              // If we have more details from the server error, show them
              if (initError.details) {
                // Check for common error patterns
                if (
                  initError.details.includes(
                    'uninitialized constant Twilio::JWT::AccessToken'
                  )
                ) {
                  throw new Error(
                    'Twilio gem not properly installed. Please check server configuration.'
                  );
                } else if (
                  initError.details.includes('undefined method') &&
                  initError.details.includes('for nil:NilClass')
                ) {
                  throw new Error(
                    'Voice channel configuration is incomplete. Please check your inbox setup.'
                  );
                } else if (
                  initError.details.includes('Missing Twilio credentials')
                ) {
                  throw new Error(
                    'Missing Twilio credentials. Please configure account SID and auth token in channel settings.'
                  );
                }
              }
            }

            // If no special case was handled, re-throw the original error
            throw initError;
          }

          // Check if device was actually initialized
          if (!VoiceAPI.device) {
            throw new Error(
              'Device initialization failed silently. Please check server logs.'
            );
          }

          isWebRTCInitialized.value = true;
          twilioDeviceStatus.value = VoiceAPI.getDeviceStatus();

          // Success notification

          useAlert('Voice call device initialized successfully');

          return true;
        } catch (deviceError) {
          // Construct a helpful error message based on the error details
          let errorMsg = 'Failed to initialize voice client';

          // Check for specific error patterns
          if (deviceError.message && deviceError.message.includes('token')) {
            errorMsg =
              'Failed to get Twilio token. Check your Twilio credentials in the Voice channel settings.';
          } else if (
            deviceError.message &&
            deviceError.message.includes('TwiML')
          ) {
            errorMsg =
              'Twilio configuration issue: Missing or invalid TwiML App SID in Voice channel settings.';
          } else if (
            deviceError.message &&
            deviceError.message.includes('Voice channel configuration')
          ) {
            errorMsg = deviceError.message;
          } else if (
            deviceError.message &&
            deviceError.message.includes('Server error')
          ) {
            errorMsg =
              'Server error while initializing voice client. Check your Twilio configuration.';
          } else if (deviceError.message) {
            errorMsg = `Voice client initialization failed: ${deviceError.message}`;
          }

          useAlert(errorMsg);
          return false;
        }
      } catch (error) {
        // Handle any uncaught errors

        useAlert(
          `Unexpected error: ${error.message}. Please check console for details.`
        );
        return false;
      }
    };

    // Join a call using the Twilio Client - this is the only option for agents now
    const joinCallWithWebRTC = async () => {
      // This is the critical method where an agent joins an incoming call
      try {
        // 1. Ensure Twilio device is initialized
        if (!isWebRTCInitialized.value) {
          const initSuccess = await initializeTwilioDevice();
          if (!initSuccess) return false;
        }

        // 2. Reset device if not ready
        if (VoiceAPI.getDeviceStatus() !== 'ready') {
          await VoiceAPI.endClientCall();
          await VoiceAPI.initializeDevice(getAvailableInboxId());
        }

        // 3. Validate incoming call object
        if (!incomingCall.value) return false;
        const {
          callSid,
          conversationId,
          accountId: callAccountId,
        } = incomingCall.value;

        // --- Account ID extraction helper ---
        const extractAccountId = () => {
          return (
            callAccountId ||
            (window.Current &&
              window.Current.account &&
              window.Current.account.id) ||
            (typeof Current !== 'undefined' &&
              Current.account &&
              Current.account.id) ||
            (() => {
              const urlMatch =
                window.location.pathname.match(/\/accounts\/(\d+)/);
              return urlMatch && urlMatch[1] ? urlMatch[1] : null;
            })()
          );
        };
        let accountId = extractAccountId();

        // --- Step 4: Inform server agent is joining and get conference_sid ---
        let serverResponse = null;
        try {
          const response = await VoiceAPI.joinCall({
            call_sid: callSid,
            conversation_id: conversationId,
            account_id: accountId,
          });
          serverResponse = response.data;

          // Process the server response to get the conference_sid
          if (serverResponse && serverResponse.conference_sid) {
            // Save the conference_sid in the incomingCall data
            if (!incomingCall.value.conference_sid) {
              // Save the conference_sid in only the key places needed
              incomingCall.value.conference_sid = serverResponse.conference_sid;

              // Also set the 'To' parameter required by Twilio
              incomingCall.value.To = serverResponse.conference_sid;
            }
          } else {
            return false;
          }
        } catch (apiError) {
          return false;
        }

        // 5. Proactively fix audio issues
        await fixAudioBeforeCall();

        // Simple conference ID extraction - using ONE source of truth
        const extractConferenceId = () => {
          // Get conference_sid from incoming call data - this is the SINGLE source of truth
          const confId = incomingCall.value?.conference_sid;

          if (!confId) {
            return null;
          }

          return confId;
        };
        const conferenceId = extractConferenceId();
        if (!conferenceId) return false;

        // Ensure conferenceId is a string
        const conferenceIdString = String(conferenceId);

        // Simple params object with the required fields in the correct format
        const enhancedParams = {
          To: conferenceIdString, // CAPITAL T is required for Twilio and MUST be a string
          account_id: accountId,
          is_agent: 'true', // Flag that this is an agent joining
        };

        // 6. Re-initialize device if needed
        if (VoiceAPI.getDeviceStatus() !== 'ready') {
          try {
            await VoiceAPI.initializeDevice(getAvailableInboxId());
          } catch (initError) {
            // Continue anyway
          }
        }

        // 7. Join the conference via WebRTC
        const connection = VoiceAPI.joinClientCall(enhancedParams);
        if (!connection) {
          throw new Error('Failed to create connection object');
        }

        // 8. Request a fresh audio stream with enhanced constraints
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
              sampleSize: { ideal: 16 },
            },
          });

          // Save the stream globally
          window.activeAudioStream = stream;

          // Ensure tracks are active and enabled
          stream.getAudioTracks().forEach(track => {
            track.enabled = true;
          });

          return true;
        } catch (e) {
          // Fall back to basic audio to ensure we at least have something
          try {
            const basicStream = await navigator.mediaDevices.getUserMedia({
              audio: true,
            });
            window.activeAudioStream = basicStream;
            return true;
          } catch (fallbackError) {
            return false;
          }
        }
      } catch (e) {
        return false;
      }
    };
    // Function to proactively fix audio issues before joining a call
    const fixAudioBeforeCall = async () => {
      try {
        // 1. Stop and clear any existing audio stream
        if (window.activeAudioStream) {
          try {
            window.activeAudioStream.getTracks().forEach(track => track.stop());
          } catch (e) {
            // Ignore errors stopping tracks
          }
        }

        // 2. Request a new audio stream with optimal constraints
        const stream = await navigator.mediaDevices.getUserMedia({
          audio: {
            echoCancellation: true,
            noiseSuppression: true,
            autoGainControl: true,
            sampleRate: { ideal: 48000 },
          },
        });
        window.activeAudioStream = stream;

        // 3. Log track details for diagnostics (optional, can be removed in prod)
        if (process.env.NODE_ENV === 'development') {
          // eslint-disable-next-line no-console
          console.log(
            '[fixAudioBeforeCall] Tracks:',
            stream.getAudioTracks().map(track => ({
              label: track.label,
              enabled: track.enabled,
              readyState: track.readyState,
              muted: track.muted,
              constraints: track.getConstraints(),
            }))
          );
        }

        // 4. Play a short beep to activate the audio subsystem
        try {
          // Play beep logic here if needed
        } catch (beepError) {
          // Ignore errors playing beep
        }
      } catch (error) {
        // Ignore errors during audio setup
      }
    };

    // ... (rest of the code remains the same)
    // Toggle mute with WebRTC
    const toggleMuteWebRTC = () => {
      if (!isWebRTCInitialized.value) return false;

      try {
        isMuted.value = !isMuted.value;
        const result = VoiceAPI.setMute(isMuted.value);

        useAlert(isMuted.value ? 'Call muted' : 'Call unmuted');

        return result;
      } catch (error) {
        return false;
      }
    };

    // Handler for end call click
    const handleEndCallClick = async () => {
      // Save the call data before UI updates
      const callData = isIncoming.value ? incomingCall.value : activeCall.value;

      if (!callData) {
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

        // Find any ContactInfo components and clear their activeCallConversation
        if (window.app && window.app.$children) {
          const clearContactInfoCallState = components => {
            components.forEach(component => {
              if (
                component.$options &&
                component.$options.name === 'ContactInfo'
              ) {
                if (component.activeCallConversation) {
                  component.activeCallConversation = null;
                  component.$forceUpdate();
                }
              }
              if (component.$children && component.$children.length) {
                clearContactInfoCallState(component.$children);
              }
            });
          };
          clearContactInfoCallState(window.app.$children);
        }
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
        return translations[key] || key;
      }
    };

    // Function to fetch contact details if needed
    const fetchContactDetails = async () => {
      // If we already have a contact name, don't fetch
      if (
        displayContactName.value !== 'Loading...' &&
        displayContactName.value !== 'Unknown Caller'
      ) {
        return;
      }

      // If we have a contact ID, fetch the details
      const contactId = props.contactId || callInfo.value?.contactId;
      if (contactId) {
        try {
          const response = await ContactAPI.show(contactId);
          if (response.data && response.data.payload) {
            const contact = response.data.payload;
            displayContactName.value = contact.name || 'Unknown Caller';

            // If there's incoming or active call data, update it with the avatar URL
            if (incomingCall.value) {
              incomingCall.value.avatarUrl = contact.avatar_url || null;
            }
            if (activeCall.value) {
              activeCall.value.avatarUrl = contact.avatar_url || null;
            }
          }
        } catch (error) {
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

      // Handle incoming calls
      if (isIncoming.value) {
        // Check if this is an outbound call
        const isOutboundCall =
          incomingCall.value && incomingCall.value.isOutbound === true;

        if (isOutboundCall && incomingCall.value.requiresAgentJoin) {
          // Auto-join outbound calls after ensuring WebRTC is ready
          setTimeout(async () => {
            // Ensure WebRTC is initialized before joining
            if (props.useWebRTC && !isWebRTCInitialized.value) {
              useAlert('Initializing WebRTC for outbound call...', 'info');
              const initSuccess = await initializeTwilioDevice();
              if (!initSuccess) {
                useAlert(
                  'Failed to initialize WebRTC for outbound call',
                  'error'
                );
                return;
              }
              // Wait for device to be in ready state
              let attempts = 0;
              while (VoiceAPI.getDeviceStatus() !== 'ready' && attempts < 10) {
                await new Promise(resolve => setTimeout(resolve, 500));
                attempts++;
              }
              if (VoiceAPI.getDeviceStatus() !== 'ready') {
                useAlert('WebRTC device not ready for outbound call', 'error');
                return;
              }
            }
            useAlert('Joining outbound call...', 'info');
            acceptCall();
          }, 3000); // Even longer delay to ensure WebRTC is fully ready
        } else if (!isOutboundCall) {
          // Only play ringtone for true inbound calls, not outbound ones

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
          isWebRTCSupported.value = false;
        } else {
          // Check if we have an inbox ID available
          const inboxId = getAvailableInboxId();

          if (!inboxId) {
            // We'll wait for store updates that might populate the inbox ID
            const storeWatcher = watch(
              () => [
                activeCall.value?.inboxId,
                incomingCall.value?.inboxId,
                props.inboxId,
                store.getters['calls/getActiveCall']?.inboxId,
                store.getters['calls/getIncomingCall']?.inboxId,
              ],
              () => {
                const newInboxId = getAvailableInboxId();

                if (newInboxId) {
                  storeWatcher(); // Stop watching since we found an ID

                  // Now continue with initialization since we have an inbox ID
                  initializeWebRTC();
                }
              },
              { immediate: true }
            );
          } else {
            // We have an inbox ID, proceed with initialization
            initializeWebRTC();
          }
        }
      } else {
      }
    });

    // Extracted WebRTC initialization logic to its own function
    const initializeWebRTC = () => {
      // Perform a staged initialization:
      // 1. First wait for the DOM to be fully rendered
      setTimeout(() => {
        // 2. Request microphone permissions
        navigator.mediaDevices
          .getUserMedia({ audio: true })
          .then(() => {
            microphonePermission.value = 'granted';

            // 3. Wait a bit longer before fully initializing the device
            setTimeout(() => {
              initializeTwilioDevice()
                .then(success => {
                  if (success) {
                  } else {
                  }
                })
                .catch(error => {});
            }, 500);
          })
          .catch(error => {
            microphonePermission.value = 'denied';
            useAlert(
              'Browser call requires microphone access. Please enable it in your browser settings.'
            );
          });
      }, 1000);
    };

    const verifyTwoWayAudio = async () => {
      try {
        // 1. Stop and clear any existing audio stream
        if (window.activeAudioStream) {
          window.activeAudioStream.getTracks().forEach(track => track.stop());
        }

        // 2. Request a new audio stream with optimal constraints
        const stream = await navigator.mediaDevices.getUserMedia({
          audio: {
            echoCancellation: true,
            noiseSuppression: true,
            autoGainControl: true,
            sampleRate: { ideal: 48000 },
          },
        });
        window.activeAudioStream = stream;

        // 3. Log track details for diagnostics (optional, can be removed in prod)
        if (process.env.NODE_ENV === 'development') {
          console.log(
            '[verifyTwoWayAudio] Tracks:',
            stream.getAudioTracks().map(track => ({
              label: track.label,
              enabled: track.enabled,
              readyState: track.readyState,
              muted: track.muted,
              constraints: track.getConstraints(),
            }))
          );
        }

        // 4. Play a short beep to activate the audio subsystem
        try {
          // Play a short beep
        } catch (error) {
          // Ignore errors playing beep
        }
      } catch (error) {
        // Handle errors checking remote media
      }
    };

    // End a WebRTC call using the VoiceAPI
    const endWebRTCCall = () => {
      if (!isWebRTCInitialized.value) return false;

      try {
        // Use the VoiceAPI to end the client call
        VoiceAPI.endClientCall();

        // Clean up audio resources
        if (window.activeAudioStream) {
          window.activeAudioStream.getTracks().forEach(track => {
            track.stop();
          });
          window.activeAudioStream = null;
        }

        return true;
      } catch (error) {
        return false;
      }
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
          const isOutboundCall =
            incomingCall.value && incomingCall.value.isOutbound === true;

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
      newCallInfo => {
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
      newStatus => {
        if (
          newStatus === 'ended' ||
          newStatus === 'completed' ||
          newStatus === 'missed'
        ) {
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
      newCall => {
        // Check if this is an outbound call
        const isOutboundCall = newCall && newCall.isOutbound === true;

        if (isOutboundCall) {
          // Handle outbound call status changes
          if (
            newCall?.status === 'ended' ||
            newCall?.status === 'completed' ||
            newCall?.status === 'missed'
          ) {
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

    // Watch for changes to contactName prop
    watch(
      () => props.contactName,
      newContactName => {
        if (newContactName) {
          displayContactName.value = newContactName;
        }
      }
    );

    return {
      isCallActive,
      callDuration,
      formattedCallDuration,
      isMuted,
      showCallOptions,
      isIncoming,
      isJoined,
      activeCall,
      incomingCall,
      callInfo,
      displayContactName,
      contactDisplayName,
      contactAvatarUrl,
      callerPhoneNumber,
      inboxDisplayName,
      inboxAvatarUrl,
      inboxPhoneNumber,
      isWebRTCInitialized,
      isWebRTCSupported,
      microphonePermission,
      twilioDeviceStatus,
      currentVolume,
      router,
      route,
      endCall,
      forceEndCall,
      acceptCall,
      rejectCall,
      handleEndCallClick,
      toggleMute,
      toggleCallOptions,
      initializeTwilioDevice,
      safeTranslate,
      endWebRTCCall,
    };
  },
};
</script>

<template>
  <!-- Main Widget Container -->
  <div
    class="floating-call-widget"
    :class="{
      'is-minimized': !showCallOptions,
      'is-incoming': isIncoming,
      'has-call-options': showCallOptions,
    }"
  >
    <!-- Call Header -->
    <div class="call-header">
      <div class="flex items-center justify-between w-full">
        <div class="flex items-center">
          <!-- Left side with inbox avatar and call info -->
          <div class="inbox-avatar">
            <!-- Simple avatar logic for voice calls -->
            <img
              v-if="inboxAvatarUrl && inboxAvatarUrl.startsWith('http')"
              :src="inboxAvatarUrl"
              :alt="inboxDisplayName"
              class="avatar-image"
              @error="handleAvatarError"
            />
            <i v-else class="i-ri-phone-fill text-white text-lg" />
          </div>
          <div class="header-info">
            <div class="voice-label">{{ inboxDisplayName }}</div>
            <div class="phone-number">{{ inboxPhoneNumber }}</div>
          </div>
        </div>
        <div>
          <!-- Right side with just the call timer (no icon) -->
          <span v-if="!isIncoming" class="call-time">{{
            formattedCallDuration
          }}</span>
        </div>
      </div>
    </div>

    <!-- Call Content -->
    <div class="call-content">
      <!-- Participant Info - Only show the caller -->
      <div class="participant-row">
        <div class="participant contact">
          <div class="avatar contact-avatar">
            <img
              v-if="contactAvatarUrl"
              :src="contactAvatarUrl"
              :alt="contactDisplayName"
              class="avatar-image"
              @error="handleAvatarError"
            />
            <span v-else>{{ contactDisplayName.charAt(0).toUpperCase() }}</span>
          </div>
          <div class="name">{{ contactDisplayName }}</div>
          <div class="phone-number-detail">{{ callerPhoneNumber }}</div>
          <div class="call-status">In call</div>
        </div>
      </div>
    </div>

    <!-- Call Options Menu (when showCallOptions is true) -->
    <div v-if="showCallOptions" class="call-options-menu">
      <button class="option-button" @click="toggleMute">
        <span :class="isMuted ? 'i-ph-microphone-slash' : 'i-ph-microphone'" />
        <span>{{ isMuted ? 'Unmute' : 'Mute' }} mic</span>
      </button>

      <button class="option-button end-call" @click="handleEndCallClick">
        <span class="i-ph-phone-x" />
        <span>End call</span>
      </button>
    </div>

    <!-- Call Controls -->
    <div class="call-controls">
      <!-- Incoming Call Controls -->
      <template v-if="isIncoming">
        <button
          class="control-button reject-call-button"
          :title="$t('CONVERSATION.VOICE_CALL.REJECT_CALL')"
          @click="rejectCall"
        >
          <span class="i-ph-phone-x" />
          <span class="button-text">{{
            safeTranslate('CONVERSATION.VOICE_CALL.REJECT_CALL')
          }}</span>
        </button>

        <button
          class="control-button accept-call-button"
          :title="$t('CONVERSATION.VOICE_CALL.JOIN_CALL')"
          @click="acceptCall"
        >
          <span class="i-ph-phone" />
          <span class="button-text">{{
            safeTranslate('CONVERSATION.VOICE_CALL.JOIN_CALL')
          }}</span>
        </button>
      </template>

      <!-- Active Call Controls -->
      <template v-else>
        <button
          class="round-control-button"
          :class="{ active: isMuted }"
          @click="toggleMute"
        >
          <span
            :class="isMuted ? 'i-ph-microphone-slash' : 'i-ph-microphone'"
          />
        </button>

        <button class="round-control-button" @click="toggleCallOptions">
          <!-- Custom dots icon as fallback -->
          <div class="custom-dots-icon">
            <div class="dot" />
            <div class="dot" />
            <div class="dot" />
          </div>
        </button>

        <button
          class="round-control-button end-call-button"
          @click="handleEndCallClick"
        >
          <span class="i-ph-phone-x" />
        </button>
      </template>
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
        <div class="webrtc-status-content">
          <span
            class="status-dot"
            :class="{
              'dot-active':
                isWebRTCInitialized && twilioDeviceStatus === 'ready',
              'dot-busy': isWebRTCInitialized && twilioDeviceStatus === 'busy',
              'dot-error':
                !isWebRTCInitialized || twilioDeviceStatus === 'error',
            }"
          />

          <span class="status-text">
            Browser Call:
            {{
              twilioDeviceStatus === 'ready'
                ? 'Ready'
                : twilioDeviceStatus === 'busy'
                  ? 'Connected'
                  : twilioDeviceStatus === 'error'
                    ? 'Error'
                    : 'Initializing...'
            }}
          </span>

          <span class="divider">|</span>

          <span class="mic-status-icon">
            <span
              :class="
                isMuted
                  ? 'i-ph-microphone-slash text-xs'
                  : 'i-ph-microphone text-xs'
              "
            />
            {{ isMuted ? 'Muted' : 'Active' }}
          </span>
        </div>
      </div>
    </div>
  </div>

  <!-- Incoming Call Modal (simplified overlay version) -->
  <div v-if="isIncoming && !isCallActive" class="incoming-call-modal">
    <div class="incoming-call-container">
      <div class="incoming-call-header">
        <span class="inbox-name">
          <!-- Add inbox avatar to the header -->
          <img
            v-if="inboxAvatarUrl && inboxAvatarUrl.startsWith('http')"
            :src="inboxAvatarUrl"
            :alt="inboxDisplayName"
            class="inline-avatar"
            style="
              width: 24px;
              height: 24px;
              border-radius: 4px;
              margin-right: 6px;
            "
          />
          <!-- Fallback to phone icon for voice channels -->
          <i
            v-else
            class="i-ri-phone-fill text-white mr-1.5"
            style="
              width: 24px;
              height: 24px;
              font-size: 16px;
              display: flex;
              align-items: center;
              justify-content: center;
            "
          />
          {{ inboxDisplayName }}
        </span>
        <span class="incoming-call-text">Incoming call</span>
      </div>

      <div class="caller-info">
        <!-- Use a proper avatar image with initials fallback -->
        <div class="caller-avatar">
          <img
            v-if="contactAvatarUrl"
            :src="contactAvatarUrl"
            :alt="contactDisplayName"
            class="avatar-image"
            @error="handleAvatarError"
          />
          <span v-else class="avatar-initials">{{
            contactDisplayName.charAt(0).toUpperCase()
          }}</span>
        </div>
        <h2 class="caller-name">{{ contactDisplayName }}</h2>
        <p class="calling-status">is calling {{ inboxDisplayName }}</p>
      </div>

      <div class="incoming-call-actions">
        <button class="reject-button" @click="rejectCall">
          <span class="i-ph-phone-x" />
          <span>Decline</span>
        </button>

        <button class="accept-button" @click="acceptCall">
          <span class="i-ph-phone" />
          <span>Accept</span>
        </button>
      </div>

      <div class="incoming-call-note">
        Declining a call still allows others in the shared inbox to pick up
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.floating-call-widget {
  position: fixed;
  bottom: 20px;
  right: 20px;
  background-color: rgba(
    31,
    41,
    55,
    0.95
  ); /* var(--b-700, #1f2937) with opacity */
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

  &.has-keypad {
    height: auto;
    min-height: 460px;
  }

  &.has-call-options {
    height: auto;
    min-height: 500px;
  }
}

.call-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
  padding: 0 0 12px 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.inbox-avatar {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  background-color: #4263eb; // Chatwoot blue color instead of orange
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: 16px;
  color: white;
  margin-right: 10px;
  overflow: hidden;
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.2);
  position: relative;

  .avatar-image {
    width: 100%;
    height: 100%;
    object-fit: cover;
    position: absolute;
    top: 0;
    left: 0;
  }

  // When avatar fails to load, restore the initials display
  &.avatar-fallback {
    .avatar-image {
      display: none;
    }
  }
}

.header-info {
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.voice-label {
  font-size: 16px;
  font-weight: 600;
  color: white;
  line-height: 1.2;
}

.phone-number {
  font-size: 14px;
  color: var(--s-300, #9ca3af);
  line-height: 1.2;
}

.call-time {
  font-size: 16px;
  font-weight: 500;
  color: white;
  background-color: rgba(0, 0, 0, 0.35);
  padding: 6px 12px;
  border-radius: 20px;
}

.call-content {
  flex: 1;
  margin-bottom: 16px;
}

.participant-row {
  display: flex;
  justify-content: center;
  margin: 16px 0;
}

.participant {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;

  .avatar {
    width: 64px;
    height: 64px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 600;
    font-size: 22px;
    border: 2px solid rgba(255, 255, 255, 0.15);
    overflow: hidden;
    background-color: var(--b-500, #4b5563);
    position: relative;

    .avatar-image {
      width: 100%;
      height: 100%;
      object-fit: cover;
      object-position: center;
      position: absolute;
      top: 0;
      left: 0;
    }

    // When avatar fails to load, restore the initials display
    &.avatar-fallback {
      .avatar-image {
        display: none;
      }
    }
  }

  .name {
    font-size: 16px;
    font-weight: 600;
    max-width: 200px;
    text-overflow: ellipsis;
    overflow: hidden;
    white-space: nowrap;
    text-align: center;
  }

  .phone-number-detail {
    font-size: 14px;
    color: var(--s-400, #9ca3af);
    margin-top: 2px;
    margin-bottom: 4px;
  }

  .call-status {
    font-size: 12px;
    color: var(--s-300, #a3a3a3);
    padding: 3px 10px;
    border-radius: 10px;
    background-color: rgba(0, 0, 0, 0.2);
  }
}

.keypad-container {
  margin: 8px 0 16px;
  background-color: rgba(0, 0, 0, 0.15);
  border-radius: 8px;
  padding: 12px;
}

.keypad-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
}

.keypad-button {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 48px;
  background-color: rgba(55, 65, 81, 0.5);
  border-radius: 8px;
  border: none;
  cursor: pointer;
  transition: all 0.2s ease;
  color: white;

  &:hover {
    background-color: var(--b-500, #4b5563);
  }

  &:active {
    transform: scale(0.95);
  }

  .digit {
    font-size: 18px;
    font-weight: 600;
  }

  .subtext {
    font-size: 10px;
    color: var(--s-300, #9ca3af);
    margin-top: 2px;
  }
}

.call-options-menu {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin: 8px 0 16px;
  background-color: rgba(0, 0, 0, 0.15);
  border-radius: 8px;
  padding: 12px;
}

.option-button {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 12px;
  background-color: rgba(55, 65, 81, 0.5);
  border-radius: 8px;
  border: none;
  cursor: pointer;
  transition: all 0.2s ease;
  color: white;
  text-align: left;

  &:hover {
    background-color: var(--b-500, #4b5563);
  }

  &:active {
    transform: scale(0.98);
  }

  &.end-call {
    background-color: rgba(220, 38, 38, 0.8);

    &:hover {
      background-color: var(--r-600, #b91c1c);
    }
  }

  span:first-child {
    font-size: 18px;
  }
}

.call-controls {
  display: flex;
  gap: 12px;
  justify-content: center;
  margin-top: auto;
  padding-top: 12px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
}

.round-control-button {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 50px;
  height: 50px;
  border-radius: 50%;
  border: none;
  cursor: pointer;
  background: var(--b-600, #4f546a);
  color: white;
  font-size: 20px;
  transition: all 0.2s ease;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.1);

  // Add a slight inner border
  position: relative;

  &:after {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    border-radius: 50%;
    box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.1);
    pointer-events: none;
  }

  &:hover {
    background: var(--b-500, #5a5f77);
  }

  &:active {
    transform: scale(0.97);
  }

  &.active {
    background: var(--w-500, #2563eb);
  }

  &.end-call-button {
    background: var(--r-500, #eb4646);

    &:hover {
      background: var(--r-600, #d62b2b);
    }
  }

  // Make sure the icons are centered properly
  [class^='i-ph-'] {
    position: relative;
    top: 2px;
  }

  // Custom keypad icon (fallback)
  .custom-keypad-icon {
    display: flex;
    align-items: center;
    justify-content: center;

    .keypad-grid-icon {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      grid-template-rows: repeat(2, 1fr);
      gap: 3px;
      width: 16px;
      height: 16px;

      .keypad-dot {
        width: 6px;
        height: 6px;
        background-color: white;
        border-radius: 1px;
      }
    }
  }

  // Custom dots icon (fallback)
  .custom-dots-icon {
    display: flex;
    gap: 3px;

    .dot {
      width: 5px;
      height: 5px;
      background-color: white;
      border-radius: 50%;
    }
  }
}

.control-button {
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
  transition: all 0.2s ease;
}

.accept-call-button {
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

.reject-call-button {
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
  margin-left: 4px;
}

// WebRTC indicator styles
.webrtc-status {
  margin-top: 8px;
  padding-top: 8px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  display: flex;
  justify-content: center;
  width: 100%;
}

.webrtc-indicator {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  font-size: 12px;
  color: var(--s-300, #9ca3af);
  background-color: rgba(0, 0, 0, 0.3);
  border-radius: 12px;
  padding: 6px 10px;
}

.webrtc-status-content {
  display: flex;
  align-items: center;
  gap: 6px;
}

.status-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  flex-shrink: 0;

  &.dot-active {
    background-color: #34c759; // Green status
  }

  &.dot-busy {
    background-color: #5ac8fa; // Blue status
  }

  &.dot-error {
    background-color: #ff3b30; // Red status
  }
}

.status-text {
  font-weight: 500;
  color: #f3f3f3;
  white-space: nowrap;
}

.divider {
  color: rgba(255, 255, 255, 0.3);
  margin: 0 4px;
}

.mic-status-icon {
  display: flex;
  align-items: center;
  gap: 6px;
  white-space: nowrap;

  [class^='i-ph-'] {
    position: relative;
    top: 1px;
  }
}

// Incoming call modal
.incoming-call-modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.75);
  backdrop-filter: blur(5px);
  z-index: 10001;
  display: flex;
  align-items: center;
  justify-content: center;
  animation: fadeIn 0.3s ease;
}

.incoming-call-container {
  width: 100%;
  max-width: 380px;
  background-color: #121212;
  border-radius: 16px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  padding: 24px;
  display: flex;
  flex-direction: column;
  align-items: center;
  color: white;
}

.incoming-call-header {
  width: 100%;
  display: flex;
  justify-content: space-between;
  padding: 0 0 16px 0;
}

.inbox-name {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 16px;
  font-weight: 600;
  color: white;

  // We're now using the actual inbox avatar image instead of this pseudo-element
  // The before element is removed as it's no longer needed
}

.incoming-call-text {
  font-size: 14px;
  font-weight: 500;
  color: #a3a3a3;
}

.caller-info {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin: 16px 0 20px 0;
}

.caller-avatar {
  width: 120px;
  height: 120px;
  border-radius: 50%;
  background-color: #333;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 20px;
  border: 3px solid rgba(255, 255, 255, 0.15);
  overflow: hidden;
  position: relative;

  // Add a subtle shadow for depth
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);

  // Background pattern for fallback state
  background-image: radial-gradient(
    circle,
    rgba(255, 255, 255, 0.1) 1px,
    transparent 1px
  );
  background-size: 10px 10px;

  .avatar-image {
    width: 100%;
    height: 100%;
    object-fit: cover;
    object-position: center;
  }

  .avatar-initials {
    font-size: 42px;
    font-weight: 600;
    color: white;
  }
}

.caller-name {
  font-size: 24px;
  font-weight: 600;
  margin: 0 0 8px;
}

.calling-status {
  font-size: 16px;
  color: #a3a3a3;
  margin: 0;
}

.incoming-call-actions {
  display: flex;
  gap: 16px;
  width: 100%;
  margin-bottom: 16px;

  button {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    flex: 1;
    height: 50px;
    border-radius: 8px;
    border: none;
    cursor: pointer;
    font-size: 16px;
    font-weight: 600;
    transition: all 0.2s ease;

    span:first-child {
      font-size: 20px;
    }
  }

  .reject-button {
    background-color: #e64c38;
    color: white;

    &:hover {
      background-color: #d53c28;
    }

    &:active {
      transform: scale(0.98);
    }
  }

  .accept-button {
    background-color: #34c759;
    color: white;

    &:hover {
      background-color: #2bb550;
    }

    &:active {
      transform: scale(0.98);
    }
  }
}

.incoming-call-note {
  width: 100%;
  text-align: center;
  font-size: 13px;
  color: #8e8e8e;
  margin-top: 8px;
  line-height: 1.4;
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

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}
</style>
