<script>
import BubbleImage from './Image.vue';
import BubbleVideo from './Video.vue';
import InstagramStoryErrorPlaceHolder from './InstagramStoryErrorPlaceHolder.vue';

export default {
  components: {
    BubbleImage,
    BubbleVideo,
    InstagramStoryErrorPlaceHolder,
  },
  props: {
    storyUrl: {
      type: String,
      default: '',
    },
  },
  emits: ['error'],
  data() {
    return {
      hasImgStoryError: false,
      hasVideoStoryError: false,
    };
  },
  methods: {
    onImageLoadError() {
      this.hasImgStoryError = true;
      this.emitError();
    },
    onVideoLoadError() {
      this.hasVideoStoryError = true;
      this.emitError();
    },
    emitError() {
      this.$emit('error');
    },
  },
};
</script>

<template>
  <BubbleImage
    v-if="!hasImgStoryError"
    :url="storyUrl"
    @error="onImageLoadError"
  />
  <BubbleVideo
    v-else-if="!hasVideoStoryError"
    :url="storyUrl"
    @error="onVideoLoadError"
  />
  <InstagramStoryErrorPlaceHolder v-else />
</template>
