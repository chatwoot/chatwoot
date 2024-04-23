<template>
  <div>
    <div class="flex flex-col gap-2">
      <span class="text-sm font-medium text-ash-900">
        {{ $t('PROFILE_SETTINGS.FORM.PICTURE') }}
      </span>
      <div
        class="relative rounded-xl h-[72px] w-[72px] cursor-pointer"
        @mouseover="onImageOver"
        @mouseleave="onImageOut"
      >
        <img
          v-if="shouldShowImage"
          class="rounded-xl h-[72px] w-[72px]"
          :src="src"
          draggable="false"
          @load="onImageLoad"
          @error="onImageLoadError"
        />
        <Avatar
          v-show="!shouldShowImage"
          :username="userNameWithoutEmoji"
          :size="72"
        />
        <input
          ref="fileInputRef"
          type="file"
          accept="image/png, image/jpeg, image/jpg, image/gif, image/webp"
          style="display: none"
          @change="onImageUpload"
        />
        <button
          v-if="src && shouldShowUploadIcon"
          class="absolute z-10 flex items-center justify-center w-6 h-6 p-1 border border-white rounded-full select-none reset-base -top-2 -right-2 dark:border-white bg-slate-200 dark:bg-slate-700"
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
    </div>
  </div>
</template>
<script setup>
import { computed, ref } from 'vue';
import Avatar from 'v3/components/Form/Avatar.vue';
import { removeEmoji } from 'shared/helpers/emoji';
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
const userNameWithoutEmoji = computed(() => removeEmoji(props.name));

const shouldShowImage = computed(() => {
  if (!props.src) {
    return false;
  }
  if (hasImageLoaded.value) {
    return !imageLoadedError.value;
  }
  return true;
});

const onImageLoadError = () => {
  imageLoadedError.value = true;
};

const onImageLoad = () => {
  hasImageLoaded.value = true;
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
  emits('change', {
    file,
    url: file ? URL.createObjectURL(file) : null,
  });
};

const onAvatarDelete = () => {
  emits('delete');
};
</script>
