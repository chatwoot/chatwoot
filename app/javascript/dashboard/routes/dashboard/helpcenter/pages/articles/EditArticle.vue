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
      @delete-article="openDeletePopup"
      @archive-article="archiveArticle"
    />
    <woot-delete-modal
      :show.sync="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('HELP_CENTER.DELETE_ARTICLE.MODAL.CONFIRM.TITLE')"
      :message="$t('HELP_CENTER.DELETE_ARTICLE.MODAL.CONFIRM.MESSAGE')"
      :confirm-text="$t('HELP_CENTER.DELETE_ARTICLE.MODAL.CONFIRM.YES')"
      :reject-text="$t('HELP_CENTER.DELETE_ARTICLE.MODAL.CONFIRM.NO')"
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
import wootConstants from 'dashboard/constants';

const { ARTICLE_STATUS_TYPES } = wootConstants;
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
      showDeleteConfirmationPopup: false,
    };
  },
  computed: {
    ...mapGetters({
      isFetching: 'articles/isFetching',
      articles: 'articles/articles',
    }),
    article() {
      return this.$store.getters['articles/articleById'](this.articleId);
    },
    articleId() {
      return this.$route.params.articleSlug;
    },
    selectedPortalSlug() {
      return this.$route.params.portalSlug;
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
    openDeletePopup() {
      this.showDeleteConfirmationPopup = true;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    confirmDeletion() {
      this.closeDeletePopup();
      this.deleteArticle();
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
          error?.message || this.$t('HELP_CENTER.EDIT_ARTICLE.API.ERROR');
        this.showAlert(this.alertMessage);
      } finally {
        setTimeout(() => {
          this.isUpdating = false;
          this.isSaved = true;
        }, 1500);
      }
    },
    async deleteArticle() {
      try {
        await this.$store.dispatch('articles/delete', {
          portalSlug: this.selectedPortalSlug,
          articleId: this.articleId,
        });
        this.alertMessage = this.$t(
          'HELP_CENTER.DELETE_ARTICLE.API.SUCCESS_MESSAGE'
        );
        this.$router.push({
          name: 'list_all_locale_articles',
          params: {
            portalSlug: this.selectedPortalSlug,
            locale: this.locale,
          },
        });
      } catch (error) {
        this.alertMessage =
          error?.message ||
          this.$t('HELP_CENTER.DELETE_ARTICLE.API.ERROR_MESSAGE');
      } finally {
        this.showAlert(this.alertMessage);
      }
    },
    async archiveArticle() {
      try {
        await this.$store.dispatch('articles/update', {
          portalSlug: this.selectedPortalSlug,
          articleId: this.articleId,
          status: ARTICLE_STATUS_TYPES.ARCHIVE,
        });
        this.alertMessage = this.$t('HELP_CENTER.ARCHIVE_ARTICLE.API.SUCCESS');
      } catch (error) {
        this.alertMessage =
          error?.message || this.$t('HELP_CENTER.ARCHIVE_ARTICLE.API.ERROR');
      } finally {
        this.showAlert(this.alertMessage);
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
  overflow: auto;

  .edit-article--container {
    flex: 1;
    flex-shrink: 0;
    overflow: auto;
  }

  .is-sidebar-open {
    flex: 0.7;
  }
}
</style>
