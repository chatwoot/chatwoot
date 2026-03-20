<script setup>
import {
  computed,
  onMounted,
  useTemplateRef,
  ref,
  getCurrentInstance,
} from 'vue';
import { useI18n } from 'vue-i18n';
import { useLoadWithRetry } from 'dashboard/composables/loadWithRetry';
import Icon from 'next/icon/Icon.vue';
import { timeStampAppendedURL } from 'dashboard/helper/URLHelper';
import { downloadFile } from '@chatwoot/utils';
import { useEmitter } from 'dashboard/composables/emitter';
import { emitter } from 'shared/helpers/mitt';

const { attachment } = defineProps({
  attachment: {
    type: Object,
    required: true,
  },
  showTranscribedText: {
    type: Boolean,
    default: true,
  },
});

defineOptions({
  inheritAttrs: false,
});

const { t } = useI18n();
const { isLoaded, hasError, loadWithRetry } = useLoadWithRetry({
  type: 'audio',
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

const { uid } = getCurrentInstance();

const onLoadedMetadata = () => {
  if (audioPlayer.value) {
    duration.value = audioPlayer.value.duration;
    audioPlayer.value.playbackRate = playbackSpeed.value;
  }
};

const playbackSpeedLabel = computed(() => {
  return `${playbackSpeed.value}x`;
});

onMounted(() => {
  if (attachment.dataUrl) {
    loadWithRetry(attachment.dataUrl);
  }
});

// Listen for global audio play events and pause if it's not this audio
useEmitter('pause_playing_audio', currentPlayingId => {
  if (currentPlayingId !== uid && isPlaying.value) {
    try {
      audioPlayer.value.pause();
    } catch {
      /* ignore pause errors */
    }
    isPlaying.value = false;
  }
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
    // Emit event to pause all other audio
    emitter.emit('pause_playing_audio', uid);
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
</script>

<template>
  <div
    v-if="hasError"
    v-bind="$attrs"
    class="flex items-center gap-1 text-center rounded-lg p-2 bg-n-alpha-white border border-n-container"
  >
    <Icon icon="i-lucide-circle-off" class="text-n-slate-11" />
    <p class="mb-0 text-n-slate-11 text-sm">
      {{ t('COMPONENTS.MEDIA.AUDIO_UNAVAILABLE') }}
    </p>
  </div>
  <template v-else-if="isLoaded">
    <audio
      ref="audioPlayer"
      controls
      class="hidden"
      playsinline
      @loadedmetadata="onLoadedMetadata"
      @timeupdate="onTimeUpdate"
      @ended="onEnd"
    >
      <source :src="timeStampURL" />
    </audio>
    <div
      v-bind="$attrs"
      class="rounded-xl w-full gap-2 p-1.5 bg-n-alpha-white flex flex-col items-center border border-n-container shadow-[0px_2px_8px_0px_rgba(94,94,94,0.06)]"
    >
      <div class="flex gap-1 w-full flex-1 items-center justify-start">
        <button class="p-0 border-0 size-8" @click="playOrPause">
          <Icon
            v-if="isPlaying"
            class="size-8"
            icon="i-teenyicons-pause-small-solid"
          />
          <Icon v-else class="size-8" icon="i-teenyicons-play-small-solid" />
        </button>
        <div class="tabular-nums text-xs">
          {{ formatTime(currentTime) }} / {{ formatTime(duration) }}
        </div>
        <div class="flex-1 items-center flex px-2">
          <input
            type="range"
            min="0"
            :max="duration"
            :value="currentTime"
            class="w-full h-1 bg-n-slate-12/40 rounded-lg appearance-none cursor-pointer accent-current"
            @input="seek"
          />
        </div>
        <button
          class="border-0 w-10 h-6 grid place-content-center bg-n-alpha-2 hover:bg-alpha-3 rounded-2xl"
          @click="changePlaybackSpeed"
        >
          <span class="text-xs text-n-slate-11 font-medium">
            {{ playbackSpeedLabel }}
          </span>
        </button>
        <button
          class="p-0 border-0 size-8 grid place-content-center"
          @click="toggleMute"
        >
          <Icon v-if="isMuted" class="size-4" icon="i-lucide-volume-off" />
          <Icon v-else class="size-4" icon="i-lucide-volume-2" />
        </button>
        <button
          class="p-0 border-0 size-8 grid place-content-center"
          @click="downloadAudio"
        >
          <Icon class="size-4" icon="i-lucide-download" />
        </button>
      </div>

      <div
        v-if="attachment.transcribedText && showTranscribedText"
        class="text-n-slate-12 p-3 text-sm bg-n-alpha-1 rounded-lg w-full break-words"
      >
        {{ attachment.transcribedText }}
      </div>
    </div>
  </template>
</template>
