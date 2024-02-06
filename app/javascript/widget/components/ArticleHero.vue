<template>
  <category-card
    :title="$t('PORTAL.POPULAR_ARTICLES')"
    :articles="articles.slice(0, 6)"
    @view-all="$emit('view-all')"
    @view="onArticleClick"
  />
</template>

<script>
import CategoryCard from './ArticleCategoryCard.vue';
export default {
  components: { CategoryCard },
  props: {
    articles: {
      type: Array,
      default: () => [],
    },
    categoryPath: {
      type: String,
      default: '',
    },
  },
  methods: {
    onArticleClick(link) {
      this.$emit('view', link);
    },
  },
};
</script>

<style></style>
