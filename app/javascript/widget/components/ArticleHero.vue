<template>
  <div>
    <category-card
      :title="$t('PORTAL.POPULAR_ARTICLES')"
      :articles="articles.slice(0, 4)"
      @view-all-articles="$emit('view-all-articles')"
    />
  </div>
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
};
</script>

<style></style>
