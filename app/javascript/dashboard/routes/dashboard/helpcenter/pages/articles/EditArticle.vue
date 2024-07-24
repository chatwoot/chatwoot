<template>
  <div class="flex w-full overflow-auto article-container">
    <div
      class="flex-1 flex-shrink-0 px-6 overflow-auto"
      :class="{ 'flex-grow-1 flex-shrink-0': showArticleSettings }"
    >
      <edit-article-header
        :back-button-label="$t('HELP_CENTER.HEADER.TITLES.ALL_ARTICLES')"
        :is-updating="isUpdating"
        :is-saved="isSaved"
        :is-sidebar-open="showArticleSettings"
        @back="onClickGoBack"
        @open="openArticleSettings"
        @close="closeArticleSettings"
        @show="showArticleInPortal"
        @update-meta="updateMeta"
      />
      <div v-if="isFetching" class="h-full p-4 text-base text-center">
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
      @update-meta="updateMeta"
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
import { useAlert } from 'dashboard/composables';
import EditArticleHeader from '../../components/Header/EditArticleHeader.vue';
import ArticleEditor from '../../components/ArticleEditor.vue';
import ArticleSettings from './ArticleSettings.vue';
import Spinner from 'shared/components/Spinner.vue';
import portalMixin from '../../mixins/portalMixin';
import wootConstants from 'dashboard/constants/globals';
import { buildPortalArticleURL } from 'dashboard/helper/portalHelper';
import { PORTALS_EVENTS } from '../../../../../helper/AnalyticsHelper/events';

const { ARTICLE_STATUS_TYPES } = wootConstants;
export default {
  components: {
    EditArticleHeader,
    ArticleEditor,
    Spinner,
    ArticleSettings,
  },
  mixins: [portalMixin],
  data() {
    return {
      isUpdating: false,
      isSaved: false,
      showArticleSettings: true,
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
    selectedLocale() {
      return this.$route.params.locale;
    },
    portalLink() {
      const slug = this.$route.params.portalSlug;
      return buildPortalArticleURL(
        slug,
        this.article.category.slug,
        this.article.category.locale,
        this.article.slug
      );
    },
  },
  mounted() {
    this.fetchArticleDetails();
  },
  methods: {
    onClickGoBack() {
      if (window.history.length > 2) {
        this.$router.go(-1);
      } else {
        this.$router.push({ name: 'list_all_locale_articles' });
      }
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
      this.$track(PORTALS_EVENTS.DELETE_ARTICLE, {
        status: this.article?.status,
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
          error?.message || this.$t('HELP_CENTER.EDIT_ARTICLE.API.ERROR');
        useAlert(this.alertMessage);
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
            recentlyDeleted: true,
          },
        });
      } catch (error) {
        this.alertMessage =
          error?.message ||
          this.$t('HELP_CENTER.DELETE_ARTICLE.API.ERROR_MESSAGE');
      } finally {
        useAlert(this.alertMessage);
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
        this.$track(PORTALS_EVENTS.ARCHIVE_ARTICLE, { uiFrom: 'sidebar' });
      } catch (error) {
        this.alertMessage =
          error?.message || this.$t('HELP_CENTER.ARCHIVE_ARTICLE.API.ERROR');
      } finally {
        useAlert(this.alertMessage);
      }
    },
    updateMeta() {
      const selectedPortalParam = {
        portalSlug: this.selectedPortalSlug,
        locale: this.selectedLocale,
      };
      return this.$store.dispatch('portals/show', selectedPortalParam);
    },
    openArticleSettings() {
      this.showArticleSettings = true;
    },
    closeArticleSettings() {
      this.showArticleSettings = false;
    },
    showArticleInPortal() {
      window.open(this.portalLink, '_blank');
      this.$track(PORTALS_EVENTS.PREVIEW_ARTICLE, {
        status: this.article?.status,
      });
    },
  },
};
</script>
