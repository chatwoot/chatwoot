<script setup>
import { computed, onMounted, useTemplateRef, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'next/icon/Icon.vue';
import { timeStampAppendedURL } from 'dashboard/helper/URLHelper';
import { downloadFile } from '@chatwoot/utils';
import { useAlert } from 'dashboard/composables';

const { t } = useI18n();
const { attachment, messageContent } = defineProps({
  attachment: {
    type: Object,
    required: true,
  },
  messageContent: {
    type: String,
    default: ''
  }
});

defineOptions({
  inheritAttrs: false,
});

const timeStampURL = computed(() => {
  if (!attachment.dataUrl) return null;
  return timeStampAppendedURL(attachment.dataUrl);
});

const audioPlayer = useTemplateRef('audioPlayer');

const isPlaying = ref(false);
const isMuted = ref(false);
const currentTime = ref(0);
const duration = ref(0);
const playbackSpeed = ref(1);
const hasDownloadError = ref(false);
const hasPlaybackError = ref(false);

// Check if this is a locale error message (path contains /locales/)
const isLocaleError = computed(() => {
  return attachment.dataUrl && attachment.dataUrl.includes('/locales/');
});

// Check if the message content indicates an error
const hasErrorContent = computed(() => {
  if (!messageContent) return false;
  return messageContent.toLowerCase().includes('download') && 
         (messageContent.toLowerCase().includes('fail') || 
          messageContent.toLowerCase().includes('error'));
});

// Determine if this is a backend-generated error message
const isBackendError = computed(() => {
  // If there's no URL but there IS message content, assume it's our backend error
  return !timeStampURL.value && !!messageContent;
});

const showWarningIcon = computed(() => {
  // Show icon if it's a backend error OR a frontend playback/download error
  return isBackendError.value || isLocaleError.value || hasDownloadError.value || hasPlaybackError.value;
});

const onLoadedMetadata = () => {
  duration.value = audioPlayer.value?.duration;
};

const onError = () => {
  hasPlaybackError.value = true;
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
  if (!timeStampURL.value) return;

  if (isPlaying.value) {
    audioPlayer.value.pause();
    isPlaying.value = false;
  } else {
    try {
      audioPlayer.value.play();
      isPlaying.value = true;
    } catch (error) {
      hasPlaybackError.value = true;
      useAlert(t('COMPONENTS.MEDIA.PLAYBACK_ERROR'));
    }
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
  
  // If URL is missing, show alert and disable download
  if (!dataUrl) {
    hasDownloadError.value = true;
    useAlert(t('GALLERY_VIEW.FILE_NOT_FOUND'));
    return;
  }
  
  try {
    hasDownloadError.value = false;
    // Ensure we have a file extension for the download
    const fileExt = extension || (fileType === 'audio/ogg' ? 'ogg' : 'mp3');
    await downloadFile({ url: dataUrl, type: fileType || 'audio/mpeg', extension: fileExt });
  } catch (error) {
    hasDownloadError.value = true;
    useAlert(t('GALLERY_VIEW.ERROR_DOWNLOADING'));
  }
};
</script>

<template>
  <audio
    ref="audioPlayer"
    controls
    class="hidden"
    @loadedmetadata="onLoadedMetadata"
    @timeupdate="onTimeUpdate"
    @ended="onEnd"
    @error="onError"
  >
    <source :src="timeStampURL" />
  </audio>
  <div
    v-bind="$attrs"
    class="rounded-xl w-full gap-1 p-1.5 bg-n-alpha-white flex items-center border border-n-container shadow-[0px_2px_8px_0px_rgba(94,94,94,0.06)]"
    :class="{ 'border-red-400': showWarningIcon }"
    :title="showWarningIcon ? t('COMPONENTS.MEDIA.AUDIO_ISSUE_HINT') : ''"
  >
    <button class="p-0 border-0 size-8" @click="playOrPause">
      <Icon
        v-if="isPlaying"
        class="size-8"
        icon="i-teenyicons-pause-small-solid"
      />
      <Icon v-else class="size-8" icon="i-teenyicons-play-small-solid" />
    </button>
    <!-- Show error text instead of player if no URL -->
    <div v-if="!timeStampURL" class="text-xs text-red-600 px-2 py-1 flex items-center">
      <!-- Show warning icon here too -->
      <span v-if="showWarningIcon" class="mr-1 text-yellow-500">⚠️</span> 
      {{ messageContent }}
    </div>
    <!-- Only show player controls if URL exists -->
    <template v-if="timeStampURL">
      <div class="tabular-nums text-xs flex items-center">
        <!-- Keep warning icon here for playback/download errors -->
        <span v-if="showWarningIcon" class="mr-1 text-yellow-500">⚠️</span>
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
        :class="{ 'text-red-600': hasDownloadError }"
        @click="downloadAudio"
      >
        <Icon class="size-4" icon="i-lucide-download" />
      </button>
    </template>
  </div>
</template>
