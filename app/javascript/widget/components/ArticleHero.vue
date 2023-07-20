<template>
  <elevated-sheet>
    <div>
      <h2 class="text-base font-bold leading-6 text-slate-800 mb-0">
        Help center
      </h2>
      <p class="text-sm leading-6 text-slate-600 mb-0 hidden">
        Read everything about our product.
      </p>
      <div class="my-4">
        <search-article placeholder="Search for answers" @search="onSearch" />
      </div>
      <category-card
        title="Most asked question"
        :articles="articles.slice(0, 4)"
        :category-path="categoryPath"
      />
    </div>
  </elevated-sheet>
</template>

<script>
import CategoryCard from './CategoryCard.vue';
import ElevatedSheet from './ElevatedSheet.vue';
import SearchArticle from './SearchArticle.vue';

export default {
  components: { ElevatedSheet, CategoryCard, SearchArticle },
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
    onSearch(query) {
      this.$emit('search', query);
    },
  },
};
</script>

<style></style>
