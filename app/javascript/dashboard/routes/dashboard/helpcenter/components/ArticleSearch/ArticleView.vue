<template>
  <div class="h-full w-full">
    <div class="padding-1 h-[480px] max-h-[60vh] min-h-[320px]">
      <iframe-loader :url="url" />
    </div>
    <div class="footer">
      <woot-button
        variant="hollow"
        size="small"
        color-scheme="secondary"
        icon="dismiss"
        @click="onBack"
      >
        {{ $t('HELP_CENTER.ARTICLE_SEARCH.CANCEL') }}
      </woot-button>
      <woot-button
        variant="smooth"
        size="small"
        icon="arrow-download"
        @click="onInsert"
      >
        {{ $t('HELP_CENTER.ARTICLE_SEARCH.INSERT_ARTICLE') }}
      </woot-button>
    </div>
  </div>
</template>

<script>
import IframeLoader from 'shared/components/IframeLoader.vue';

export default {
  name: 'ChatwootSearch',
  components: {
    IframeLoader,
  },
  props: {
    url: {
      type: String,
      default: '',
    },
  },
  methods: {
    onBack() {
      this.$emit('back');
    },
    onInsert() {
      this.$emit('insert');
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
