<template>
  <button
    class="flex flex-col gap-1 bg-white dark:bg-slate-900 hover:bg-slate-25 hover:dark:bg-slate-800 rounded-md py-1 px-2 w-full group border border-transparent border-solid focus:outline-none focus:bg-slate-25 focus:border-slate-500 dark:focus:border-slate-400 dark:focus:bg-slate-800 cursor-pointer"
    @click="handlePreview"
  >
    <h4
      class="text-sm ltr:text-left rtl:text-right w-full mb-0 text-slate-900 dark:text-slate-25 -mx-1 rounded-sm hover:underline group-hover:underline"
    >
      {{ title }}
    </h4>

    <div class="flex content-between items-center gap-0.5 w-full">
      <p
        class="text-sm ltr:text-left rtl:text-right text-slate-600 dark:text-slate-300 mb-0 w-full"
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
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  name: 'ArticleSearchResultItem',
  mixins: [alertMixin],
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
      this.showAlert(this.$t('CONTACT_PANEL.COPY_SUCCESSFUL'));
    },
  },
};
</script>
