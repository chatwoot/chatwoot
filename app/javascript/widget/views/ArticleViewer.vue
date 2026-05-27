<script>
import IframeLoader from 'shared/components/IframeLoader.vue';

export default {
  name: 'ArticleViewer',
  components: {
    IframeLoader,
  },
};
</script>

<template>
  <div class="bg-white h-full">
    <IframeLoader :url="$route.query.link" />
  </div>
</template>
