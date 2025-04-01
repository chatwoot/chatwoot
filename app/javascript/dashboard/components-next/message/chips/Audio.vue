<script setup>
import { computed, onMounted, useTemplateRef, ref } from 'vue';
import Icon from 'next/icon/Icon.vue';
import { timeStampAppendedURL } from 'dashboard/helper/URLHelper';
import { downloadFile } from '@chatwoot/utils';
import { transcribeAudio } from 'dashboard/services/transcriptionService';

const { attachment } = defineProps({
  attachment: {
    type: Object,
    required: true,
  },
});

defineOptions({
  inheritAttrs: false,
});

const timeStampURL = computed(() => {
  return timeStampAppendedURL(attachment.dataUrl);
});

const audioPlayer = useTemplateRef('audioPlayer');

const isPlaying = ref(false);
const isMuted = ref(false);
const currentTime = ref(0);
const duration = ref(0);
const playbackSpeed = ref(1);
const showTranscription = ref(false);
const isTranscribing = ref(false);
const transcriptionText = ref('');

const onLoadedMetadata = () => {
  duration.value = audioPlayer.value?.duration;
};

const playbackSpeedLabel = computed(() => {
  return `${playbackSpeed.value}x`;
});

// There maybe a chance that the audioPlayer ref is not available
// When the onLoadMetadata is called, so we need to set the duration
// value when the component is mounted
onMounted(() => {
  duration.value = audioPlayer.value?.duration;
  audioPlayer.value.playbackRate = playbackSpeed.value;
});

const formatTime = time => {
  if (!time || Number.isNaN(time)) return '00:00';
  const minutes = Math.floor(time / 60);
  const seconds = Math.floor(time % 60);
  return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
};

const toggleMute = () => {
  audioPlayer.value.muted = !audioPlayer.value.muted;
  isMuted.value = audioPlayer.value.muted;
};

const onTimeUpdate = () => {
  currentTime.value = audioPlayer.value?.currentTime;
};

const seek = event => {
  const time = Number(event.target.value);
  audioPlayer.value.currentTime = time;
  currentTime.value = time;
};

const playOrPause = () => {
  if (isPlaying.value) {
    audioPlayer.value.pause();
    isPlaying.value = false;
  } else {
    audioPlayer.value.play();
    isPlaying.value = true;
  }
};

const onEnd = () => {
  isPlaying.value = false;
  currentTime.value = 0;
  playbackSpeed.value = 1;
  audioPlayer.value.playbackRate = 1;
};

const changePlaybackSpeed = () => {
  const speeds = [1, 1.5, 2];
  const currentIndex = speeds.indexOf(playbackSpeed.value);
  const nextIndex = (currentIndex + 1) % speeds.length;
  playbackSpeed.value = speeds[nextIndex];
  audioPlayer.value.playbackRate = playbackSpeed.value;
};

const downloadAudio = async () => {
  const { fileType, dataUrl, extension } = attachment;
  downloadFile({ url: dataUrl, type: fileType, extension });
};

const handleTranscribeAudio = async () => {
  if (isTranscribing.value) return;

  try {
    isTranscribing.value = true;
    transcriptionText.value = 'Transcrevendo...';
    showTranscription.value = true;

    // Usa a URL base do arquivo sem o timestamp
    const baseUrl = attachment.dataUrl.split('?')[0];
    const result = await transcribeAudio(baseUrl);
    transcriptionText.value = result;
  } catch (error) {
    transcriptionText.value =
      error.response?.data?.error?.message ||
      'Erro ao transcrever o áudio. Por favor, tente novamente.';
  } finally {
    isTranscribing.value = false;
  }
};
</script>

<template>
  <div class="flex flex-col gap-2">
    <div class="flex items-center gap-2">
      <button
        class="p-1 rounded-full hover:bg-n-alpha-1 transition-colors"
        :title="$t('CONVERSATION.TRANSCRIBE_AUDIO')"
        @click="handleTranscribeAudio"
      >
        <Icon icon="i-lucide-ear" class="size-3 text-n-slate-11" />
      </button>
      <audio
        ref="audioPlayer"
        :src="timeStampURL"
        class="hidden"
        @loadedmetadata="onLoadedMetadata"
        @timeupdate="onTimeUpdate"
        @ended="onEnd"
      />
      <div class="flex items-center gap-2">
        <button
          class="p-1 rounded-full hover:bg-n-alpha-1 transition-colors"
          @click="playOrPause"
        >
          <Icon
            :icon="isPlaying ? 'i-lucide-pause' : 'i-lucide-play'"
            class="size-3 text-n-slate-11"
          />
        </button>
        <div class="flex-1">
          <input
            type="range"
            :value="currentTime"
            :max="duration"
            class="w-full"
            @input="seek"
          />
          <div class="flex justify-between text-xs text-n-slate-11">
            <span>{{ formatTime(currentTime) }}</span>
            <span>{{ formatTime(duration) }}</span>
          </div>
        </div>
        <button
          class="p-1 rounded-full hover:bg-n-alpha-1 transition-colors"
          @click="toggleMute"
        >
          <Icon
            :icon="isMuted ? 'i-lucide-volume-x' : 'i-lucide-volume-2'"
            class="size-3 text-n-slate-11"
          />
        </button>
        <button
          class="p-1 rounded-full hover:bg-n-alpha-1 transition-colors"
          @click="changePlaybackSpeed"
        >
          <span class="text-xs text-n-slate-11">{{ playbackSpeedLabel }}</span>
        </button>
        <button
          class="p-1 rounded-full hover:bg-n-alpha-1 transition-colors"
          @click="downloadAudio"
        >
          <Icon icon="i-lucide-download" class="size-3 text-n-slate-11" />
        </button>
      </div>
    </div>
    <div
      v-if="showTranscription"
      class="p-2 bg-n-alpha-1 rounded-lg text-sm text-n-slate-11"
    >
      {{ transcriptionText }}
    </div>
  </div>
</template>
