<template>
  <div>
    <h2 class="text-base font-bold leading-6 text-slate-800 mb-0">
      {{ $t('PORTAL.POPULAR_ARTICLES') }}
    </h2>
    <category-card
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
