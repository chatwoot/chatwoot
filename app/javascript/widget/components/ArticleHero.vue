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
    @viewAll="$emit('viewAll')"
    @view="onArticleClick"
  />
</template>
