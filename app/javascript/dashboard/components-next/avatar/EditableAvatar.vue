<script setup>
import { computed, ref } from 'vue';

import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  src: {
    type: String,
    default: '',
  },
  size: {
    type: Number,
    default: 72,
  },
  name: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['upload', 'delete']);

const avatarSize = computed(() => `${props.size}px`);
const iconSize = computed(() => `${props.size / 2}px`);

const fileInput = ref(null);
const imgError = ref(false);

const shouldShowImage = computed(() => props.src && !imgError.value);

const handleUploadAvatar = () => {
  fileInput.value.click();
};

const handleImageUpload = event => {
  const [file] = event.target.files;
  if (file) {
    emit('upload', {
      file,
      url: file ? URL.createObjectURL(file) : null,
    });
  }
};

const handleDeleteAvatar = () => {
  if (fileInput.value) {
    fileInput.value.value = null;
  }
  emit('delete');
};

const handleDismiss = event => {
  event.stopPropagation();
  handleDeleteAvatar();
};
</script>

<template>
  <div
    class="relative flex flex-col items-center gap-2 select-none rounded-xl outline outline-1 outline-n-container group/avatar"
    :style="{ width: avatarSize, height: avatarSize }"
  >
    <img
      v-if="shouldShowImage"
      :src="src"
      :alt="name || 'avatar'"
      class="object-cover w-full h-full shadow-sm rounded-xl"
      @error="imgError = true"
    />
    <div
      v-else
      class="flex items-center justify-center w-full h-full rounded-xl bg-n-alpha-2"
    >
      <Icon
        icon="i-lucide-building-2"
        class="text-n-brand/50"
        :style="{ width: `${iconSize}`, height: `${iconSize}` }"
      />
    </div>
    <div
      v-if="src"
      class="absolute z-20 outline outline-1 outline-n-container flex items-center cursor-pointer justify-center w-6 h-6 transition-all invisible opacity-0 duration-500 ease-in-out -top-2.5 -right-2.5 rounded-xl bg-n-solid-3 group-hover/avatar:visible group-hover/avatar:opacity-100"
      @click="handleDismiss"
    >
      <Icon icon="i-lucide-x" class="text-n-slate-11 size-4" />
    </div>
    <div
      class="absolute inset-0 z-10 flex items-center justify-center invisible w-full h-full transition-all duration-500 ease-in-out opacity-0 rounded-xl bg-n-alpha-black1 group-hover/avatar:visible group-hover/avatar:opacity-100"
      @click="handleUploadAvatar"
    >
      <Icon
        icon="i-lucide-upload"
        class="text-white"
        :style="{ width: `${iconSize}`, height: `${iconSize}` }"
      />
      <input
        ref="fileInput"
        type="file"
        accept="image/png, image/jpeg, image/jpg, image/gif, image/webp"
        class="hidden"
        @change="handleImageUpload"
      />
    </div>
  </div>
</template>
