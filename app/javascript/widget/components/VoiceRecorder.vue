<script>
import { mapGetters } from 'vuex';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import Spinner from 'shared/components/Spinner.vue';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { MAXIMUM_FILE_UPLOAD_SIZE } from 'shared/constants/messages';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { DirectUpload } from 'activestorage';

export default {
  components: { FluentIcon, Spinner },
  props: {
    onAttach: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return {
      isRecording: false,
      isUploading: false,
      mediaRecorder: null,
      audioChunks: [],
      recordingTime: 0,
      timerInterval: null,
    };
  },
  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
    formattedTime() {
      const minutes = Math.floor(this.recordingTime / 60);
      const seconds = this.recordingTime % 60;
      return `${minutes}:${seconds.toString().padStart(2, '0')}`;
    },
  },
  methods: {
    async startRecording() {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({
          audio: true,
        });
        this.mediaRecorder = new MediaRecorder(stream);
        this.audioChunks = [];

        this.mediaRecorder.ondataavailable = event => {
          this.audioChunks.push(event.data);
        };

        this.mediaRecorder.onstop = async () => {
          const audioBlob = new Blob(this.audioChunks, { type: 'audio/mp3' });
          await this.uploadRecording(audioBlob);
        };

        this.mediaRecorder.start();
        this.isRecording = true;
        this.recordingTime = 0;
        this.timerInterval = setInterval(() => {
          this.recordingTime += 1;
        }, 1000);
      } catch (error) {
        emitter.emit(BUS_EVENTS.SHOW_ALERT, {
          message: this.$t('VOICE_RECORDING_ERROR'),
        });
      }
    },

    stopRecording() {
      if (this.mediaRecorder && this.isRecording) {
        this.mediaRecorder.stop();
        this.isRecording = false;
        clearInterval(this.timerInterval);

        // Stop all audio tracks
        this.mediaRecorder.stream.getTracks().forEach(track => track.stop());
      }
    },

    async uploadRecording(audioBlob) {
      this.isUploading = true;
      try {
        const file = new File([audioBlob], 'voice-message.mp3', {
          type: 'audio/mp3',
        });

        if (checkFileSizeLimit(file, MAXIMUM_FILE_UPLOAD_SIZE)) {
          if (this.globalConfig.directUploadsEnabled) {
            await this.onDirectFileUpload(file);
          } else {
            await this.onIndirectFileUpload(file);
          }
        } else {
          emitter.emit(BUS_EVENTS.SHOW_ALERT, {
            message: this.$t('FILE_SIZE_LIMIT', {
              MAXIMUM_FILE_UPLOAD_SIZE: MAXIMUM_FILE_UPLOAD_SIZE,
            }),
          });
        }
      } catch (error) {
        emitter.emit(BUS_EVENTS.SHOW_ALERT, {
          message: this.$t('UPLOAD_ERROR'),
        });
      }
      this.isUploading = false;
    },

    async onDirectFileUpload(file) {
      const { websiteToken } = window.chatwootWebChannel;
      const upload = new DirectUpload(
        file,
        `/api/v1/widget/direct_uploads?website_token=${websiteToken}`,
        {
          directUploadWillCreateBlobWithXHR: xhr => {
            xhr.setRequestHeader('X-Auth-Token', window.authToken);
          },
        }
      );

      upload.create((error, blob) => {
        if (error) {
          emitter.emit(BUS_EVENTS.SHOW_ALERT, {
            message: error,
          });
        } else {
          this.onAttach({
            file: blob.signed_id,
            thumbUrl: window.URL.createObjectURL(file),
            fileType: 'file',
          });
        }
      });
    },

    async onIndirectFileUpload(file) {
      await this.onAttach({
        file: file,
        thumbUrl: window.URL.createObjectURL(file),
        fileType: 'file',
      });
    },
  },
};
</script>

<template>
  <div class="voice-recorder">
    <button
      class="flex items-center justify-center min-h-8 min-w-8"
      :class="{ recording: isRecording }"
      @click="isRecording ? stopRecording() : startRecording()"
    >
      <FluentIcon
        v-if="!isRecording && !isUploading"
        icon="microphone"
        class="text-n-slate-12"
      />
      <FluentIcon v-if="isRecording" icon="send" class="text-red-500" />
      <Spinner v-if="isUploading" size="small" />
    </button>
    <span v-if="isRecording" class="recording-time">
      {{ formattedTime }}
    </span>
  </div>
</template>

<style lang="scss" scoped>
.voice-recorder {
  display: flex;
  align-items: center;
  gap: 0.5rem;

  .recording-time {
    font-size: 0.875rem;
    color: #ef4444;
  }

  button.recording {
    background-color: rgba(239, 68, 68, 0.1);
  }
}
</style>
