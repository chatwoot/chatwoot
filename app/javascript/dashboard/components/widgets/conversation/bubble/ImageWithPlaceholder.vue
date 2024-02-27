<template>
  <div class="flex items-center justify-center w-full h-full">
    <img
      v-if="!isImageError"
      class="max-w-full max-h-full bg-woot-200 dark:bg-woot-900"
      :class="{
        'text-woot-200 dark:text-woot-900 opacity-50': !isImageLoaded,
      }"
      :src="placeholder"
      :width="imageWidth"
      :height="imageHeight"
      @click="onClick"
      @error="onImgError"
      @load="loadImage"
    />
  </div>
</template>

<script>
export default {
  props: {
    width: {
      type: Number || null,
      required: false,
      default: null,
    },
    height: {
      type: Number || null,
      required: false,
      default: null,
    },
    src: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      placeholder: `data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${this.width} ${this.height}"%3E%3Crect width="${this.width}" height="${this.height}" fill="currentColor" %3E%3C/rect%3E%3C/svg%3E`,
      isImageLoaded: false,
      isImageError: false,
    };
  },
  computed: {
    imageWidth() {
      return this.width ? `${this.width}px` : 'auto';
    },
    imageHeight() {
      return this.height ? `${this.height}px` : 'auto';
    },
  },
  watch: {
    src() {
      this.isImageLoaded = false;
      this.isImageError = false;
      this.loadImage();
    },
  },
  beforeDestroy() {
    this.isImageLoaded = false;
    this.isImageError = false;
  },
  methods: {
    loadImage() {
      if (!this.isImageLoaded) {
        const img = new Image();
        img.src = this.src;
        img.onload = () => {
          this.placeholder = img.src;
          this.isImageLoaded = true;
        };
      }
      this.$emit('load');
    },
    onImgError() {
      this.isImageError = true;
      this.isImageLoaded = true;
      this.$emit('error');
    },
    onClick() {
      this.$emit('click');
    },
  },
};
</script>
