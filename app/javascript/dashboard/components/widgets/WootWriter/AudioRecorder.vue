<script setup>
import getUuid from 'widget/helpers/uuid';
import { ref, onMounted, onUnmounted, defineEmits, defineExpose } from 'vue';
import WaveSurfer from 'wavesurfer.js';
import RecordPlugin from 'wavesurfer.js/dist/plugins/record.js';
import { format, intervalToDuration } from 'date-fns';
import { convertAudio } from './utils/audioConversionUtils';

const props = defineProps({
  audioRecordFormat: {
    type: String,
    required: true,
  },
});

const emit = defineEmits([
  'recorderProgressChanged',
  'finishRecord',
  'pause',
  'play',
  'recordError',
]);

const waveformContainer = ref(null);
const wavesurfer = ref(null);
const record = ref(null);
const isRecording = ref(false);
const isPlaying = ref(false);
const hasRecording = ref(false);
const recordedAudioUrl = ref(null);

const formatTimeProgress = time => {
  const duration = intervalToDuration({ start: 0, end: time });
  return format(
    new Date(0, 0, 0, 0, duration.minutes, duration.seconds),
    'mm:ss'
  );
};

const AUDIO_EXTENSION_MAP = {
  'audio/ogg': 'ogg',
  'audio/mp3': 'mp3',
  'audio/mpeg': 'mp3',
  'audio/wav': 'wav',
  'audio/webm': 'webm',
};

const getRecordPluginOptions = audioFormat => {
  const options = {
    scrollingWaveform: true,
    renderRecordedAudio: false,
  };
  if (
    audioFormat === 'audio/ogg' &&
    MediaRecorder.isTypeSupported('audio/ogg;codecs=opus')
  ) {
    options.mimeType = 'audio/ogg;codecs=opus';
  }
  return options;
};

const initWaveSurfer = () => {
  wavesurfer.value = WaveSurfer.create({
    container: waveformContainer.value,
    waveColor: '#1F93FF',
    progressColor: '#6E6F73',
    height: 100,
    barWidth: 2,
    barGap: 1,
    barRadius: 2,
    plugins: [
      RecordPlugin.create(getRecordPluginOptions(props.audioRecordFormat)),
    ],
  });

  wavesurfer.value.on('pause', () => emit('pause'));
  wavesurfer.value.on('play', () => emit('play'));

  record.value = wavesurfer.value.plugins[0];

  wavesurfer.value.on('finish', () => {
    isPlaying.value = false;
  });

  record.value.on('record-end', async blob => {
    try {
      const audioBlob = await convertAudio(blob, props.audioRecordFormat);
      const ext = AUDIO_EXTENSION_MAP[props.audioRecordFormat] || 'mp3';
      const fileName = `${getUuid()}.${ext}`;
      const file = new File([audioBlob], fileName, {
        type: props.audioRecordFormat,
      });
      if (recordedAudioUrl.value) URL.revokeObjectURL(recordedAudioUrl.value);
      recordedAudioUrl.value = URL.createObjectURL(audioBlob);
      wavesurfer.value.load(recordedAudioUrl.value);
      emit('finishRecord', {
        name: file.name,
        type: file.type,
        size: file.size,
        file,
      });
      hasRecording.value = true;
      isRecording.value = false;
    } catch (error) {
      isRecording.value = false;
      hasRecording.value = false;
      emit('recordError', { error });
    }
  });

  record.value.on('record-progress', time => {
    emit('recorderProgressChanged', formatTimeProgress(time));
  });
};

const stopRecording = () => {
  if (isRecording.value) {
    record.value.stopRecording();
    isRecording.value = false;
  }
};

const startRecording = () => {
  record.value.startRecording();
  isRecording.value = true;
};

const playPause = () => {
  if (hasRecording.value) {
    wavesurfer.value.playPause();
    isPlaying.value = !isPlaying.value;
  }
};

onMounted(() => {
  initWaveSurfer();
  startRecording();
});

onUnmounted(() => {
  if (recordedAudioUrl.value) {
    URL.revokeObjectURL(recordedAudioUrl.value);
    recordedAudioUrl.value = null;
  }
  if (wavesurfer.value) {
    wavesurfer.value.destroy();
  }
});

defineExpose({ playPause, stopRecording, record });
</script>

<template>
  <div ref="waveformContainer" class="w-full p-1" />
</template>
