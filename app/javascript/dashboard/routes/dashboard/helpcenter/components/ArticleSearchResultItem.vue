<template>
  <div class="article-item">
    <h4 class="text-block-title margin-bottom-0">{{ title }}</h4>
    <p class="margin-bottom-0 text-truncate">{{ body }}</p>
    <div class="footer">
      <p class="text-small meta">
        {{ locale }}
        {{ ` / ` }}
        {{
          category ||
            $t('HELP_CENTER.ARTICLE_SEARCH_RESULT.ARTICLE_SEARCH_RESULT')
        }}
      </p>
      <div class="action-buttons">
        <woot-button
          :title="$t('HELP_CENTER.ARTICLE_SEARCH_RESULT.COPY_LINK')"
          variant="hollow"
          color-scheme="secondary"
          size="tiny"
          icon="copy"
          @click="handleCopy"
        />

        <a
          :href="url"
          class="button hollow button--only-icon tiny secondary"
          rel="noopener noreferrer nofollow"
          target="_blank"
          :title="$t('HELP_CENTER.ARTICLE_SEARCH_RESULT.OPEN_LINK')"
        >
          <fluent-icon size="12" icon="arrow-up-right" />
          <span class="show-for-sr">{{ url }}</span>
        </a>
        <woot-button
          variant="hollow"
          color-scheme="secondary"
          size="tiny"
          icon="preview-link"
          :title="$t('HELP_CENTER.ARTICLE_SEARCH_RESULT.PREVIEW_LINK')"
          @click="handlePreview"
        />
        <woot-button
          class="insert-button"
          variant="smooth"
          color-scheme="secondary"
          size="tiny"
          @click="handleClick"
        >
          {{ $t('HELP_CENTER.ARTICLE_SEARCH_RESULT.INSERT_ARTICLE') }}
        </woot-button>
      </div>
    </div>
  </div>
</template>

<script>
import { copyTextToClipboard } from 'shared/helpers/clipboard';

export default {
  name: 'ArticleSearchResultItem',
  props: {
    title: {
      type: String,
      default: 'Untitled',
    },
    body: {
      type: String,
      default: '',
    },
    url: {
      type: String,
      default: '',
    },
    category: {
      type: String,
      default: '',
    },
    locale: {
      type: String,
      default: 'en-US',
    },
  },
  methods: {
    handleClick() {
      this.$emit('click');
    },
    handlePreview() {
      this.$emit('preview');
    },
    async handleCopy() {
      await copyTextToClipboard(this.url);
      this.showAlert(this.$t('CONTACT_PANEL.COPY_SUCCESSFUL'));
    },
  },
};
</script>
<style lang="scss" scoped>
.article-item {
  display: flex;
  flex-direction: column;
  gap: var(--space-micro);
}

.footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: var(--space-micro);
}

.meta {
  color: var(--s-600);
  margin-bottom: 0;
}

.action-buttons {
  display: flex;
  gap: var(--space-micro);
}
.action-buttons .button:not(.insert-button) {
  visibility: hidden;
  opacity: 0;
  transition: all 0.1s ease-in;
}

.article-item:hover .action-buttons .button:not(.insert-button) {
  visibility: visible;
  opacity: 1;
}
</style>
