<template>
  <div class="flex flex-col gap-2 mt-2">
    <span class="font-medium text-slate-900 dark:text-slate-25 text-normal">
      Profile picture
    </span>
    <div
      class="relative rounded-xl h-[72px] w-[72px]"
      :title="title"
      @mouse-over="showUpload"
    >
      <img
        class="rounded-xl h-[72px] w-[72px]"
        src="https://i.pravatar.cc/300"
        draggable="false"
        @load="onImgLoad"
        @error="onImgError"
      />
      <div
        class="absolute z-10 flex items-center justify-center w-6 h-6 p-1 border border-white rounded-full select-none -top-2 -right-2 dark:border-white bg-slate-200 dark:bg-slate-700"
      >
        <fluent-icon
          icon="dismiss"
          size="16"
          class="text-slate-800 dark:text-slate-200"
        />
      </div>
      <div
        class="absolute h-[72px] w-[72px] top-0 left-0 rounded-xl select-none flex items-center justify-center bg-modal-backdrop-dark dark:bg-modal-backdrop-dark"
      >
        <fluent-icon
          icon="avatar-upload"
          size="32"
          class="text-white dark:text-white"
        />
      </div>
    </div>
  </div>
</template>
<script>
export default {
  props: {
    src: {
      type: String,
      default: '',
    },
    title: {
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
    shouldShowImage() {
      if (!this.src) {
        return false;
      }
      if (this.hasImageLoaded) {
        return !this.imgError;
      }
      return false;
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
  },
};
</script>
