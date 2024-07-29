<template>
  <button
    class="flex flex-col w-full gap-1 px-2 py-1 bg-white border border-transparent border-solid rounded-md cursor-pointer dark:bg-slate-900 hover:bg-slate-25 hover:dark:bg-slate-800 group focus:outline-none focus:bg-slate-25 focus:border-slate-500 dark:focus:border-slate-400 dark:focus:bg-slate-800"
    @click="handlePreview"
  >
    <h4
      class="w-full mb-0 -mx-1 text-sm rounded-sm ltr:text-left rtl:text-right text-slate-900 dark:text-slate-25 hover:underline group-hover:underline"
    >
      {{ title }}
    </h4>

    <div class="flex content-between items-center gap-0.5 w-full">
      <p
        class="w-full mb-0 text-sm ltr:text-left rtl:text-right text-slate-600 dark:text-slate-300"
      >
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
  </button>
</template>

<script>
import { useAlert } from 'dashboard/composables';
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
    handleInsert(e) {
      e.stopPropagation();
      this.$emit('insert', this.id);
    },
    handlePreview(e) {
      e.stopPropagation();
      this.$emit('preview', this.id);
    },
    async handleCopy(e) {
      e.stopPropagation();
      await copyTextToClipboard(this.url);
      useAlert(this.$t('CONTACT_PANEL.COPY_SUCCESSFUL'));
    },
  },
};
</script>
