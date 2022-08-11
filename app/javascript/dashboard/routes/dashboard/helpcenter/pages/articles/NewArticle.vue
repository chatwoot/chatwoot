<template>
  <div class="article-container">
    <div
      class="edit-article--container"
      :class="{ 'is-sidebar-open': showArticleSettings }"
    >
      <edit-article-header
        back-button-label="All Articles"
        draft-state="saved"
        @back="onClickGoBack"
        @open="openArticleSettings"
        @close="closeArticleSettings"
      />
      <edit-article-field
        :is-settings-sidebar-open="showArticleSettings"
        @titleInput="titleInput"
        @contentInput="contentInput"
      />
    </div>
    <article-settings v-if="showArticleSettings" />
  </div>
</template>

<script>
import EditArticleHeader from 'dashboard/routes/dashboard/helpcenter/components/Header/EditArticleHeader';
import EditArticleField from 'dashboard/components/helpCenter/EditArticle';
import ArticleSettings from 'dashboard/routes/dashboard/helpcenter/pages/articles/ArticleSettings';
export default {
  components: {
    EditArticleHeader,
    EditArticleField,
    ArticleSettings,
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
