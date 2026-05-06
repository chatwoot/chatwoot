<script setup>
import {
  computed,
  onMounted,
  useTemplateRef,
  ref,
  getCurrentInstance,
} from 'vue';
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

const playbackURL = computed(() => {
  return timeStampAppendedURL(attachment.playbackUrl || attachment.dataUrl);
});

const playbackContentType = computed(() => {
  return attachment.playbackUrl ? 'audio/mpeg' : attachment.contentType;
});

const audioPlayer = useTemplateRef('audioPlayer');

const isPlaying = ref(false);
const isMuted = ref(false);
const currentTime = ref(0);
const duration = ref(0);
const playbackSpeed = ref(1);
const hasNativeControlsFallback = ref(false);

const { uid } = getCurrentInstance();

const getFiniteMediaTime = time => {
  return Number.isFinite(time) ? time : 0;
};

const onLoadedMetadata = () => {
  duration.value = getFiniteMediaTime(audioPlayer.value?.duration);
  if (audioPlayer.value) {
    audioPlayer.value.playbackRate = playbackSpeed.value;
  }
};

const playbackSpeedLabel = computed(() => {
  return `${playbackSpeed.value}x`;
});

const durationSeparator = computed(() => {
  return '/';
});

const audioControlClass = computed(() => {
  return hasNativeControlsFallback.value ? 'w-full h-10' : 'sr-only';
});

// There maybe a chance that the audioPlayer ref is not available
// When the onLoadMetadata is called, so we need to set the duration
// value when the component is mounted
// Note: playbackRate must be set inside onLoadedMetadata (not onMounted)
// because on mobile browsers (especially Safari iOS), the audio element
// is not ready to accept playbackRate changes until metadata is loaded.
onMounted(() => {
  duration.value = getFiniteMediaTime(audioPlayer.value?.duration);
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
  if (!audioPlayer.value) return;

  audioPlayer.value.muted = !audioPlayer.value.muted;
  isMuted.value = audioPlayer.value.muted;
};

const onTimeUpdate = () => {
  currentTime.value = getFiniteMediaTime(audioPlayer.value?.currentTime);
};

const seek = event => {
  if (!audioPlayer.value) return;

  const time = Number(event.target.value);
  audioPlayer.value.currentTime = time;
  currentTime.value = time;
};

const onPlay = () => {
  isPlaying.value = true;
};

const onPause = () => {
  isPlaying.value = false;
};

const onAudioError = () => {
  isPlaying.value = false;
  hasNativeControlsFallback.value = true;
};

const playOrPause = async () => {
  if (!audioPlayer.value || !playbackURL.value) return;

  if (isPlaying.value) {
    audioPlayer.value.pause();
  } else {
    // Emit event to pause all other audio
    emitter.emit('pause_playing_audio', uid);
    audioPlayer.value.playbackRate = playbackSpeed.value;
    if (!isMuted.value) {
      audioPlayer.value.muted = false;
      audioPlayer.value.volume = 1;
    }
    if (audioPlayer.value.readyState === 0) {
      audioPlayer.value.load();
    }
    try {
      await audioPlayer.value.play();
    } catch {
      isPlaying.value = false;
      hasNativeControlsFallback.value = true;
    }
  }
};

const onEnd = () => {
  isPlaying.value = false;
  currentTime.value = 0;
  playbackSpeed.value = 1;
  if (audioPlayer.value) {
    audioPlayer.value.playbackRate = 1;
  }
};

const changePlaybackSpeed = () => {
  const speeds = [1, 1.5, 2];
  const currentIndex = speeds.indexOf(playbackSpeed.value);
  const nextIndex = (currentIndex + 1) % speeds.length;
  playbackSpeed.value = speeds[nextIndex];
  if (audioPlayer.value) {
    audioPlayer.value.playbackRate = playbackSpeed.value;
  }
};

const downloadAudio = async () => {
  const { fileType, dataUrl, extension } = attachment;
  downloadFile({ url: dataUrl, type: fileType, extension });
};
</script>

<template>
  <div
    v-bind="$attrs"
    class="rounded-xl w-full gap-2 p-1.5 bg-n-alpha-white flex flex-col items-center border border-n-container shadow-[0px_2px_8px_0px_rgba(94,94,94,0.06)]"
  >
    <audio
      ref="audioPlayer"
      :controls="hasNativeControlsFallback"
      preload="metadata"
      controlsList="nodownload"
      :class="audioControlClass"
      playsinline
      @loadedmetadata="onLoadedMetadata"
      @timeupdate="onTimeUpdate"
      @play="onPlay"
      @pause="onPause"
      @ended="onEnd"
      @error="onAudioError"
    >
      <source
        v-if="playbackURL"
        :src="playbackURL"
        :type="playbackContentType"
      />
    </audio>
    <div
      v-if="!hasNativeControlsFallback"
      class="flex gap-1 w-full flex-1 items-center justify-start"
    >
      <button type="button" class="p-0 border-0 size-8" @click="playOrPause">
        <Icon
          v-if="isPlaying"
          class="size-8"
          icon="i-teenyicons-pause-small-solid"
        />
        <Icon v-else class="size-8" icon="i-teenyicons-play-small-solid" />
      </button>
      <div class="tabular-nums text-xs">
        {{ formatTime(currentTime) }} {{ durationSeparator }}
        {{ formatTime(duration) }}
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
        type="button"
        class="border-0 w-10 h-6 grid place-content-center bg-n-alpha-2 hover:bg-alpha-3 rounded-2xl"
        @click="changePlaybackSpeed"
      >
        <span class="text-xs text-n-slate-11 font-medium">
          {{ playbackSpeedLabel }}
        </span>
      </button>
      <button
        type="button"
        class="p-0 border-0 size-8 grid place-content-center"
        @click="toggleMute"
      >
        <Icon v-if="isMuted" class="size-4" icon="i-lucide-volume-off" />
        <Icon v-else class="size-4" icon="i-lucide-volume-2" />
      </button>
      <button
        type="button"
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
