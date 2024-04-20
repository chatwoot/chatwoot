<template>
  <div>
    <div class="flex flex-col gap-2">
      <span class="font-medium text-ash-90"> Profile picture </span>
      <div
        class="relative rounded-xl h-[72px] w-[72px] cursor-pointer"
        :title="name"
        @mouseover="showUpload"
        @mouseleave="hideUpload"
      >
        <img
          v-if="shouldShowImage"
          class="rounded-xl h-[72px] w-[72px]"
          :src="src"
          draggable="false"
          @load="onImgLoad"
          @error="onImgError"
        />
        <Avatar
          v-show="!shouldShowImage"
          :username="userNameWithoutEmoji"
          :size="72"
        />
        <input
          ref="file"
          type="file"
          accept="image/png, image/jpeg, image/jpg, image/gif, image/webp"
          style="display: none"
          @change="handleImageUpload"
        />
        <button
          v-if="src && showUploadIcon"
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
          v-if="showUploadIcon"
          class="reset-base absolute h-[72px] w-[72px] top-0 left-0 rounded-xl select-none flex items-center justify-center bg-modal-backdrop-dark dark:bg-modal-backdrop-dark"
          @click="openFileInput"
        >
          <fluent-icon icon="avatar-upload" size="32" class="text-white" />
        </button>
      </div>
    </div>
  </div>
</template>
<script>
import Avatar from 'v3/components/Form/Avatar.vue';
import { removeEmoji } from 'shared/helpers/emoji';
export default {
  components: {
    Avatar,
  },
  props: {
    src: {
      type: String,
      default: '',
    },
    name: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      hasImageLoaded: false,
      imgError: false,
      showUploadIcon: false,
    };
  },
  computed: {
    userNameWithoutEmoji() {
      return removeEmoji(this.name);
    },
    shouldShowImage() {
      if (!this.src) {
        return false;
      }
      if (this.hasImageLoaded) {
        return !this.imgError;
      }
      return true;
    },
  },
  watch: {
    src(value, oldValue) {
      if (value !== oldValue && this.imgError) {
        this.imgError = false;
      }
    },
  },
  methods: {
    onImgError() {
      this.imgError = true;
    },
    onImgLoad() {
      this.hasImageLoaded = true;
    },
    showUpload() {
      this.showUploadIcon = true;
    },
    hideUpload() {
      this.showUploadIcon = false;
    },
    openFileInput() {
      // Trigger click event on the hidden file input
      this.$refs.file.click();
    },
    handleImageUpload(event) {
      const [file] = event.target.files;
      this.$emit('change', {
        file,
        url: file ? URL.createObjectURL(file) : null,
      });
    },
    onAvatarDelete() {
      this.$emit('delete');
    },
  },
};
</script>
