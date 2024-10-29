<script>
import IframeLoader from 'shared/components/IframeLoader.vue';

export default {
  name: 'ArticleView',
  components: {
    IframeLoader,
  },
  props: {
    url: {
      type: String,
      default: '',
    },
  },
  emits: ['back', 'insert'],
  methods: {
    onBack(e) {
      e.stopPropagation();
      this.$emit('back');
    },
    onInsert(e) {
      e.stopPropagation();
      this.$emit('insert');
    },
  },
};
</script>

<template>
  <div class="h-full w-full flex flex-col flex-1 overflow-hidden">
    <div class="py-1">
      <woot-button
        variant="link"
        size="small"
        icon="chevron-left"
        @click="onBack"
      >
        {{ $t('HELP_CENTER.ARTICLE_SEARCH.BACK_RESULTS') }}
      </woot-button>
    </div>
    <div class="-ml-4 h-full overflow-y-auto">
      <div class="w-full h-full min-h-0">
        <IframeLoader :url="url" />
      </div>
    </div>

    <div class="flex justify-end gap-2 py-2">
      <woot-button
        variant="hollow"
        size="small"
        is-expanded
        color-scheme="secondary"
        icon="chevron-left"
        @click="onBack"
      >
        {{ $t('HELP_CENTER.ARTICLE_SEARCH.BACK') }}
      </woot-button>
      <woot-button
        size="small"
        is-expanded
        icon="arrow-download"
        @click="onInsert"
      >
        {{ $t('HELP_CENTER.ARTICLE_SEARCH.INSERT_ARTICLE') }}
      </woot-button>
    </div>
  </div>
</template>
