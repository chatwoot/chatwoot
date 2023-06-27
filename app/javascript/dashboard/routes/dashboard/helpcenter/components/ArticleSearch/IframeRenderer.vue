<template>
  <div class="iframe-container">
    <iframe
      v-if="url"
      :src="url"
      frameborder="0"
      width="100%"
      height="100%"
      @load="handleIframeLoad"
      @error="handleIframeError"
    />
    <article-skeleton-loader-vue v-if="isLoading" />
    <div v-if="showEmptyState" class="empty-state">
      <p>{{ $t('HELP_CENTER.ARTICLE_SEARCH.IFRAME_ERROR') }}</p>
    </div>
  </div>
</template>

<script>
import ArticleSkeletonLoaderVue from './ArticleSkeletonLoader.vue';
export default {
  name: 'IframeRenderer',
  components: {
    ArticleSkeletonLoaderVue,
  },
  props: {
    url: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      isLoading: true,
      showEmptyState: !this.url,
    };
  },
  methods: {
    handleIframeLoad() {
      // Once loaded, the loading state is hidden
      this.isLoading = false;
    },
    handleIframeError() {
      // Hide the loading state and show the empty state when an error occurs
      this.isLoading = false;
      this.showEmptyState = true;
    },
  },
};
</script>

<style scoped>
.iframe-container {
  position: relative;
  padding-bottom: 56.25%;
  height: 0;
  overflow: hidden;
}

.iframe-container iframe {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
}

.loading-state,
.empty-state {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
  background-color: var(--s-25);
}
</style>
