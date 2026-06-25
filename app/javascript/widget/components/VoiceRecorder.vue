<script setup>
import { ref, onMounted, onUnmounted } from 'vue';
import getUuid from 'widget/helpers/uuid';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';

const emit = defineEmits(['finish', 'cancel', 'error']);

const MIME_EXTENSION_MAP = {
  'audio/webm': 'webm',
  'audio/ogg': 'ogg',
  'audio/mp4': 'mp4',
  'audio/mpeg': 'mp3',
  'audio/wav': 'wav',
};

const mediaRecorder = ref(null);
const mediaStream = ref(null);
const chunks = ref([]);
const elapsed = ref(0);
const isCancelled = ref(false);
const isUnmounted = ref(false);
let timer = null;

const formattedTime = () => {
  const minutes = Math.floor(elapsed.value / 60);
  const seconds = elapsed.value % 60;
  return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
};

const releaseStream = () => {
  if (timer) {
    clearInterval(timer);
    timer = null;
  }
  if (mediaStream.value) {
    mediaStream.value.getTracks().forEach(track => track.stop());
    mediaStream.value = null;
  }
};

const pickMimeType = () => {
  const candidates = ['audio/webm', 'audio/ogg', 'audio/mp4'];
  return candidates.find(type => MediaRecorder.isTypeSupported(type)) || '';
};

const isRecordingSupported = () =>
  !!navigator.mediaDevices?.getUserMedia &&
  typeof window.MediaRecorder !== 'undefined';

const startRecording = async () => {
  if (!isRecordingSupported()) {
    emit('error', new Error('Audio recording is not supported'));
    return;
  }

  let stream;
  try {
    stream = await navigator.mediaDevices.getUserMedia({ audio: true });
  } catch (error) {
    emit('error', error);
    return;
  }

  // The permission prompt is async: the user may have cancelled or the
  // component may have unmounted while it was open. Release and bail out
  // before we start capturing.
  if (isCancelled.value || isUnmounted.value) {
    stream.getTracks().forEach(track => track.stop());
    return;
  }

  mediaStream.value = stream;
  const mimeType = pickMimeType();
  mediaRecorder.value = new MediaRecorder(stream, mimeType ? { mimeType } : {});

  mediaRecorder.value.addEventListener('dataavailable', event => {
    if (event.data.size > 0) chunks.value.push(event.data);
  });

  mediaRecorder.value.addEventListener('stop', () => {
    releaseStream();
    if (isCancelled.value) return;

    const type = mediaRecorder.value.mimeType || 'audio/webm';
    const blob = new Blob(chunks.value, { type });
    const extension = MIME_EXTENSION_MAP[type.split(';')[0]] || 'webm';
    const file = new File([blob], `${getUuid()}.${extension}`, { type });
    emit('finish', file);
  });

  mediaRecorder.value.start();
  timer = setInterval(() => {
    elapsed.value += 1;
  }, 1000);
};

const stopRecording = () => {
  if (mediaRecorder.value && mediaRecorder.value.state !== 'inactive') {
    mediaRecorder.value.stop();
  }
};

const cancelRecording = () => {
  isCancelled.value = true;
  stopRecording();
  releaseStream();
  emit('cancel');
};

onMounted(startRecording);
onUnmounted(() => {
  isUnmounted.value = true;
  releaseStream();
});
</script>

<template>
  <div class="flex items-center justify-between w-full gap-2">
    <div class="flex items-center gap-2 text-n-slate-12">
      <span class="w-2 h-2 rounded-full bg-n-ruby-9 animate-pulse" />
      <span class="text-sm tabular-nums">{{ formattedTime() }}</span>
      <span class="text-sm text-n-slate-11">{{
        $t('VOICE_RECORDER.RECORDING')
      }}</span>
    </div>
    <div class="flex items-center gap-1">
      <button
        class="flex items-center justify-center min-h-8 min-w-8 text-n-slate-11"
        :aria-label="$t('VOICE_RECORDER.CANCEL')"
        @click="cancelRecording"
      >
        <FluentIcon icon="dismiss" />
      </button>
      <button
        class="flex items-center justify-center min-h-8 min-w-8 text-n-brand"
        :aria-label="$t('VOICE_RECORDER.STOP')"
        @click="stopRecording"
      >
        <FluentIcon icon="send" />
      </button>
    </div>
  </div>
</template>
