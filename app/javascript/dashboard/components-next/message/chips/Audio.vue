<script setup>
import { computed, onMounted, useTemplateRef, ref } from 'vue';
import Icon from 'next/icon/Icon.vue';
import { timeStampAppendedURL } from 'dashboard/helper/URLHelper';
import { downloadFile } from '@chatwoot/utils';

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
</script>

<template>
  <audio
    ref="audioPlayer"
    controls
    class="hidden"
    @loadedmetadata="onLoadedMetadata"
    @timeupdate="onTimeUpdate"
    @ended="onEnd"
  >
    <source :src="timeStampURL" />
  </audio>
  <div
    v-bind="$attrs"
    class="rounded-xl w-full gap-1 p-1.5 bg-n-alpha-white flex items-center border border-n-container shadow-[0px_2px_8px_0px_rgba(94,94,94,0.06)]"
  >
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
</template>
