<template>
  <div class="container">
    <article-header
      header-title="All Articles"
      :count="199"
      selected-value="Published"
      @newArticlePage="newArticlePage"
    />
  </div>
</template>

<script>
import ArticleHeader from 'dashboard/components/helpCenter/Header/ArticleHeader';
export default {
  components: {
    ArticleHeader,
  },
  methods: {
    newArticlePage() {
      this.$router.push({ name: 'new_article' });
    },
  },
};
</script>

<style lang="scss" scoped>
.container {
  padding: var(--space-small) var(--space-normal);
  width: 100%;
}
</style>
