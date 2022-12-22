<template>
  <div class="article-container">
    <div
      class="new-article--container"
      :class="{ 'is-sidebar-open': showArticleSettings }"
    >
      <edit-article-header
        :back-button-label="$t('HELP_CENTER.HEADER.TITLES.ALL_ARTICLES')"
        draft-state="saved"
        @back="onClickGoBack"
        @open="openArticleSettings"
        @close="closeArticleSettings"
        @save-article="createNewArticle"
      />
      <article-editor :article="newArticle" @save-article="createNewArticle" />
    </div>
    <article-settings
      v-if="showArticleSettings"
      :article="article"
      @save-article="saveArticle"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import EditArticleHeader from 'dashboard/routes/dashboard/helpcenter/components/Header/EditArticleHeader';
import ArticleEditor from '../../components/ArticleEditor.vue';
import portalMixin from '../../mixins/portalMixin';
import alertMixin from 'shared/mixins/alertMixin.js';
import ArticleSettings from './ArticleSettings.vue';
export default {
  components: {
    EditArticleHeader,
    ArticleEditor,
    ArticleSettings,
  },
  mixins: [portalMixin, alertMixin],
  data() {
    return {
      articleTitle: '',
      articleContent: '',
      showOpenSidebarButton: false,
      showArticleSettings: true,
      article: {},
    };
  },
  computed: {
    ...mapGetters({
      currentUserID: 'getCurrentUserID',
      articles: 'articles/articles',
      categories: 'categories/allCategories',
    }),
    articleId() {
      return this.$route.params.articleSlug;
    },
    newArticle() {
      return { title: this.articleTitle, content: this.articleContent };
    },
    selectedPortalSlug() {
      return this.$route.params.portalSlug;
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
              recentlyCreated: true,
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
    openArticleSettings() {
      this.showArticleSettings = true;
    },
    closeArticleSettings() {
      this.showArticleSettings = false;
    },
    saveArticle() {
      this.alertMessage = this.$t('HELP_CENTER.CREATE_ARTICLE.ERROR_MESSAGE');
      this.showAlert(this.alertMessage);
    },
  },
};
</script>

<style lang="scss" scoped>
.article-container {
  display: flex;
  padding: 0 var(--space-normal);
  width: 100%;
  flex: 1;
  overflow: auto;
}
.new-article--container {
  flex: 1;
  flex-shrink: 0;
  overflow-y: auto;
}
.is-sidebar-open {
  flex: 0.7;
  flex-grow: 1;
}
</style>
