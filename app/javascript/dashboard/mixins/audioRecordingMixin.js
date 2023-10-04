import { AUDIO_FORMATS } from 'shared/constants/messages';

export default {
  data() {
    return {
      isRecordingAudio: false,
      isRecorderAudioStopped: false,
      recordingAudioState: '',
      recordingAudioDurationText: '',
    };
  },
  computed: {
    audioRecordFormat() {
      if (this.isAWhatsAppChannel || this.isAPIInbox) {
        return AUDIO_FORMATS.OGG;
      }
      return AUDIO_FORMATS.WAV;
    },
    showAudioRecorder() {
      return !this.isOnPrivateNote && this.showFileUpload;
    },
    showAudioRecorderEditor() {
      return this.showAudioRecorder && this.isRecordingAudio;
    },
  },
  methods: {
    toggleAudioRecorder() {
      this.isRecordingAudio = !this.isRecordingAudio;
      this.isRecorderAudioStopped = !this.isRecordingAudio;
      if (!this.isRecordingAudio) {
        this.clearMessage();
        this.clearEmailField();
      }
    },
    toggleAudioRecorderPlayPause() {
      if (this.isRecordingAudio) {
        if (!this.isRecorderAudioStopped) {
          this.isRecorderAudioStopped = true;
          this.$refs.audioRecorderInput.stopAudioRecording();
        } else if (this.isRecorderAudioStopped) {
          this.$refs.audioRecorderInput.playPause();
        }
      }
    },
    onStateProgressRecorderChanged(duration) {
      this.recordingAudioDurationText = duration;
    },
    onStateRecorderChanged(state) {
      this.recordingAudioState = state;
      if (state && 'notallowederror'.includes(state)) {
        this.toggleAudioRecorder();
      }
    },
    onFinishRecorder(file) {
      return file && this.onFileUpload(file);
    },
  },
};
