<script>
import { computed, ref, onMounted, onBeforeUnmount } from 'vue';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import VoiceAPI from 'dashboard/api/channels/voice';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { useAccount } from 'dashboard/composables/useAccount';
import actionCableService from 'dashboard/helper/actionCable';

export default {
  name: 'CallManager',
  components: {
    NextButton,
  },
  props: {
    conversation: {
      type: Object,
      default: null,
    },
  },
  emits: ['callEnded'],
  setup(props, { emit }) {
    const store = useStore();
    const { accountId } = useAccount();
    const callStatus = ref('');
    const callSid = ref('');
    const callDuration = ref(0);
    const recordingUrl = ref('');
    const transcription = ref('');
    const durationTimer = ref(null);
    const isCallActive = computed(
      () => callStatus.value && 
            !['completed', 'ended', 'missed', 'failed', 'busy', 'no-answer'].includes(callStatus.value)
    );

    const callStatusText = computed(() => {
      switch (callStatus.value) {
        case 'queued':
          return 'Call queued';
        case 'ringing':
          return 'Phone ringing...';
        case 'in-progress':
          return 'Call in progress';
        case 'completed':
          return 'Call completed';
        case 'failed':
          return 'Call failed';
        case 'busy':
          return 'Phone was busy';
        case 'no-answer':
          return 'No answer';
        default:
          return 'Call initiated';
      }
    });

    const formattedCallDuration = computed(() => {
      const minutes = Math.floor(callDuration.value / 60);
      const seconds = callDuration.value % 60;
      return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    });

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

    const updateCallStatus = status => {
      callStatus.value = status;

      // Log the status update to help with debugging
      console.log(`CallManager: Updating call status to ${status}`);

      if (status === 'in-progress' || status === 'in_progress') {
        startDurationTimer();
      } else if (
        ['completed', 'ended', 'missed', 'failed', 'busy', 'no-answer', 'no_answer'].includes(status)
      ) {
        console.log(`CallManager: Call ended with status ${status}`);
        stopDurationTimer();
        emit('callEnded');
        
        // Forcefully hide the call widget after a short delay
        setTimeout(() => {
          if (window.app && window.app.$data) {
            window.app.$data.showCallWidget = false;
          }
        }, 2000);
      }
    };

    const endCall = async () => {
      if (!callSid.value) return;

      try {
        await VoiceAPI.endCall(callSid.value, props.conversation.id);
        updateCallStatus('completed');
        useAlert('Call ended', 'success');
      } catch (error) {
        useAlert('Failed to end call. Please try again.', 'error');
      }
    };

    const setupCall = () => {
      // If there's an active conversation, check for call details
      if (props.conversation) {
        const messages = props.conversation.messages || [];

        // Find the most recent call activity message
        const callMessage = messages.find(
          message =>
            message.message_type === 10 && // activity message
            message.additional_attributes?.call_sid
        );

        if (callMessage) {
          const attrs = callMessage.additional_attributes;
          callSid.value = attrs.call_sid;
          updateCallStatus(attrs.status || 'initiated');

          if (attrs.recording_url) {
            recordingUrl.value = attrs.recording_url;
          }

          // Find transcription if available
          const transcriptionMessage = messages.find(
            message =>
              message.message_type === 0 && // incoming message
              message.additional_attributes?.is_transcription
          );

          if (transcriptionMessage) {
            transcription.value = transcriptionMessage.content;
          }
        }
      }
    };

    // Setup WebSocket listener for call status updates
    const setupWebSocket = () => {
      if (!props.conversation) return;

      try {
        // The actionCable events are already set up in App.vue
        // We don't need to create or add any rooms - we'll just watch the calls store
        
        // Set up watch on the calls store to react to status changes
        const callStateUnwatch = store.watch(
          state => state.calls?.activeCall?.status,
          newStatus => {
            if (newStatus && callSid.value) {
              console.log(`Call status changed in store: ${newStatus}`);
              updateCallStatus(newStatus);
              
              // If call is completed, refresh the conversation to get any recordings
              if (newStatus === 'completed' || newStatus === 'canceled' || newStatus === 'missed') {
                // Notify parent component that call has ended
                emit('callEnded');
                
                // Refresh the conversation to get updated messages with recordings
                if (props.conversation?.id) {
                  store.dispatch('fetchConversation', {
                    id: props.conversation.id,
                  });
                }
              }
            }
          }
        );
        
        // Clean up the watcher when component is unmounted
        onBeforeUnmount(() => {
          if (callStateUnwatch) {
            callStateUnwatch();
          }
        });
      } catch (error) {
        console.error('Error setting up call status watcher:', error);
      }
      
      try {  
        // Set up message watcher to update UI elements related to recordings and transcriptions
        if (store.state.conversations && store.state.conversations.conversations) {
          const messageUnwatch = store.watch(
            state => {
              if (!props.conversation || !props.conversation.id) return null;
              const conversations = state.conversations?.conversations || {};
              const conv = conversations[props.conversation.id];
              return conv ? conv.messages : null;
            },
            messages => {
              if (!messages) return;

              try {
                // Check for recording URL updates in call messages
                const callMessage = messages.find(
                  message =>
                    message.content_type === 'voice_call' &&
                    message.content_attributes?.data?.call_sid === callSid.value
                );

                if (callMessage?.content_attributes?.data) {
                  // Update UI if recording URL is available
                  if (callMessage.content_attributes.data.recording_url) {
                    recordingUrl.value = callMessage.content_attributes.data.recording_url;
                  }
                }

                // Check for transcription messages
                const transcriptionMessage = messages.find(
                  message =>
                    message.message_type === 0 && // incoming message
                    message.additional_attributes?.is_transcription
                );

                if (transcriptionMessage) {
                  transcription.value = transcriptionMessage.content;
                }
              } catch (err) {
                console.error('Error processing message updates:', err);
              }
            }
          );

          // Clean up the watcher when component is unmounted
          onBeforeUnmount(() => {
            if (messageUnwatch) {
              messageUnwatch();
            }
          });
        } else {
          console.warn('Conversations store not found or initialized');
        }
      } catch (error) {
        console.error('Error setting up message watcher:', error);
      }
    };

    onMounted(() => {
      // Wrap in try/catch to prevent Vue errors if there's an issue
      try {
        if (props.conversation && props.conversation.id) {
          // Proceed with setup, using props.conversation.messages or default inside setupCall
          setupCall();
          setupWebSocket();
        }
      } catch (error) {
        console.error('Error in CallManager mounted:', error);
      }
    });

    onBeforeUnmount(() => {
      stopDurationTimer();
      // No need to clean up ActionCable connection as we're not using room-specific subscriptions
    });

    return {
      callStatus,
      callStatusText,
      isCallActive,
      recordingUrl,
      transcription,
      callDuration,
      formattedCallDuration,
      endCall,
    };
  },
};
</script>

