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
      showArticleSettings: false,
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
    openArticleSettings() {
      this.showArticleSettings = true;
    },
    closeArticleSettings() {
      this.showArticleSettings = false;
    },
  },
};
</script>

<style lang="scss" scoped>
.article-container {
  display: flex;
  padding: var(--space-small) var(--space-normal);
  width: 100%;
  flex: 1;
  overflow: scroll;

  .edit-article--container {
    flex: 1;
    flex-shrink: 0;
    overflow: scroll;
  }

  .is-sidebar-open {
    flex: 0.7;
  }
}
</style>
