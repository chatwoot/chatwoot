<template>
  <div class="audio-wave-wrapper">
    <audio id="audio-wave" class="video-js vjs-fill vjs-default-skin" />
  </div>
</template>

<script>
import getUuid from 'widget/helpers/uuid';
import 'video.js/dist/video-js.css';
import 'videojs-record/dist/css/videojs.record.css';

import videojs from 'video.js';

import { useAlert } from 'dashboard/composables';

import Recorder from 'opus-recorder';

// Workers to record Audio .ogg and .wav
import encoderWorker from 'opus-recorder/dist/encoderWorker.min';
import waveWorker from 'opus-recorder/dist/waveWorker.min';

import WaveSurfer from 'wavesurfer.js';
import MicrophonePlugin from 'wavesurfer.js/dist/plugin/wavesurfer.microphone.js';

import 'videojs-wavesurfer/dist/videojs.wavesurfer.js';
import 'videojs-record/dist/videojs.record.js';

import OpusRecorderEngine from 'videojs-record/dist/plugins/videojs.record.opus-recorder.js';

import { format, addSeconds } from 'date-fns';
import { AUDIO_FORMATS } from 'shared/constants/messages';
import { convertWavToMp3 } from './utils/mp3ConversionUtils';

WaveSurfer.microphone = MicrophonePlugin;

const RECORDER_CONFIG = {
  [AUDIO_FORMATS.WAV]: {
    audioMimeType: 'audio/wav',
    audioWorkerURL: waveWorker,
  },
  [AUDIO_FORMATS.MP3]: {
    audioMimeType: 'audio/wav',
    audioWorkerURL: waveWorker,
  },
  [AUDIO_FORMATS.OGG]: {
    audioMimeType: 'audio/ogg',
    audioWorkerURL: encoderWorker,
  },
};

export default {
  name: 'WootAudioRecorder',
  props: {
    audioRecordFormat: {
      type: String,
      default: AUDIO_FORMATS.WAV,
    },
    isAWhatsAppChannel: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      player: false,
      recordingDateStarted: new Date(0),
      initialTimeDuration: '00:00',
      recorderOptions: {
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
            maxLength: 900,
            timeSlice: 1000,
            maxFileSize: 15 * 1024 * 1024,
            displayMilliseconds: false,
            audioChannels: 1,
            audioSampleRate: 48000,
            audioBitRate: 128,
            audioEngine: 'opus-recorder',
            ...RECORDER_CONFIG[this.audioRecordFormat],
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
      if (this.player.record().engine instanceof OpusRecorderEngine) {
        if (
          [AUDIO_FORMATS.WAV, AUDIO_FORMATS.MP3].includes(
            this.audioRecordFormat
          )
        ) {
          this.player.record().engine.audioType = 'audio/wav';
        }
      }
      this.player.record().start();
    },
    startRecord() {
      this.fireStateRecorderChanged('recording');
    },
    stopRecord() {
      this.fireStateRecorderChanged('stopped');
    },
    async finishRecord() {
      let recordedContent = this.player.recordedData;
      let fileName = this.player.recordedData.name;
      let type = this.player.recordedData.type;
      if (this.audioRecordFormat === AUDIO_FORMATS.MP3) {
        recordedContent = await convertWavToMp3(this.player.recordedData);
        fileName = `${getUuid()}.mp3`;
        type = AUDIO_FORMATS.MP3;
      }
      const file = new File([recordedContent], fileName, { type });
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
        useAlert(this.$t('CONVERSATION.REPLYBOX.TIP_AUDIORECORDER_PERMISSION'));
        this.fireStateRecorderChanged('notallowederror');
      } else {
        useAlert(this.$t('CONVERSATION.REPLYBOX.TIP_AUDIORECORDER_ERROR'));
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
  @apply h-20 min-h-[5rem];

  .video-js {
    @apply bg-transparent max-h-60 min-h-[3rem] pt-4 px-0 pb-0 resize-none;
  }
}

// Added to override the default text and bg style to support dark and light mode.
.video-js .vjs-control-bar,
.vjs-record.video-js .vjs-control.vjs-record-indicator:before {
  @apply text-slate-600 dark:text-slate-200 bg-transparent dark:bg-transparent;
}

// Added to fix  div overlays the screen and takes over the button clicks
// https://github.com/collab-project/videojs-record/issues/688
// https://github.com/collab-project/videojs-record/pull/709
.vjs-record.video-js .vjs-control.vjs-record-indicator.vjs-hidden,
.vjs-record.video-js .vjs-control.vjs-record-indicator,
.vjs-record.video-js .vjs-control.vjs-record-indicator:before,
.vjs-record.video-js .vjs-control.vjs-record-indicator:after {
  @apply pointer-events-none;
}
</style>