<template>
  <div
    v-show="callStatus"
    v-if="callStatus"
    class="relative p-4 mb-4 border border-solid rounded-md bg-n-slate-1 border-n-slate-4 flex flex-col gap-2"
  >
    <div class="flex items-center justify-between">
      <div class="flex items-center gap-2">
        <span class="text-red-600 animate-pulse i-ph-phone-call text-xl" />
        <h3 class="mb-0 text-base font-medium">{{ callStatusText }}</h3>
      </div>
      <div class="flex items-center gap-2">
        <div v-if="callDuration" class="text-sm text-n-slate-9">
          {{ formattedCallDuration }}
        </div>
        <NextButton
          v-tooltip.top-end="$t('CONVERSATION.END_CALL')"
          icon="i-ph-phone-x"
          sm
          ruby
          @click.stop.prevent="endCall"
        />
      </div>
    </div>
    <div v-if="recordingUrl" class="w-full mt-2">
      <audio controls class="w-full h-10">
        <source :src="recordingUrl" type="audio/mpeg" />
        {{ $t('CONVERSATION.AUDIO_NOT_SUPPORTED') }}
      </audio>
    </div>
    <div
      v-if="transcription"
      class="mt-2 p-2 border border-solid rounded bg-n-slate-2 border-n-slate-5 text-sm"
    >
      <h4 class="mb-1 text-xs font-semibold text-n-slate-10">
        {{ $t('CONVERSATION.TRANSCRIPTION') }}
      </h4>
      <p class="m-0">{{ transcription }}</p>
    </div>
  </div>
</template>
