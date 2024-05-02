<template>
  <div
    class="shadow-xl hover:shadow-lg bg-white dark:bg-slate-900 mt-2 max-h-96 scroll-py-2 p-5 overflow-y-auto text-sm text-slate-700 dark:text-slate-100 border border-solid border-slate-50 dark:border-slate-800 rounded-lg"
  >
    <div
      v-if="isLoading"
      class="font-medium text-sm text-slate-400 dark:text-slate-700"
    >
      {{ loadingPlaceholder }}
    </div>
    <ul
      v-if="shouldShowResults"
      class="bg-white dark:bg-slate-900 gap-4 flex flex-col text-sm text-slate-700 dark:text-slate-100"
      role="listbox"
    >
      <li
        v-for="(article, index) in items"
        :id="article.id"
        :key="article.id"
        class="group flex border border-solid hover:bg-slate-25 dark:hover:bg-slate-800 border-slate-100 dark:border-slate-800 rounded-lg cursor-pointer select-none items-center p-4"
        :class="isSearchItemActive(index)"
        role="option"
        tabindex="-1"
        @mouse-enter="onHover(index)"
        @mouse-leave="onHover(-1)"
      >
        <a
          class="flex flex-col gap-1 overflow-y-hidden"
          :href="generateArticleUrl(article)"
        >
          <span
            v-dompurify-html="prepareContent(article.title)"
            class="flex-auto truncate text-base font-semibold leading-6 w-full overflow-hidden text-ellipsis whitespace-nowrap"
          />
          <div
            v-dompurify-html="prepareContent(article.content)"
            class="line-clamp-2 text-ellipsis whitespace-nowrap overflow-hidden text-slate-600 dark:text-slate-300 text-sm"
          />
        </a>
      </li>
    </ul>

    <div
      v-if="showEmptyResults"
      class="font-medium text-sm text-slate-400 dark:text-slate-700"
    >
      {{ emptyPlaceholder }}
    </div>
  </div>
</template>

<script>
import mentionSelectionKeyboardMixin from 'dashboard/components/widgets/mentions/mentionSelectionKeyboardMixin.js';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';

export default {
  mixins: [mentionSelectionKeyboardMixin, messageFormatterMixin],
  props: {
    items: {
      type: Array,
      default: () => [],
    },
    isLoading: {
      type: Boolean,
      default: false,
    },
    emptyPlaceholder: {
      type: String,
      default: '',
    },
    searchPlaceholder: {
      type: String,
      default: '',
    },
    loadingPlaceholder: {
      type: String,
      default: '',
    },
    resultsTitle: {
      type: String,
      default: '',
    },
    searchTerm: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      selectedIndex: -1,
    };
  },

  computed: {
    showEmptyResults() {
      return !this.items.length && !this.isLoading;
    },
    shouldShowResults() {
      return this.items.length && !this.isLoading;
    },
  },

  methods: {
    isSearchItemActive(index) {
      return index === this.selectedIndex
        ? 'bg-slate-25 dark:bg-slate-800'
        : 'bg-white dark:bg-slate-900';
    },
    generateArticleUrl(article) {
      return `/hc/${article.portal.slug}/articles/${article.slug}`;
    },
    adjustScroll() {
      this.$nextTick(() => {
        this.$el.scrollTop = 102 * this.selectedIndex;
      });
    },
    prepareContent(content) {
      return this.highlightContent(
        content,
        this.searchTerm,
        'bg-slate-100 dark:bg-slate-700 font-semibold text-slate-600 dark:text-slate-200'
      );
    },
  },
};
</script>
