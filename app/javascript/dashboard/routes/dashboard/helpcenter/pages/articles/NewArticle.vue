<template>
  <div class="container">
    <edit-article-header
      back-button-label="All Articles"
      draft-state="saved"
      @back="onClickGoBack"
    />
    <edit-article-field @titleInput="titleInput" @contentInput="contentInput" />
  </div>
</template>

<script>
import EditArticleHeader from 'dashboard/components/helpCenter/Header/EditArticleHeader';
import EditArticleField from 'dashboard/components/helpCenter/EditArticle';
export default {
  components: {
    EditArticleHeader,
    EditArticleField,
  },
  data() {
    return {
      articleTitle: '',
      articleContent: '',
    };
  },
  methods: {
    onClickGoBack() {
      this.$router.push({ name: 'list_all_locale_articles' });
    },
    titleInput(value) {
      this.articleTitle = value;
    },
    contentInput(value) {
      this.articleContent = value;
    },
  },
};
</script>

<style lang="scss" scoped>
.container {
  padding: var(--space-small) var(--space-normal);
  width: 100%;
  overflow: scroll;
}
</style>
