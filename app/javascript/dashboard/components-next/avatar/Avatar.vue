<script setup>
import { computed } from 'vue';
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon.vue';

const props = defineProps({
  src: {
    type: String,
    default: '',
  },
  size: {
    type: Number,
    default: 72,
  },
});

const emit = defineEmits(['upload']);

const avatarSize = computed(() => `${props.size}px`);
const iconSize = computed(() => `${props.size / 2}px`);

const handleUploadAvatar = () => {
  emit('upload');
};
</script>

<template>
  <div
    class="relative flex flex-col items-center gap-2 select-none rounded-xl group/avatar"
    :style="{
      width: avatarSize,
      height: avatarSize,
    }"
  >
    <img
      v-if="src"
      :src="props.src"
      alt="avatar"
      class="w-full h-full shadow-sm rounded-xl"
    />
    <div
      class="absolute inset-0 flex items-center justify-center invisible w-full h-full transition-all duration-500 ease-in-out opacity-0 rounded-xl dark:bg-slate-900/50 bg-slate-900/20 group-hover/avatar:visible group-hover/avatar:opacity-100"
      @click="handleUploadAvatar"
    >
      <FluentIcon
        icon="upload-lucide"
        icon-lib="lucide"
        :size="iconSize"
        class="text-white dark:text-white"
      />
    </div>
  </div>
</template>
