<template>
  <div class="article-container">
    <edit-article-header
      :back-button-label="$t('HELP_CENTER.HEADER.TITLES.ALL_ARTICLES')"
      draft-state="saved"
      @back="onClickGoBack"
      @save-article="createNewArticle"
    />
    <article-editor :article="article" @save-article="createNewArticle" />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import EditArticleHeader from 'dashboard/routes/dashboard/helpcenter/components/Header/EditArticleHeader';
import ArticleEditor from '../../components/ArticleEditor.vue';
import portalMixin from '../../mixins/portalMixin';
import alertMixin from 'shared/mixins/alertMixin.js';
export default {
  components: {
    EditArticleHeader,
    ArticleEditor,
  },
  mixins: [portalMixin, alertMixin],
  data() {
    return {
      articleTitle: '',
      articleContent: '',
      showArticleSettings: false,
    };
  },
  computed: {
    ...mapGetters({
      selectedPortal: 'portals/getSelectedPortal',
      currentUserID: 'getCurrentUserID',
      categories: 'categories/allCategories',
    }),
    article() {
      return { title: this.articleTitle, content: this.articleContent };
    },
    selectedPortalSlug() {
      return this.portalSlug || this.selectedPortal?.slug;
    },
    categoryId() {
      return this.categories.length ? this.categories[0].id : null;
    },
  },
  methods: {
    onClickGoBack() {
      this.$router.push({ name: 'list_all_locale_articles' });
    },
    async createNewArticle({ ...values }) {
      const { title, content } = values;
      if (title) this.articleTitle = title;
      if (content) this.articleContent = content;
      if (this.articleTitle && this.articleContent) {
        try {
          const articleId = await this.$store.dispatch('articles/create', {
            portalSlug: this.selectedPortalSlug,
            content: this.articleContent,
            title: this.articleTitle,
            author_id: this.currentUserID,
            // TODO: Change to un categorized later when API supports
            category_id: this.categoryId,
          });
          this.$router.push({
            name: 'edit_article',
            params: {
              articleSlug: articleId,
              portalSlug: this.selectedPortalSlug,
              locale: this.locale,
            },
          });
        } catch (error) {
          this.alertMessage =
            error?.message ||
            this.$t('HELP_CENTER.CREATE_ARTICLE.API.ERROR_MESSAGE');
          this.showAlert(this.alertMessage);
        }
      }
    },
  },
};
</script>

<style lang="scss" scoped>
.article-container {
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
