<template>
  <div class="audio-wave-wrapper">
    <div id="audio-wave"></div>
  </div>
</template>

<script>
import WaveSurfer from 'wavesurfer.js';
import MicrophonePlugin from 'wavesurfer.js/dist/plugin/wavesurfer.microphone.js';
import RecordRTC from 'recordrtc';
import inboxMixin from '../../../../shared/mixins/inboxMixin';
import alertMixin from '../../../../shared/mixins/alertMixin';

WaveSurfer.microphone = MicrophonePlugin;

export default {
  name: 'WootAudioRecorder',
  mixins: [inboxMixin, alertMixin],
  data() {
    return {
      wavesurfer: false,
      recorder: false,
      recordingInterval: false,
      recordingDateStarted: new Date().getTime(),
      timeDuration: '00:00',
      initialTimeDuration: '00:00',
      options: {
        container: '#audio-wave',
        backend: 'WebAudio',
        interact: true,
        cursorWidth: 1,
        plugins: [
          WaveSurfer.microphone.create({
            bufferSize: 4096,
            numberOfInputChannels: 1,
            numberOfOutputChannels: 1,
            constraints: {
              video: false,
              audio: true,
            },
          }),
        ],
      },
      optionsRecorder: {
        type: 'audio',
        mimeType: 'audio/wav',
        disableLogs: true,
        recorderType: RecordRTC.StereoAudioRecorder,
        sampleRate: 44100,
        numberOfAudioChannels: 2,
        checkForInactiveTracks: true,
        bufferSize: 4096,
      },
    };
  },
  computed: {
    isRecording() {
      if (this.recorder) {
        return this.recorder.getState() === 'recording';
      }
      return false;
    },
  },
  mounted() {
    this.wavesurfer = WaveSurfer.create(this.options);
    this.wavesurfer.on('play', this.playingRecorder);
    this.wavesurfer.on('pause', this.pausedRecorder);
    this.wavesurfer.microphone.on('deviceReady', this.startRecording);
    this.wavesurfer.microphone.on('deviceError', this.deviceError);
    this.wavesurfer.microphone.start();
    this.fireStateRecorderTimerChanged(this.initialTimeDuration);
  },
  beforeDestroy() {
    if (this.recorder) {
      this.recorder.destroy();
    }
    if (this.wavesurfer) {
      this.wavesurfer.destroy();
    }
  },
  methods: {
    startRecording(stream) {
      this.recorder = RecordRTC(stream, this.optionsRecorder);
      this.recorder.onStateChanged = this.onStateRecorderChanged;
      this.recorder.startRecording();
    },
    stopAudioRecording() {
      if (this.isRecording) {
        this.recorder.stopRecording(() => {
          this.wavesurfer.microphone.stopDevice();
          this.wavesurfer.loadBlob(this.recorder.getBlob());
          this.wavesurfer.stop();
          this.fireRecorderBlob(this.getAudioFile());
        });
      }
    },
    getAudioFile() {
      if (this.hasAudio()) {
        return new File([this.recorder.getBlob()], this.getAudioFileName(), {
          type: 'audio/wav',
        });
      }
      return false;
    },
    hasAudio() {
      return !(this.isRecording || this.wavesurfer.isPlaying());
    },
    playingRecorder() {
      this.fireStateRecorderChanged('playing');
    },
    pausedRecorder() {
      this.fireStateRecorderChanged('paused');
    },
    deviceError(err) {
      if (
        err?.name &&
        (err.name.toLowerCase().includes('notallowederror') ||
          err.name.toLowerCase().includes('permissiondeniederror'))
      ) {
        this.showAlert(
          this.$t('CONVERSATION.REPLYBOX.TIP_AUDIORECORDER_PERMISSION')
        );
        this.fireStateRecorderChanged('notallowederror');
      } else {
        this.showAlert(
          this.$t('CONVERSATION.REPLYBOX.TIP_AUDIORECORDER_ERROR')
        );
      }
    },
    onStateRecorderChanged(state) {
      // recording stopped inactive destroyed
      switch (state) {
        case 'recording':
          this.timerDurationChanged();
          break;
        case 'stopped':
          this.timerDurationChanged();
          break;
        default:
          break;
      }
      this.fireStateRecorderChanged(state);
    },
    timerDurationChanged() {
      if (this.isRecording) {
        this.recordingInterval = setInterval(() => {
          this.calculateTimeDuration(
            (new Date().getTime() - this.recordingDateStarted) / 1000
          );
          this.fireStateRecorderTimerChanged(this.timeDuration);
        }, 1000);
      } else {
        clearInterval(this.recordingInterval);
      }
    },
    calculateTimeDuration(secs) {
      let hr = Math.floor(secs / 3600);
      let min = Math.floor((secs - hr * 3600) / 60);
      let sec = Math.floor(secs - hr * 3600 - min * 60);
      if (min < 10) {
        min = '0' + min;
      }
      if (sec < 10) {
        sec = '0' + sec;
      }
      if (hr <= 0) {
        this.timeDuration = min + ':' + sec;
      } else {
        if (hr < 10) {
          hr = '0' + hr;
        }
        this.timeDuration = hr + ':' + min + ':' + sec;
      }
    },
    playPause() {
      this.wavesurfer.playPause();
    },
    fireRecorderBlob(blob) {
      this.$emit('recorder-blob', {
        name: blob.name,
        type: blob.type,
        size: blob.size,
        file: blob,
      });
    },
    fireStateRecorderChanged(state) {
      this.$emit('state-recorder-changed', state);
    },
    fireStateRecorderTimerChanged(duration) {
      this.$emit('state-recorder-timer-changed', duration);
    },
    getAudioFileName() {
      const d = new Date();
      return `audio-${d.getFullYear()}-${d.getMonth()}-${d.getDate()}-${this.getRandomString()}.wav`;
    },
    getRandomString() {
      if (
        window.crypto &&
        window.crypto.getRandomValues &&
        navigator.userAgent.indexOf('Safari') === -1
      ) {
        let a = window.crypto.getRandomValues(new Uint32Array(3));
        let token = '';
        for (let i = 0, l = a.length; i < l; i += 1) {
          token += a[i].toString(36);
        }
        return token.toLowerCase();
      }
      return (Math.random() * new Date().getTime())
        .toString(36)
        .replace(/\./g, '');
    },
  },
};
</script>

<style lang="scss">
.audio-wave-wrapper {
  min-height: 8rem;
  max-height: 12rem;
  overflow: hidden;
}
</style>
