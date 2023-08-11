<template>
  <div class="py-2">
    <h3 class="text-sm font-semibold text-slate-900 mb-0">{{ title }}</h3>
    <article-list :articles="articles" />
    <button
      class="inline-flex text-sm font-medium rounded-md px-2 py-1 -ml-2 leading-6 text-slate-800 justify-between items-center hover:bg-slate-25 see-articles"
      @click="$emit('view-all-articles')"
    >
      <span class="pr-2">{{ $t('PORTAL.VIEW_ALL_ARTICLES') }}</span>
      <fluent-icon icon="arrow-right" size="14" />
    </button>
  </div>
</template>

<script>
import ArticleList from './ArticleList.vue';
export default {
  components: { ArticleList },
  props: {
    title: {
      type: String,
      default: '',
    },
    articles: {
      type: Array,
      default: () => [],
    },
    categoryPath: {
      type: String,
      default: '',
    },
  },
};
</script>
<style lang="scss" scoped>
.see-articles {
  color: var(--brand-textButtonClear);
  svg {
    color: var(--brand-textButtonClear);
  }
}
</style>
