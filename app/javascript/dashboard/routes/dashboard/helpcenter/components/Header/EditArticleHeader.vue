<template>
  <div class="flex items-center justify-between w-full h-16">
    <div class="flex items-center">
      <woot-button
        icon="chevron-left"
        variant="clear"
        size="small"
        color-scheme="primary"
        class="back-button"
        @click="onClickGoBack"
      >
        {{ backButtonLabel }}
      </woot-button>
    </div>
    <div class="flex items-center gap-1">
      <span
        v-if="isUpdating || isSaved"
        class="draft-status mr-1 ml-4 rtl:ml-2 rtl:mr-4 text-slate-400 dark:text-slate-300 items-center text-xs"
      >
        {{ statusText }}
      </span>

      <woot-button
        class-names="article--buttons relative"
        icon="globe"
        color-scheme="secondary"
        variant="hollow"
        size="small"
        @click="showPreview"
      >
        {{ $t('HELP_CENTER.EDIT_HEADER.PREVIEW') }}
      </woot-button>
      <!-- Hidden since this is in V2
      <woot-button
        v-if="shouldShowAddLocaleButton"
        class-names="article--buttons relative"
        icon="add"
        color-scheme="secondary"
        variant="hollow"
        size="small"
        @click="onClickAdd"
      >
        {{ $t('HELP_CENTER.EDIT_HEADER.ADD_TRANSLATION') }}
      </woot-button> -->
      <woot-button
        v-if="!isSidebarOpen"
        v-tooltip.top-end="$t('HELP_CENTER.EDIT_HEADER.OPEN_SIDEBAR')"
        icon="pane-open"
        class-names="article--buttons relative sidebar-button"
        variant="hollow"
        size="small"
        color-scheme="secondary"
        :is-disabled="enableOpenSidebarButton"
        @click="openSidebar"
      />
      <woot-button
        v-if="isSidebarOpen"
        v-tooltip.top-end="$t('HELP_CENTER.EDIT_HEADER.CLOSE_SIDEBAR')"
        icon="pane-close"
        class-names="article--buttons relative"
        variant="hollow"
        size="small"
        color-scheme="secondary"
        @click="closeSidebar"
      />
      <div class="article--buttons relative">
        <div class="button-group">
          <woot-button
            class-names="publish-button"
            size="small"
            icon="checkmark"
            color-scheme="primary"
            :is-disabled="!articleSlug || isPublishedArticle"
            @click="updateArticleStatus(ARTICLE_STATUS_TYPES.PUBLISH)"
          >
            {{ $t('HELP_CENTER.EDIT_HEADER.PUBLISH_BUTTON') }}
          </woot-button>
          <woot-button
            ref="arrowDownButton"
            size="small"
            icon="chevron-down"
            :is-disabled="!articleSlug || isArchivedArticle"
            @click="openActionsDropdown"
          />
        </div>
        <div
          v-if="showActionsDropdown"
          v-on-clickaway="closeActionsDropdown"
          class="dropdown-pane dropdown-pane--open"
        >
          <woot-dropdown-menu>
            <woot-dropdown-item>
              <woot-button
                variant="clear"
                color-scheme="secondary"
                size="small"
                icon="book-clock"
                @click="updateArticleStatus(ARTICLE_STATUS_TYPES.ARCHIVE)"
              >
                {{ $t('HELP_CENTER.EDIT_HEADER.MOVE_TO_ARCHIVE_BUTTON') }}
              </woot-button>
            </woot-dropdown-item>
          </woot-dropdown-menu>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { useAlert } from 'dashboard/composables';
import wootConstants from 'dashboard/constants/globals';
import { PORTALS_EVENTS } from '../../../../../helper/AnalyticsHelper/events';

const { ARTICLE_STATUS_TYPES } = wootConstants;

export default {
  props: {
    isSidebarOpen: {
      type: Boolean,
      default: true,
    },
    backButtonLabel: {
      type: String,
      default: '',
    },
    isUpdating: {
      type: Boolean,
      default: false,
    },
    isSaved: {
      type: Boolean,
      default: false,
    },
    enableOpenSidebarButton: {
      type: Boolean,
      default: false,
    },
    shouldShowAddLocaleButton: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      showActionsDropdown: false,
      alertMessage: '',
      ARTICLE_STATUS_TYPES,
    };
  },
  computed: {
    statusText() {
      return this.isUpdating
        ? this.$t('HELP_CENTER.EDIT_HEADER.SAVING')
        : this.$t('HELP_CENTER.EDIT_HEADER.SAVED');
    },
    articleSlug() {
      return this.$route.params.articleSlug;
    },
    currentPortalSlug() {
      return this.$route.params.portalSlug;
    },
    currentArticleStatus() {
      return this.$store.getters['articles/articleStatus'](this.articleSlug);
    },
    isPublishedArticle() {
      return this.currentArticleStatus === 'published';
    },
    isArchivedArticle() {
      return this.currentArticleStatus === 'archived';
    },
  },
  methods: {
    onClickGoBack() {
      this.$emit('back');
    },
    showPreview() {
      this.$emit('show');
    },
    onClickAdd() {
      this.$emit('add');
    },
    async updateArticleStatus(status) {
      try {
        await this.$store.dispatch('articles/update', {
          portalSlug: this.currentPortalSlug,
          articleId: this.articleSlug,
          status: status,
        });
        this.$emit('update-meta');
        this.statusUpdateSuccessMessage(status);
        this.closeActionsDropdown();
        if (status === this.ARTICLE_STATUS_TYPES.ARCHIVE) {
          this.$track(PORTALS_EVENTS.ARCHIVE_ARTICLE, { uiFrom: 'header' });
        } else if (status === this.ARTICLE_STATUS_TYPES.PUBLISH) {
          this.$track(PORTALS_EVENTS.PUBLISH_ARTICLE);
        }
      } catch (error) {
        this.alertMessage =
          error?.message || this.statusUpdateErrorMessage(status);
      } finally {
        useAlert(this.alertMessage);
      }
    },
    statusUpdateSuccessMessage(status) {
      if (status === this.ARTICLE_STATUS_TYPES.PUBLISH) {
        this.alertMessage = this.$t('HELP_CENTER.PUBLISH_ARTICLE.API.SUCCESS');
      } else if (status === this.ARTICLE_STATUS_TYPES.ARCHIVE) {
        this.alertMessage = this.$t('HELP_CENTER.ARCHIVE_ARTICLE.API.SUCCESS');
      }
    },
    statusUpdateErrorMessage(status) {
      if (status === this.ARTICLE_STATUS_TYPES.PUBLISH) {
        this.alertMessage = this.$t('HELP_CENTER.PUBLISH_ARTICLE.API.ERROR');
      } else if (status === this.ARTICLE_STATUS_TYPES.ARCHIVE) {
        this.alertMessage = this.$t('HELP_CENTER.ARCHIVE_ARTICLE.API.ERROR');
      }
    },
    openSidebar() {
      this.$emit('open');
    },
    closeSidebar() {
      this.$emit('close');
    },
    openActionsDropdown() {
      this.showActionsDropdown = !this.showActionsDropdown;
    },
    closeActionsDropdown() {
      this.showActionsDropdown = false;
    },
  },
};
</script>

<style scoped lang="scss">
.article--buttons {
  .dropdown-pane {
    @apply absolute right-0;
  }
}

.draft-status {
  animation: fadeIn 1s;

  @keyframes fadeIn {
    0% {
      opacity: 0;
    }

    100% {
      opacity: 1;
    }
  }
}
</style>
