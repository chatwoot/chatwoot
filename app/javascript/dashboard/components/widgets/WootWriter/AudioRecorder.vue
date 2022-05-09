<template>
  <div class="audio-wave-wrapper">
    <audio id="audio-wave" class="video-js vjs-fill vjs-default-skin"></audio>
  </div>
</template>

<script>
import 'video.js/dist/video-js.css';
import 'videojs-record/dist/css/videojs.record.css';

import videojs from 'video.js';

import inboxMixin from '../../../../shared/mixins/inboxMixin';
import alertMixin from '../../../../shared/mixins/alertMixin';

import Recorder from 'opus-recorder';
import encoderWorker from 'opus-recorder/dist/encoderWorker.min';

import WaveSurfer from 'wavesurfer.js';
import MicrophonePlugin from 'wavesurfer.js/dist/plugin/wavesurfer.microphone.js';
import 'videojs-wavesurfer/dist/videojs.wavesurfer.js';

import 'videojs-record/dist/videojs.record.js';
import 'videojs-record/dist/plugins/videojs.record.opus-recorder.js';
import { format, addSeconds } from 'date-fns';

WaveSurfer.microphone = MicrophonePlugin;

export default {
  name: 'WootAudioRecorder',
  mixins: [inboxMixin, alertMixin],
  data() {
    return {
      player: false,
      recordingDateStarted: new Date(0),
      initialTimeDuration: '00:00',
      recorderOptions: {
        debug: true,
        controls: true,
        bigPlayButton: false,
        fluid: false,
        controlBar: {
          deviceButton: false,
          fullscreenToggle: false,
          cameraButton: false,
          volumePanel: false,
        },
        plugins: {
          wavesurfer: {
            backend: 'WebAudio',
            waveColor: '#1f93ff',
            progressColor: 'rgb(25, 118, 204)',
            cursorColor: 'rgba(43, 51, 63, 0.7)',
            backgroundColor: 'none',
            barWidth: 1,
            cursorWidth: 1,
            hideScrollbar: true,
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
          record: {
            audio: true,
            video: false,
            displayMilliseconds: false,
            maxLength: 300,
            audioEngine: 'opus-recorder',
            audioWorkerURL: encoderWorker,
            audioChannels: 1,
            audioSampleRate: 48000,
            audioBitRate: 128,
          },
        },
      },
    };
  },
  computed: {
    isRecording() {
      return this.player && this.player.record().isRecording();
    },
  },
  mounted() {
    window.Recorder = Recorder;
    this.fireProgressRecord(this.initialTimeDuration);
    this.player = videojs('#audio-wave', this.recorderOptions, () => {
      this.$nextTick(() => {
        this.player.record().getDevice();
      });
    });
    this.player.on('deviceReady', this.deviceReady);
    this.player.on('deviceError', this.deviceError);
    this.player.on('startRecord', this.startRecord);
    this.player.on('stopRecord', this.stopRecord);
    this.player.on('progressRecord', this.progressRecord);
    this.player.on('finishRecord', this.finishRecord);
    this.player.on('playbackFinish', this.playbackFinish);
  },
  beforeDestroy() {
    if (this.player) {
      this.player.dispose();
    }
    if (window.Recorder) {
      window.Recorder = undefined;
    }
  },
  methods: {
    deviceReady() {
      this.player.record().start();
    },
    startRecord() {
      this.fireStateRecorderChanged('recording');
    },
    stopRecord() {
      this.fireStateRecorderChanged('stopped');
    },
    finishRecord() {
      const file = new File(
        [this.player.recordedData],
        this.player.recordedData.name,
        { type: this.player.recordedData.type }
      );
      this.fireRecorderBlob(file);
    },
    progressRecord() {
      this.fireProgressRecord(this.formatTimeProgress());
    },
    stopAudioRecording() {
      this.player.record().stop();
    },
    deviceError() {
      const deviceError = this.player.deviceErrorCode;
      const deviceErrorName = deviceError?.name.toLowerCase();
      if (
        deviceErrorName?.includes('notallowederror') ||
        deviceErrorName?.includes('permissiondeniederror')
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
    formatTimeProgress() {
      return format(
        addSeconds(
          new Date(this.recordingDateStarted.getTimezoneOffset() * 1000 * 60),
          this.player.record().getDuration()
        ),
        'mm:ss'
      );
    },
    playPause() {
      if (this.player.wavesurfer().surfer.isPlaying()) {
        this.fireStateRecorderChanged('paused');
      } else {
        this.fireStateRecorderChanged('playing');
      }
      this.player.wavesurfer().surfer.playPause();
    },
    play() {
      this.fireStateRecorderChanged('playing');
      this.player.wavesurfer().play();
    },
    pause() {
      this.fireStateRecorderChanged('paused');
      this.player.wavesurfer().pause();
    },
    playbackFinish() {
      this.fireStateRecorderChanged('paused');
      this.player.wavesurfer().pause();
    },
    fireRecorderBlob(blob) {
      this.$emit('finish-record', {
        name: blob.name,
        type: blob.type,
        size: blob.size,
        file: blob,
      });
    },
    fireStateRecorderChanged(state) {
      this.$emit('state-recorder-changed', state);
    },
    fireProgressRecord(duration) {
      this.$emit('state-recorder-progress-changed', duration);
    },
  },
};
</script>

<style lang="scss">
.audio-wave-wrapper {
  min-height: 8rem;
  height: 8rem;
}
.video-js .vjs-control-bar {
  background-color: transparent;
}
</style>
