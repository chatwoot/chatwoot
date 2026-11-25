<script>
import IframeLoader from 'shared/components/IframeLoader.vue';
import { getArticleViewerURL } from 'widget/helpers/urlParamsHelper';

export default {
  name: 'ArticleViewer',
  components: {
    IframeLoader,
  },
  computed: {
    articleURL() {
      return getArticleViewerURL(this.$route.query.link);
    },
  },
};
</script>

<template>
  <div class="bg-n-solid-1 h-full">
    <IframeLoader :url="articleURL" />
  </div>
</template>
