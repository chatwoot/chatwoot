<template>
  <div class="container">
    <edit-article-header
      back-button-label="All Articles"
      draft-state="saved"
      @back="onClickGoBack"
    />
    <article-editor @titleInput="titleInput" @contentInput="contentInput" />
  </div>
</template>

<script>
import EditArticleHeader from 'dashboard/routes/dashboard/helpcenter/components/Header/EditArticleHeader';
import ArticleEditor from '../../components/ArticleEditor.vue';
export default {
  components: {
    EditArticleHeader,
    ArticleEditor,
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
