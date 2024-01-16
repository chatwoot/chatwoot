<template>
  <div class="w-full">
    <div
      class="my-0 py-0 px-4 grid grid-cols-6 md:grid-cols-7 lg:grid-cols-8 gap-4 border-b border-slate-100 dark:border-slate-700 sticky top-16 bg-white dark:bg-slate-900"
      :class="{ draggable: onCategoryPage }"
    >
      <div
        class="font-semibold capitalize text-sm py-2 px-0 text-slate-700 dark:text-slate-100 ltr:text-left rtl:text-right col-span-4"
      >
        {{ $t('HELP_CENTER.TABLE.HEADERS.TITLE') }}
      </div>
      <div
        class="font-semibold capitalize text-sm py-2 px-0 text-slate-700 dark:text-slate-100 text-left"
      >
        {{ $t('HELP_CENTER.TABLE.HEADERS.CATEGORY') }}
      </div>
      <div
        class="font-semibold capitalize text-sm py-2 px-0 text-slate-700 dark:text-slate-100 text-left hidden lg:block"
      >
        {{ $t('HELP_CENTER.TABLE.HEADERS.READ_COUNT') }}
      </div>
      <div
        class="font-semibold capitalize text-sm py-2 px-0 text-slate-700 dark:text-slate-100 text-left"
      >
        {{ $t('HELP_CENTER.TABLE.HEADERS.STATUS') }}
      </div>
      <div
        class="font-semibold capitalize text-sm py-2 px-0 text-slate-700 dark:text-slate-100 text-right hidden md:block"
      >
        {{ $t('HELP_CENTER.TABLE.HEADERS.LAST_EDITED') }}
      </div>
    </div>
    <draggable
      tag="div"
      class="border-t-0 px-4"
      :disabled="!dragEnabled"
      :list="localArticles"
      ghost-class="article-ghost-class"
      @start="dragging = true"
      @end="onDragEnd"
    >
      <ArticleItem
        v-for="article in localArticles"
        :id="article.id"
        :key="article.id"
        :class="{ draggable: onCategoryPage }"
        :title="article.title"
        :author="article.author"
        :category="article.category"
        :views="article.views"
        :status="article.status"
        :updated-at="article.updated_at"
      />
    </draggable>

    <table-footer
      v-if="showArticleFooter"
      :current-page="currentPage"
      :total-count="totalCount"
      :page-size="pageSize"
      class="dark:bg-slate-900 sticky bottom-0 border-t-0 px-4"
      @page-change="onPageChange"
    />
  </div>
</template>

<script>
import ArticleItem from './ArticleItem.vue';
import TableFooter from 'dashboard/components/widgets/TableFooter.vue';
import draggable from 'vuedraggable';

export default {
  components: {
    ArticleItem,
    TableFooter,
    draggable,
  },
  props: {
    articles: {
      type: Array,
      default: () => {},
    },
    totalCount: {
      type: Number,
      default: 0,
    },
    currentPage: {
      type: Number,
      default: 1,
    },
    pageSize: {
      type: Number,
      default: 25,
    },
  },
  data() {
    return {
      localArticles: [],
    };
  },
  computed: {
    dragEnabled() {
      // dragging allowed only on category page
      return (
        this.articles.length > 1 && !this.isFetching && this.onCategoryPage
      );
    },
    onCategoryPage() {
      return this.$route.name === 'show_category';
    },
    showArticleFooter() {
      return this.currentPage === 1
        ? this.totalCount > 25
        : this.articles.length > 0;
    },
  },
  watch: {
    articles() {
      this.localArticles = [...this.articles];
    },
  },
  methods: {
    onDragEnd() {
      // why reuse the same positons array, instead of creating a new one?
      // this ensures that the shuffling happens within the same group
      // itself and does not create any new positions and avoid conflict with existing articles
      // so if a user sorts on page number 2, and the positions are say [550, 560, 570, 580, 590]
      // the new sorted items will be in the same position range as well
      const sortedArticlePositions = this.localArticles
        .map(article => article.position)
        .sort((a, b) => {
          // Why sort like this? Glad you asked!
          // because JavaScript is the doom of my existence, and if a `compareFn` is not supplied,
          // all non-undefined array elements are sorted by converting them to strings
          // and comparing strings in UTF-16 code units order.
          //
          // so an array [20, 10000, 10, 30, 40] will be sorted as [10, 10000, 20, 30, 40]

          return a - b;
        });

      const orderedArticles = this.localArticles.map(article => article.id);

      const reorderedGroup = orderedArticles.reduce((obj, key, index) => {
        obj[key] = sortedArticlePositions[index];
        return obj;
      }, {});

      this.$emit('reorder', reorderedGroup);
    },
    onPageChange(page) {
      this.$emit('page-change', page);
    },
  },
};
</script>
<style lang="scss" scoped>
.article-ghost-class {
  @apply opacity-50 bg-slate-50 dark:bg-slate-800;
}
</style>
