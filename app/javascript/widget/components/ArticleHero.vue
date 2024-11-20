<script>
import CategoryCard from './ArticleCategoryCard.vue';
export default {
  components: { CategoryCard },
  props: {
    articles: {
      type: Array,
      default: () => [],
    },
  },
  emits: ['view', 'viewAll'],
  methods: {
    onArticleClick(link) {
      this.$emit('view', link);
    },
  },
};
</script>

<template>
  <CategoryCard
    :title="$t('PORTAL.POPULAR_ARTICLES')"
    :articles="articles.slice(0, 6)"
    @view-all="$emit('viewAll')"
    @view="onArticleClick"
  />
</template>
