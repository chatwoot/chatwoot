<template>
  <div class="bg-white h-full">
    <iframe-loader :url="link" />
  </div>
</template>

<script>
import IframeLoader from 'shared/components/IframeLoader.vue';

export default {
  name: 'ArticleViewer',
  components: {
    IframeLoader,
  },
  props: {
    link: {
      type: String,
      default: '',
    },
  },
};
</script>
