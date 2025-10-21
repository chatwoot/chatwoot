<script>
import { mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import CallIcon from './CallIcon.vue';
import DismissCallIcon from './DismissCallIcon.vue';
import VideoAddIcon from './VideoAddIcon.vue';
import DismissIcon from './DismissIcon.vue';
import MicrophoneOnIcon from './MicrophoneOnIcon.vue';
import MicrophoneOffIcon from './MicrophoneOffIcon.vue';

export default {
  name: 'CallDialog',
  components: {
    CallIcon,
    DismissCallIcon,
    VideoAddIcon,
    DismissIcon,
    MicrophoneOnIcon,
    MicrophoneOffIcon,
  },
  emits: ['startCall', 'endCall'],
  data() {
    return {
      callType: 'voice',
      isStartingCall: false,
      isCallActive: false,
      isMicrophoneOn: true,
      isRecording: false,
      audioWaves: [0.2, 0.4, 0.6, 0.3, 0.8, 0.5, 0.7, 0.2, 0.9, 0.4],
      audioContext: null,
      analyser: null,
      microphone: null,
      mediaStream: null,
      dataArray: null,
      animationFrame: null,
      notificationMessage: '',
      showNotification: false,
    };
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
  },
  beforeUnmount() {
    // Clean up resources when component is destroyed
    this.stopRecording();
  },
  methods: {
    selectCallType(type) {
      this.callType = type;
    },
    async startCall() {
      this.isStartingCall = true;
      try {
        // Emit the call start event with the selected call type
        this.$emit('startCall', { type: this.callType });

        // Simulate call initiation delay
        await new Promise(resolve => {
          setTimeout(resolve, 1000);
        });

        // Keep dialog open to show active call state
        this.isCallActive = true;

        // Show call started notification
        this.showVoiceNotification(this.$t('CALL_STARTED'));

        // Start recording for voice calls
        if (this.callType === 'voice') {
          this.startRecording();
        }
      } catch (error) {
        // Handle call start error silently
      } finally {
        this.isStartingCall = false;
      }
    },
    endCall() {
      this.isCallActive = false;
      this.stopRecording();
      this.isMicrophoneOn = true;

      // Show call ended notification
      this.showVoiceNotification(this.$t('CALL_ENDED'));

      this.$emit('endCall');

      // Reset to initial state without closing dialog
      // User can manually close or start a new call
    },
    async toggleMicrophone() {
      this.isMicrophoneOn = !this.isMicrophoneOn;
      if (this.isMicrophoneOn) {
        this.showVoiceNotification(this.$t('MICROPHONE_ENABLED'));
        await this.startRecording();
      } else {
        this.showVoiceNotification(this.$t('MICROPHONE_DISABLED'));
        this.stopRecording();
      }
    },
    async startRecording() {
      try {
        this.isRecording = true;

        // Initialize Web Audio API
        this.audioContext = new (window.AudioContext ||
          window.webkitAudioContext)();

        // Get microphone access
        this.mediaStream = await navigator.mediaDevices.getUserMedia({
          audio: {
            echoCancellation: true,
            noiseSuppression: true,
            autoGainControl: true,
          },
        });

        this.microphone = this.audioContext.createMediaStreamSource(
          this.mediaStream
        );
        this.analyser = this.audioContext.createAnalyser();

        // Configure analyser for better frequency resolution
        this.analyser.fftSize = 256;
        this.analyser.smoothingTimeConstant = 0.8;

        const bufferLength = this.analyser.frequencyBinCount;
        this.dataArray = new Uint8Array(bufferLength);

        // Connect microphone to analyser
        this.microphone.connect(this.analyser);

        // Start real-time wave animation
        this.animateWaves();

        // Show recording started notification
        this.showVoiceNotification(this.$t('RECORDING_STARTED'));
      } catch (error) {
        // Handle microphone access error
        this.isRecording = false;
        this.isMicrophoneOn = false;
        this.showVoiceNotification(this.$t('MICROPHONE_ACCESS_DENIED'));
        // Fallback to simulated waves if microphone access fails
        this.animateWaves();
      }
    },
    stopRecording() {
      const wasRecording = this.isRecording;
      this.isRecording = false;

      // Clean up Web Audio API resources
      if (this.animationFrame) {
        cancelAnimationFrame(this.animationFrame);
        this.animationFrame = null;
      }

      if (this.microphone) {
        this.microphone.disconnect();
        this.microphone = null;
      }

      // Stop all media stream tracks to properly close microphone
      if (this.mediaStream) {
        this.mediaStream.getTracks().forEach(track => {
          track.stop();
        });
        this.mediaStream = null;
      }

      if (this.audioContext && this.audioContext.state !== 'closed') {
        this.audioContext.close();
        this.audioContext = null;
      }

      // Reset waves to minimal state
      this.audioWaves = this.audioWaves.map(() => 0.1);

      // Show recording stopped notification if it was recording
      if (wasRecording) {
        this.showVoiceNotification(this.$t('RECORDING_STOPPED'));
      }
    },
    animateWaves() {
      if (!this.isRecording) return;

      if (this.analyser && this.dataArray) {
        // Get real-time frequency data
        this.analyser.getByteFrequencyData(this.dataArray);

        // Process frequency data into wave heights
        const waveCount = this.audioWaves.length;
        const binSize = Math.floor(this.dataArray.length / waveCount);

        this.audioWaves = this.audioWaves.map((_, index) => {
          // Get average amplitude for this frequency range
          let sum = 0;
          const startBin = index * binSize;
          const endBin = Math.min(startBin + binSize, this.dataArray.length);

          for (let i = startBin; i < endBin; i += 1) {
            sum += this.dataArray[i];
          }

          const average = sum / (endBin - startBin);
          // Normalize to 0-1 range and add minimum height
          return Math.max(0.1, (average / 255) * 0.9);
        });
      } else {
        // Fallback to simulated waves if no microphone access
        this.audioWaves = this.audioWaves.map(() => Math.random() * 0.6 + 0.2);
      }

      // Continue animation
      this.animationFrame = requestAnimationFrame(() => {
        if (this.isRecording) {
          this.animateWaves();
        }
      });
    },
    open() {
      this.$refs.dialogRef.showModal();
    },
    close() {
      this.$refs.dialogRef.close();
    },
    handleBackdropClick(event) {
      if (event.target === event.currentTarget) {
        this.close();
      }
    },
    showVoiceNotification(message) {
      this.notificationMessage = message;
      this.showNotification = true;

      // Play notification sound
      this.playNotificationSound();

      // Hide notification after 3 seconds
      setTimeout(() => {
        this.showNotification = false;
      }, 3000);
    },
    playNotificationSound() {
      try {
        // Create a simple notification beep using Web Audio API
        const audioContext = new (window.AudioContext ||
          window.webkitAudioContext)();
        const oscillator = audioContext.createOscillator();
        const gainNode = audioContext.createGain();

        oscillator.connect(gainNode);
        gainNode.connect(audioContext.destination);

        // Configure notification tone
        oscillator.frequency.setValueAtTime(800, audioContext.currentTime);
        oscillator.type = 'sine';

        // Configure volume envelope
        gainNode.gain.setValueAtTime(0, audioContext.currentTime);
        gainNode.gain.linearRampToValueAtTime(
          0.1,
          audioContext.currentTime + 0.01
        );
        gainNode.gain.exponentialRampToValueAtTime(
          0.001,
          audioContext.currentTime + 0.3
        );

        // Play the sound
        oscillator.start(audioContext.currentTime);
        oscillator.stop(audioContext.currentTime + 0.3);

        // Clean up
        setTimeout(() => {
          audioContext.close();
        }, 500);
      } catch (error) {
        // Silently handle notification sound error
      }
    },
  },
  expose: ['open', 'close'],
};
</script>

<template>
  <dialog
    ref="dialogRef"
    class="transition-all duration-300 ease-in-out shadow-xl rounded-xl overflow-visible mx-3 my-8"
    :class="[
      isCallActive && callType === 'voice'
        ? 'w-[96%] max-w-lg'
        : 'w-[96%] max-w-md',
    ]"
    @close="close"
  >
    <div
      class="call-dialog bg-white rounded-lg shadow-lg p-6 w-full"
      @click.stop
    >
      <!-- Header -->
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-gray-900">
          {{ isCallActive ? $t('CALL_IN_PROGRESS') : $t('START_LIVE_CALL') }}
        </h3>
        <button
          class="text-gray-500 hover:text-gray-700 transition-colors"
          @click="close"
        >
          <DismissIcon size="20" />
        </button>
      </div>

      <!-- Call Type Selection (only show when not in active call) -->
      <div v-if="!isCallActive" class="mb-6">
        <p class="text-sm text-gray-600 mb-3">
          {{ $t('SELECT_CALL_TYPE') }}
        </p>
        <div class="grid grid-cols-2 gap-3">
          <!-- Voice Call Option -->
          <button
            class="call-type-option"
            :class="{
              selected: callType === 'voice',
              'border-2': callType === 'voice',
            }"
            :style="callType === 'voice' ? { borderColor: widgetColor } : {}"
            @click="selectCallType('voice')"
          >
            <CallIcon size="24" class="mb-2" />
            <span class="text-sm font-medium">{{ $t('VOICE_CALL') }}</span>
          </button>

          <!-- Video Call Option -->
          <button
            class="call-type-option"
            :class="{
              selected: callType === 'video',
              'border-2': callType === 'video',
            }"
            :style="callType === 'video' ? { borderColor: widgetColor } : {}"
            @click="selectCallType('video')"
          >
            <VideoAddIcon size="24" class="mb-2" />
            <span class="text-sm font-medium">{{ $t('VIDEO_CALL') }}</span>
          </button>
        </div>
      </div>

      <!-- Active Call Display -->
      <div v-if="isCallActive" class="mb-6 text-center">
        <div class="flex flex-col items-center justify-center py-8">
          <div class="mb-4 p-4 rounded-full bg-green-100">
            <CallIcon v-if="callType === 'voice'" size="32" color="#10b981" />
            <VideoAddIcon v-else size="32" color="#10b981" />
          </div>
          <p class="text-lg font-medium text-gray-900 mb-2">
            {{
              callType === 'voice'
                ? $t('VOICE_CALL_ACTIVE')
                : $t('VIDEO_CALL_ACTIVE')
            }}
          </p>
          <p class="text-sm text-gray-600 mb-6">
            {{ $t('CALL_CONNECTED') }}
          </p>

          <!-- Audio Wave Visualization for Voice Calls -->
          <div v-if="callType === 'voice'" class="mb-6">
            <div class="flex items-center justify-center gap-1 h-16 mb-4">
              <div
                v-for="(wave, index) in audioWaves"
                :key="index"
                :class="`bg-green-500 rounded-full w-1 transition-all duration-150 ease-in-out ${isRecording ? '' : 'opacity-30'}`"
                :style="{
                  height: isRecording ? `${wave * 40 + 8}px` : '8px',
                  animationDelay: `${index * 50}ms`,
                }"
              />
            </div>

            <!-- Microphone Controls -->
            <div class="flex items-center justify-center gap-4">
              <button
                class="p-3 rounded-full transition-all duration-200 hover:scale-105"
                :class="
                  isMicrophoneOn
                    ? 'bg-green-100 hover:bg-green-200'
                    : 'bg-red-100 hover:bg-red-200'
                "
                @click="toggleMicrophone"
              >
                <MicrophoneOnIcon
                  v-if="isMicrophoneOn"
                  size="24"
                  color="#10b981"
                />
                <MicrophoneOffIcon v-else size="24" color="#ef4444" />
              </button>
              <div class="text-center">
                <p class="text-xs text-gray-500 mb-1">
                  {{
                    isMicrophoneOn ? $t('MICROPHONE_ON') : $t('MICROPHONE_OFF')
                  }}
                </p>
                <p class="text-xs text-gray-400">
                  {{ isRecording ? $t('RECORDING') : $t('MUTED') }}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Voice Notification Banner -->
      <div
        v-if="showNotification"
        class="mb-4 p-3 bg-blue-50 border border-blue-200 rounded-lg transition-all duration-300 ease-in-out"
      >
        <div class="flex items-center justify-center">
          <div class="flex items-center gap-2">
            <div class="w-2 h-2 bg-blue-500 rounded-full animate-pulse" />
            <p class="text-sm font-medium text-blue-800">
              {{ notificationMessage }}
            </p>
          </div>
        </div>
      </div>

      <!-- Action Buttons -->
      <div class="flex gap-3">
        <!-- Cancel/Close Button -->
        <button
          v-if="!isCallActive"
          class="flex-1 px-4 py-2 text-sm font-medium text-gray-600 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors"
          @click="close"
        >
          {{ $t('CANCEL') }}
        </button>

        <!-- Start Call Button (when not active) -->
        <button
          v-if="!isCallActive"
          class="flex-1 px-4 py-2 text-sm font-medium rounded-lg transition-colors flex items-center justify-center gap-2"
          :style="{
            backgroundColor: widgetColor,
            color: textColor,
          }"
          :disabled="isStartingCall"
          @click="startCall"
        >
          <CallIcon v-if="!isStartingCall && callType === 'voice'" size="16" />
          <VideoAddIcon
            v-if="!isStartingCall && callType === 'video'"
            size="16"
          />
          <div
            v-if="isStartingCall"
            class="animate-spin rounded-full h-4 w-4 border-2 border-current border-t-transparent"
          />
          {{ isStartingCall ? $t('STARTING_CALL') : $t('START_CALL') }}
        </button>

        <!-- End Call Button (when active) -->
        <button
          v-if="isCallActive"
          class="w-full px-4 py-3 text-sm font-medium bg-red-600 hover:bg-red-700 text-white rounded-lg transition-colors flex items-center justify-center gap-2"
          @click="endCall"
        >
          <DismissCallIcon size="16" color="white" />
          {{ $t('END_CALL') }}
        </button>
      </div>
    </div>
  </dialog>
</template>

<style scoped lang="scss">
dialog::backdrop {
  background-color: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
}

.call-type-option {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 1rem;
  border-radius: 0.5rem;
  border: 1px solid #e2e8f0;
  background-color: #f8fafc;
  transition: all 0.2s;
  cursor: pointer;

  &:hover {
    border-color: #cbd5e1;
    background-color: #f1f5f9;
  }

  &.selected {
    background-color: #f1f5f9;
  }
}

.call-dialog {
  animation: slideIn 0.2s ease-out;
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
