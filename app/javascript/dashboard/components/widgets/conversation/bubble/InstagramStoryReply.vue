<script>
import InstagramStory from './InstagramStory.vue';

export default {
  components: { InstagramStory },
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
    },
    onVideoLoadError() {
      this.hasVideoStoryError = true;
    },
  },
};
</script>

<template>
  <blockquote
    class="my-0 px-2 pb-0 pt-0 border-l-4 border-solid border-slate-75 dark:border-slate-600 text-slate-600 dark:text-slate-200"
  >
    <span>{{ $t('CONVERSATION.REPLIED_TO_STORY') }}</span>
    <InstagramStory :story-url="storyUrl" class="mt-3 rounded-md" />
  </blockquote>
</template>
