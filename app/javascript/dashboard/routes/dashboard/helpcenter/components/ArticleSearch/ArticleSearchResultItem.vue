<template>
  <div
    class="flex flex-col gap-1 bg-white dark:bg-slate-900 hover:bg-slate-25 hover:dark:bg-slate-800 rounded-md py-1 px-2 w-full group"
  >
    <h4 class="text-block-title mb-0 text-slate-900 dark:text-slate-25">
      {{ title }}
    </h4>
    <p
      class="mb-0 overflow-hidden whitespace-nowrap text-ellipsis text-slate-700 dark:text-slate-100"
    >
      {{ plainBody }}
    </p>
    <div class="flex content-between items-center gap-0.5 w-full">
      <p class="text-sm text-slate-600 dark:text-slate-300 mb-0 w-full">
        {{ locale }}
        {{ ` / ` }}
        {{ category || $t('HELP_CENTER.ARTICLE_SEARCH_RESULT.UNCATEGORIZED') }}
      </p>
      <div class="flex gap-0.5">
        <woot-button
          :title="$t('HELP_CENTER.ARTICLE_SEARCH_RESULT.COPY_LINK')"
          variant="hollow"
          color-scheme="secondary"
          size="tiny"
          icon="copy"
          class="invisible group-hover:visible"
          @click="handleCopy"
        />

        <a
          :href="url"
          class="button hollow button--only-icon tiny secondary invisible group-hover:visible"
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
          class="invisible group-hover:visible"
          :title="$t('HELP_CENTER.ARTICLE_SEARCH_RESULT.PREVIEW_LINK')"
          @click="handlePreview"
        />
        <woot-button
          class="insert-button"
          variant="smooth"
          color-scheme="secondary"
          size="tiny"
          @click="handleInsert"
        >
          {{ $t('HELP_CENTER.ARTICLE_SEARCH_RESULT.INSERT_ARTICLE') }}
        </woot-button>
      </div>
    </div>
  </div>
</template>

<script>
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin.js';

export default {
  name: 'ArticleSearchResultItem',
  mixins: [messageFormatterMixin],
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
  computed: {
    plainBody() {
      return this.getPlainText(this.body);
    },
  },
  methods: {
    handleInsert() {
      this.$emit('insert', this.url);
    },
    handlePreview() {
      this.$emit('preview', this.url);
    },
    async handleCopy(e) {
      e.preventDefault();
      await copyTextToClipboard(this.url);
      this.showAlert(this.$t('CONTACT_PANEL.COPY_SUCCESSFUL'));
    },
  },
};
</script>
