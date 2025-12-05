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
import { useMessageContext } from '../provider.js';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import messageAPI from 'dashboard/api/inbox/message';

const { attachment } = defineProps({
  attachment: {
    type: Object,
    required: true,
  },
});

defineOptions({
  inheritAttrs: false,
});

const { t } = useI18n();
const { contentAttributes, conversationId, id } = useMessageContext();

const timeStampURL = computed(() => {
  return timeStampAppendedURL(attachment.dataUrl);
});

const audioPlayer = useTemplateRef('audioPlayer');

const isPlaying = ref(false);
const isMuted = ref(false);
const currentTime = ref(0);
const duration = ref(0);
const playbackSpeed = ref(1);
const isRetrying = ref(false);

const { uid } = getCurrentInstance();

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

const retryTranscription = async () => {
  isRetrying.value = true;
  try {
    await messageAPI.retryTranscription(conversationId.value, id.value);
    useAlert(t('CONVERSATION.TRANSCRIPTION_RETRY_INITIATED'));
  } catch {
    useAlert(t('CONVERSATION.TRANSCRIPTION_RETRY_FAILED'));
  } finally {
    isRetrying.value = false;
  }
};

// Compute transcription state
const transcriptionData = computed(() => {
  return contentAttributes.value?.transcription;
});

const hasTranscription = computed(() => {
  return !!transcriptionData.value?.language;
});

const hasTranscriptionError = computed(() => {
  return !!transcriptionData.value?.error;
});

// Removed: We can't reliably distinguish between "actively transcribing" vs "never transcribed"
// Users can transcribe old messages via the context menu "Transcribe audio" option
// const isTranscribing = computed(() => {
//   return (
//     audioTranscriptionEnabled.value &&
//     !hasTranscription.value &&
//     !hasTranscriptionError.value
//   );
// });

const transcriptionText = computed(() => {
  // Get transcription text from content attributes
  return transcriptionData.value?.text || '';
});

const languageName = computed(() => {
  const code = transcriptionData.value?.language;
  if (!code) return '';

  const languages = {
    en: 'English',
    es: 'Spanish',
    fr: 'French',
    de: 'German',
    pt: 'Portuguese',
    it: 'Italian',
    nl: 'Dutch',
    pl: 'Polish',
    ru: 'Russian',
    ja: 'Japanese',
    ko: 'Korean',
    zh: 'Chinese',
    ar: 'Arabic',
    hi: 'Hindi',
    tr: 'Turkish',
  };

  return languages[code] || code.toUpperCase();
});
</script>

<template>
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

    <!-- Transcription Error -->
    <div
      v-if="hasTranscriptionError"
      class="flex items-center justify-between gap-2 px-3 py-2 text-sm w-full"
    >
      <div class="flex items-center gap-2 text-n-red-11">
        <Icon class="size-4" icon="i-lucide-alert-circle" />
        <span>{{ t('CONVERSATION.TRANSCRIPTION_FAILED') }}</span>
      </div>
      <button
        class="flex items-center gap-1 px-2 py-1 text-xs border-0 bg-n-alpha-2 hover:bg-n-alpha-3 rounded text-n-slate-11 hover:text-n-slate-12 disabled:opacity-50 disabled:cursor-not-allowed"
        :disabled="isRetrying"
        @click="retryTranscription"
      >
        <Icon
          v-if="isRetrying"
          class="size-3 animate-spin"
          icon="i-lucide-loader-circle"
        />
        <Icon v-else class="size-3" icon="i-lucide-refresh-cw" />
        <span>{{ t('CONVERSATION.RETRY') }}</span>
      </button>
    </div>

    <!-- Transcription Content -->
    <div
      v-if="hasTranscription && transcriptionText"
      class="flex flex-col gap-1 p-3 text-sm bg-n-alpha-1 rounded-lg w-full"
    >
      <div class="flex items-center gap-2 text-xs text-n-slate-11">
        <Icon icon="i-lucide-text" class="size-3" />
        <span>{{ t('CONVERSATION.TRANSCRIPTION') }}</span>
        <span v-if="languageName" class="text-xs text-n-slate-10">
          ({{ languageName }})
        </span>
      </div>
      <p class="text-n-slate-12 whitespace-pre-wrap break-words">
        {{ transcriptionText }}
      </p>
    </div>
  </div>
</template>
