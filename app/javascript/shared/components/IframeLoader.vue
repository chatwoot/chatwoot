<template>
  <div class="relative overflow-hidden pb-1/2 h-full">
    <iframe
      v-if="url"
      :src="url"
      class="absolute w-full h-full top-0 left-0"
      @load="handleIframeLoad"
      @error="handleIframeError"
    />
    <article-skeleton-loader
      v-if="isLoading"
      class="absolute w-full h-full top-0 left-0"
    />
    <div
      v-if="showEmptyState"
      class="absolute w-full h-full top-0 left-0 flex justify-center items-center"
    >
      <p>{{ $t('PORTAL.IFRAME_ERROR') }}</p>
    </div>
  </div>
</template>

<script>
import ArticleSkeletonLoader from 'shared/components/ArticleSkeletonLoader.vue';

export default {
  name: 'IframeLoader',
  components: {
    ArticleSkeletonLoader,
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
