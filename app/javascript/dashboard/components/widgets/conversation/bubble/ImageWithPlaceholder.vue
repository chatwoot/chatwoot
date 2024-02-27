<template>
  <div class="flex items-center justify-center w-full h-full">
    <img
      v-if="!isImageError"
      class="max-w-full max-h-full bg-woot-200 dark:bg-woot-900"
      :src="src"
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
      this.isImageError = false;
      this.loadImage();
    },
  },
  beforeDestroy() {
    this.isImageError = false;
  },
  methods: {
    loadImage() {
      this.$emit('load');
    },
    onImgError() {
      this.isImageError = true;
      this.$emit('error');
    },
    onClick() {
      this.$emit('click');
    },
  },
};
</script>
