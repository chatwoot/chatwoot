<template>
  <div class="container">
    <edit-article-header
      back-button-label="All Articles"
      :status-text="saveStatusText"
      @back="onClickGoBack"
    />
    <div v-if="isFetching" class="text-center p-normal fs-default h-full">
      <spinner size="" />
      <span>{{ $t('HELP_CENTER.EDIT_ARTICLE.LOADING') }}</span>
    </div>
    <article-editor v-else :article="article" @save-article="saveArticle" />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import EditArticleHeader from '../../components/Header/EditArticleHeader.vue';
import ArticleEditor from '../../components/ArticleEditor.vue';
import Spinner from 'shared/components/Spinner';
import portalMixin from '../../mixins/portalMixin';
import alertMixin from 'shared/mixins/alertMixin';
export default {
  components: {
    EditArticleHeader,
    ArticleEditor,
    Spinner,
  },
  mixins: [portalMixin, alertMixin],
  computed: {
    ...mapGetters({
      isFetching: 'articles/isFetching',
      articles: 'articles/articles',
    }),
    article() {
      return this.$store.getters['articles/articleById'](this.articleId);
    },
    articleFlags() {
      return this.$store.getters['articles/articleFlagById'](this.articleId);
    },
    articleId() {
      return this.$route.params.articleSlug;
    },
    selectedPortalSlug() {
      return this.portalSlug || this.selectedPortal?.slug;
    },
    saveStatusText() {
      if (this.articleFlags && this.articleFlags.isUpdating) {
        return this.$t('HELP_CENTER.EDIT_HEADER.SAVING');
      }
      return '';
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
    async saveArticle({ title, content }) {
      try {
        await this.$store.dispatch('articles/update', {
          portalSlug: this.selectedPortalSlug,
          articleId: this.articleId,
          title,
          content,
        });
      } catch (error) {
        this.alertMessage =
          error?.message ||
          this.$t('HELP_CENTER.EDIT_ARTICLE.API.ERROR_MESSAGE');
      }
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
