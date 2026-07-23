<script setup>
import {
  computed,
  onMounted,
  useTemplateRef,
  ref,
  watch,
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

const timeStampURL = computed(() => {
  return timeStampAppendedURL(attachment.dataUrl);
});

const TRANSCRIPT_PREVIEW_LENGTH = 200;
const isTranscriptExpanded = ref(false);
const isTranscriptLong = computed(
  () => (attachment.transcribedText?.length || 0) > TRANSCRIPT_PREVIEW_LENGTH
);
const displayedTranscript = computed(() => {
  const text = attachment.transcribedText || '';
  if (!isTranscriptLong.value || isTranscriptExpanded.value) return text;
  return `${text.slice(0, TRANSCRIPT_PREVIEW_LENGTH).trimEnd()}…`;
});

const audioPlayer = useTemplateRef('audioPlayer');

const isPlaying = ref(false);
const isMuted = ref(false);
const currentTime = ref(0);
const duration = ref(0);
const playbackSpeed = ref(1);
// While probing WebM/Opus duration we seek to a huge currentTime; ignore those
// timeupdates so the UI does not flash values like 150119987579016:31.
const isProbingDuration = ref(false);

const { uid } = getCurrentInstance();

const MAX_DISPLAY_SECONDS = 24 * 60 * 60; // 24h ceiling for mm:ss display

// MediaRecorder-produced WebM/Opus blobs lack a Duration header → <audio>.duration
// resolves to Infinity until we seek past the end, which forces the engine to
// scan the file and compute the real length. Safe no-op for files with a real
// duration already (mp3/m4a/etc).
const resolveStreamingDuration = () => {
  const el = audioPlayer.value;
  if (!el || isProbingDuration.value) return;

  isProbingDuration.value = true;
  const onProbeTimeUpdate = () => {
    el.removeEventListener('timeupdate', onProbeTimeUpdate);
    try {
      el.currentTime = 0;
    } catch {
      /* ignore */
    }
    const d = el.duration;
    if (Number.isFinite(d) && d > 0) {
      duration.value = d;
    }
    currentTime.value = 0;
    isProbingDuration.value = false;
  };

  el.addEventListener('timeupdate', onProbeTimeUpdate);
  try {
    el.currentTime = Number.MAX_SAFE_INTEGER;
  } catch {
    el.removeEventListener('timeupdate', onProbeTimeUpdate);
    isProbingDuration.value = false;
  }
};

const syncDurationFromElement = () => {
  const d = audioPlayer.value?.duration;
  if (!Number.isFinite(d) || d <= 0) {
    resolveStreamingDuration();
    return;
  }
  duration.value = d;
};

const onLoadedMetadata = () => {
  syncDurationFromElement();
};

const onDurationChange = () => {
  syncDurationFromElement();
};

const playbackSpeedLabel = computed(() => {
  return `${playbackSpeed.value}x`;
});

// There maybe a chance that the audioPlayer ref is not available
// When the onLoadMetadata is called, so we need to set the duration
// value when the component is mounted
onMounted(() => {
  syncDurationFromElement();
  audioPlayer.value.playbackRate = playbackSpeed.value;
});

watch(timeStampURL, (url, previousUrl) => {
  if (!url || url === previousUrl) return;

  const el = audioPlayer.value;
  if (!el) return;

  el.load();
  currentTime.value = 0;
  duration.value = 0;
  isPlaying.value = false;
  isProbingDuration.value = false;
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
  if (time === null || time === undefined || Number.isNaN(time)) return '00:00';
  const seconds = Number(time);
  if (
    !Number.isFinite(seconds) ||
    seconds < 0 ||
    seconds > MAX_DISPLAY_SECONDS
  ) {
    return '00:00';
  }
  const minutes = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
};

const toggleMute = () => {
  audioPlayer.value.muted = !audioPlayer.value.muted;
  isMuted.value = audioPlayer.value.muted;
};

const onTimeUpdate = () => {
  if (isProbingDuration.value) return;

  const t = audioPlayer.value?.currentTime;
  if (!Number.isFinite(t) || t < 0 || t > MAX_DISPLAY_SECONDS) return;
  // Ignore probe overshoots if duration is already known
  if (duration.value > 0 && t > duration.value + 1) return;

  currentTime.value = t;
};

const seek = event => {
  const time = Number(event.target.value);
  if (!Number.isFinite(time) || time < 0) return;
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
  <audio
    ref="audioPlayer"
    controls
    class="hidden"
    playsinline
    @loadedmetadata="onLoadedMetadata"
    @durationchange="onDurationChange"
    @canplaythrough="onDurationChange"
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
          :max="duration > 0 ? duration : 1"
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
      {{ displayedTranscript }}
      <button
        v-if="isTranscriptLong"
        class="block mt-1 p-0 border-0 bg-transparent text-n-slate-11 hover:text-n-slate-12 font-medium"
        @click="isTranscriptExpanded = !isTranscriptExpanded"
      >
        {{
          isTranscriptExpanded
            ? $t('CONVERSATION.VOICE_CALL.TRANSCRIPT_SHOW_LESS')
            : $t('CONVERSATION.VOICE_CALL.TRANSCRIPT_SHOW_MORE')
        }}
      </button>
    </div>
  </div>
</template>
