<template>
  <bubble-image
    v-if="!hasImgStoryError"
    :url="storyUrl"
    @error="onImageLoadError"
  />
  <bubble-video
    v-else-if="!hasVideoStoryError"
    :url="storyUrl"
    @error="onVideoLoadError"
  />
  <instagram-story-error-place-holder v-else />
</template>
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
