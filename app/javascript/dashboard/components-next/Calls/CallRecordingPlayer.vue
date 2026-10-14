<script setup>
import { computed, getCurrentInstance, ref, useTemplateRef } from 'vue';
import { downloadFile } from '@chatwoot/utils';
import { useEmitter } from 'dashboard/composables/emitter';
import { emitter } from 'shared/helpers/mitt';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  src: {
    type: String,
    required: true,
  },
  fallbackDuration: {
    type: Number,
    default: 0,
  },
});

const PLAYBACK_SPEEDS = [1, 1.5, 2];

const audioPlayer = useTemplateRef('audioPlayer');
const { uid } = getCurrentInstance();

const isPlaying = ref(false);
const currentTime = ref(0);
const duration = ref(props.fallbackDuration);
const playbackSpeed = ref(1);

const onLoadedMetadata = () => {
  const loadedDuration = audioPlayer.value?.duration;
  if (Number.isFinite(loadedDuration)) duration.value = loadedDuration;
};

const formatTime = time => {
  if (!time || Number.isNaN(time)) return '00:00';
  const minutes = Math.floor(time / 60);
  const seconds = Math.floor(time % 60);
  return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
};

const playbackSpeedLabel = computed(() => `${playbackSpeed.value}x`);

const displayedTime = computed(() =>
  formatTime(
    isPlaying.value || currentTime.value ? currentTime.value : duration.value
  )
);

// Only one recording should play at a time across the list.
useEmitter('pause_playing_audio', currentPlayingId => {
  if (currentPlayingId !== uid && isPlaying.value) {
    audioPlayer.value?.pause();
    isPlaying.value = false;
  }
});

const playOrPause = () => {
  if (isPlaying.value) {
    audioPlayer.value.pause();
    isPlaying.value = false;
  } else {
    emitter.emit('pause_playing_audio', uid);
    audioPlayer.value.play();
    isPlaying.value = true;
  }
};

const onTimeUpdate = () => {
  currentTime.value = audioPlayer.value?.currentTime;
};

const seek = event => {
  const time = Number(event.target.value);
  audioPlayer.value.currentTime = time;
  currentTime.value = time;
};

const onEnd = () => {
  isPlaying.value = false;
  currentTime.value = 0;
};

const changePlaybackSpeed = () => {
  const currentIndex = PLAYBACK_SPEEDS.indexOf(playbackSpeed.value);
  playbackSpeed.value =
    PLAYBACK_SPEEDS[(currentIndex + 1) % PLAYBACK_SPEEDS.length];
  audioPlayer.value.playbackRate = playbackSpeed.value;
};

const downloadRecording = () => {
  downloadFile({ url: props.src, type: 'audio' });
};
</script>

<template>
  <div
    class="flex items-center justify-center h-9 gap-2 px-2 rounded-full bg-n-alpha-1 dark:bg-n-alpha-2 overflow-hidden"
    @click.stop
  >
    <audio
      ref="audioPlayer"
      class="hidden"
      playsinline
      @loadedmetadata="onLoadedMetadata"
      @timeupdate="onTimeUpdate"
      @ended="onEnd"
    >
      <source :src="src" />
    </audio>
    <Button
      variant="ghost"
      color="slate"
      size="xs"
      class="!w-6 !p-0 text-n-slate-12"
      @click="playOrPause"
    >
      <template #icon>
        <Icon
          :icon="isPlaying ? 'i-lucide-pause' : 'i-lucide-play'"
          class="size-4 flex-shrink-0"
        />
      </template>
    </Button>
    <input
      type="range"
      min="0"
      :max="duration || 0"
      :value="currentTime"
      class="flex-1 min-w-0 lg:grow-0 lg:basis-24 h-1 rounded-lg appearance-none cursor-pointer bg-n-slate-12/30 accent-n-slate-11"
      @input="seek"
    />
    <span class="text-sm tabular-nums text-n-slate-11 shrink-0">
      {{ displayedTime }}
    </span>
    <div class="w-px h-3.5 bg-n-slate-6 shrink-0" />
    <Button
      variant="ghost"
      color="slate"
      size="xs"
      :label="playbackSpeedLabel"
      class="!px-1 min-w-6 !text-n-slate-11"
      @click="changePlaybackSpeed"
    />
    <div class="w-px h-3.5 bg-n-slate-6 shrink-0" />
    <Button
      variant="ghost"
      color="slate"
      size="xs"
      class="!w-6 !p-0 text-n-slate-11"
      @click="downloadRecording"
    >
      <template #icon>
        <Icon icon="i-lucide-download" class="size-4 flex-shrink-0" />
      </template>
    </Button>
  </div>
</template>
