<template>
  <div class="article-container">
    <div
      class="edit-article--container"
      :class="{ 'is-sidebar-open': showArticleSettings }"
    >
      <edit-article-header
        :back-button-label="$t('HELP_CENTER.HEADER.TITLES.ALL_ARTICLES')"
        :is-updating="isUpdating"
        :is-saved="isSaved"
        @back="onClickGoBack"
        @open="openArticleSettings"
        @close="closeArticleSettings"
      />
      <div v-if="isFetching" class="text-center p-normal fs-default h-full">
        <spinner size="" />
        <span>{{ $t('HELP_CENTER.EDIT_ARTICLE.LOADING') }}</span>
      </div>
      <article-editor
        v-else
        :is-settings-sidebar-open="showArticleSettings"
        :article="article"
        @save-article="saveArticle"
      />
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
import EditArticleHeader from '../../components/Header/EditArticleHeader.vue';
import ArticleEditor from '../../components/ArticleEditor.vue';
import ArticleSettings from './ArticleSettings.vue';
import Spinner from 'shared/components/Spinner';
import portalMixin from '../../mixins/portalMixin';
import alertMixin from 'shared/mixins/alertMixin';
export default {
  components: {
    EditArticleHeader,
    ArticleEditor,
    Spinner,
    ArticleSettings,
  },
  mixins: [portalMixin, alertMixin],
  data() {
    return {
      isUpdating: false,
      isSaved: false,
      showArticleSettings: false,
      alertMessage: '',
    };
  },
  computed: {
    ...mapGetters({
      isFetching: 'articles/isFetching',
      articles: 'articles/articles',
      selectedPortal: 'portals/getSelectedPortal',
    }),
    article() {
      return this.$store.getters['articles/articleById'](this.articleId);
    },
    articleId() {
      return this.$route.params.articleSlug;
    },
    selectedPortalSlug() {
      return this.portalSlug || this.selectedPortal?.slug;
    },
  },
  mounted() {
    this.fetchArticleDetails();
  },
  methods: {
    onClickGoBack() {
      this.$router.push({ name: 'list_all_locale_articles' });
    },
    fetchArticleDetails() {
      this.$store.dispatch('articles/show', {
        id: this.articleId,
        portalSlug: this.selectedPortalSlug,
      });
    },
    async saveArticle({ ...values }) {
      this.isUpdating = true;
      try {
        await this.$store.dispatch('articles/update', {
          portalSlug: this.selectedPortalSlug,
          articleId: this.articleId,
          ...values,
        });
      } catch (error) {
        this.alertMessage =
          error?.message ||
          this.$t('HELP_CENTER.EDIT_ARTICLE.API.ERROR_MESSAGE');
        this.showAlert(this.alertMessage);
      } finally {
        setTimeout(() => {
          this.isUpdating = false;
          this.isSaved = true;
        }, 1500);
      }
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
