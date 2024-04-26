<template>
  <div
    class="relative rounded-xl h-[72px] w-[72px] cursor-pointer"
    @mouseover="onImageOver"
    @mouseleave="onImageOut"
  >
    <img
      v-if="shouldShowImage"
      class="rounded-xl h-[72px] w-[72px]"
      :alt="name"
      :src="src"
      draggable="false"
      @load="onImageLoad"
      @error="onImageLoadError"
    />
    <initials-avatar v-else-if="!shouldShowImage" :name="name" :size="72" />

    <input
      ref="fileInputRef"
      type="file"
      accept="image/png, image/jpeg, image/jpg, image/gif, image/webp"
      style="display: none"
      @change="onImageUpload"
    />
    <button
      v-if="src && shouldShowUploadIcon"
      class="absolute z-10 flex items-center justify-center w-6 h-6 p-1 border border-white rounded-full select-none dark:border-ash-75 reset-base -top-2 -right-2 bg-ash-300"
      @click="onAvatarDelete"
    >
      <fluent-icon
        icon="dismiss"
        size="16"
        class="text-slate-800 dark:text-slate-200"
      />
    </button>
    <button
      v-if="shouldShowUploadIcon"
      class="reset-base absolute h-[72px] w-[72px] top-0 left-0 rounded-xl select-none flex items-center justify-center bg-modal-backdrop-dark dark:bg-modal-backdrop-dark"
      @click="openFileInput"
    >
      <fluent-icon icon="avatar-upload" size="32" class="text-white" />
    </button>
  </div>
</template>
<script setup>
import { computed, ref } from 'vue';
import InitialsAvatar from './InitialsAvatar.vue';
const props = defineProps({
  src: {
    type: String,
    default: '',
  },
  name: {
    type: String,
    default: '',
  },
});

const emits = defineEmits(['change', 'delete']);

const hasImageLoaded = ref(false);
const imageLoadedError = ref(false);
const shouldShowUploadIcon = ref(false);
const fileInputRef = ref(null);

const shouldShowImage = computed(() => props.src && !imageLoadedError.value);

const onImageLoadError = () => {
  imageLoadedError.value = true;
};

const onImageLoad = () => {
  hasImageLoaded.value = true;
  imageLoadedError.value = false;
};

const onImageOver = () => {
  shouldShowUploadIcon.value = true;
};

const onImageOut = () => {
  shouldShowUploadIcon.value = false;
};

const openFileInput = () => {
  fileInputRef.value.click();
};

const onImageUpload = event => {
  const [file] = event.target.files;
  emits('change-avatar', {
    file,
    url: file ? URL.createObjectURL(file) : null,
  });
};

const onAvatarDelete = () => {
  emits('delete-avatar');
};
</script>
