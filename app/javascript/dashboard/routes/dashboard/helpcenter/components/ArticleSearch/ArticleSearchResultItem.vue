<template>
  <div
    class="flex flex-col gap-1 bg-white dark:bg-slate-900 hover:bg-slate-25 hover:dark:bg-slate-800 rounded-md py-1 px-2 w-full group"
  >
    <button @click="handlePreview">
      <h4
        class="text-block-title text-left mb-0 text-slate-900 dark:text-slate-25 px-1 -mx-1 rounded-sm hover:underline cursor-pointer width-auto"
      >
        {{ title }}
      </h4>
    </button>

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

export default {
  name: 'ArticleSearchResultItem',
  props: {
    id: {
      type: Number,
      default: 0,
    },
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
      default: '',
    },
  },
  methods: {
    handleInsert() {
      this.$emit('insert', this.id);
    },
    handlePreview() {
      this.$emit('preview', this.id);
    },
    async handleCopy() {
      await copyTextToClipboard(this.url);
      this.showAlert(this.$t('CONTACT_PANEL.COPY_SUCCESSFUL'));
    },
  },
};
</script>
