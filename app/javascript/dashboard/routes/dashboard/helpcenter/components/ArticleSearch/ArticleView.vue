<template>
  <div class="chatwoot-search">
    <search-header title="Insert article" @close="onClose" @search="onSearch" />
    <div class="padding-1">
      <iframe-loader :url="url" />
    </div>
    <div class="footer">
      <woot-button
        variant="hollow"
        size="small"
        color-scheme="secondary"
        icon="dismiss"
        @click="onClose"
      >
        {{ $t('HELP_CENTER.ARTICLE_SEARCH.INSERT_ARTICLE') }}
      </woot-button>
      <woot-button
        variant="smooth"
        size="small"
        icon="arrow-download"
        @click="onClose"
      >
        {{ $t('HELP_CENTER.ARTICLE_SEARCH.CANCEL') }}
      </woot-button>
    </div>
  </div>
</template>

<script>
import SearchHeader from './Header';
import IframeLoader from 'shared/components/IframeLoader.vue';

export default {
  name: 'ChatwootSearch',
  components: {
    SearchHeader,
    IframeLoader,
  },
  props: {
    url: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      searchQuery: '',
    };
  },
  methods: {
    onSearch() {
      this.$emit('search', this.searchQuery);
    },
    onClose() {
      this.$emit('close');
    },
  },
};
</script>

<style scoped lang="scss">
.footer {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-smaller);
  padding: var(--space-medium) 0;
}
</style>
