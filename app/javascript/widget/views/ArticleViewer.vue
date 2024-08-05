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

<template>
  <div class="bg-white h-full">
    <IframeLoader :url="link" />
  </div>
</template>
