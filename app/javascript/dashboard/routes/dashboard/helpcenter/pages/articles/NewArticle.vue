<template>
  <div class="flex flex-1 overflow-auto">
    <div
      class="flex-1 flex-shrink-0 px-6 overflow-y-auto"
      :class="{ 'flex-grow-1': showArticleSettings }"
    >
      <edit-article-header
        :back-button-label="$t('HELP_CENTER.HEADER.TITLES.ALL_ARTICLES')"
        draft-state="saved"
        :is-sidebar-open="showArticleSettings"
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
import { useAlert } from 'dashboard/composables';
import EditArticleHeader from 'dashboard/routes/dashboard/helpcenter/components/Header/EditArticleHeader.vue';
import ArticleEditor from '../../components/ArticleEditor.vue';
import portalMixin from '../../mixins/portalMixin';
import ArticleSettings from './ArticleSettings.vue';
import { PORTALS_EVENTS } from '../../../../../helper/AnalyticsHelper/events';
export default {
  components: {
    EditArticleHeader,
    ArticleEditor,
    ArticleSettings,
  },
  mixins: [portalMixin],
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
          this.$track(PORTALS_EVENTS.CREATE_ARTICLE, {
            locale: this.locale,
          });
        } catch (error) {
          this.alertMessage =
            error?.message ||
            this.$t('HELP_CENTER.CREATE_ARTICLE.API.ERROR_MESSAGE');
          useAlert(this.alertMessage);
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
      useAlert(this.alertMessage);
    },
  },
};
</script>
