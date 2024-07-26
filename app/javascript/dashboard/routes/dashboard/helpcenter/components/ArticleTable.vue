<script>
import ArticleItem from './ArticleItem.vue';
import TableFooter from 'dashboard/components/widgets/TableFooter.vue';
import draggable from 'vuedraggable';

export default {
  components: {
    ArticleItem,
    TableFooter,
    Draggable: draggable,
  },
  props: {
    articles: {
      type: Array,
      default: () => [],
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
      localArticles: this.articles || [],
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
      this.$emit('pageChange', page);
    },
  },
};
</script>

<template>
  <div class="flex-1">
    <div
      class="sticky z-10 content-center hidden h-12 grid-cols-12 gap-4 px-6 py-0 bg-white border-b lg:grid border-slate-50 dark:border-slate-700 top-16 dark:bg-slate-900"
      :class="{ draggable: onCategoryPage }"
    >
      <div
        class="col-span-6 px-0 py-2 text-sm font-semibold text-left capitalize text-slate-700 dark:text-slate-100 rtl:text-right"
      >
        {{ $t('HELP_CENTER.TABLE.HEADERS.TITLE') }}
      </div>
      <div
        class="col-span-2 px-0 py-2 text-sm font-semibold text-left capitalize text-slate-700 dark:text-slate-100 rtl:text-right"
      >
        {{ $t('HELP_CENTER.TABLE.HEADERS.CATEGORY') }}
      </div>
      <div
        class="hidden px-0 py-2 text-sm font-semibold text-left capitalize text-slate-700 dark:text-slate-100 rtl:text-right lg:block"
      >
        {{ $t('HELP_CENTER.TABLE.HEADERS.READ_COUNT') }}
      </div>
      <div
        class="px-0 py-2 text-sm font-semibold text-left capitalize text-slate-700 dark:text-slate-100 rtl:text-right"
      >
        {{ $t('HELP_CENTER.TABLE.HEADERS.STATUS') }}
      </div>
      <div
        class="hidden col-span-2 px-0 py-2 text-sm font-semibold text-right capitalize text-slate-700 dark:text-slate-100 rtl:text-left md:block"
      >
        {{ $t('HELP_CENTER.TABLE.HEADERS.LAST_EDITED') }}
      </div>
    </div>
    <Draggable
      tag="div"
      class="px-4 pb-4 border-t-0"
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
        :show-drag-icon="dragEnabled"
        :category="article.category"
        :views="article.views"
        :status="article.status"
        :updated-at="article.updated_at"
      />
    </Draggable>

    <TableFooter
      v-if="showArticleFooter"
      :current-page="currentPage"
      :total-count="totalCount"
      :page-size="pageSize"
      class="bottom-0 border-t dark:bg-slate-900 border-slate-75 dark:border-slate-700/50"
      @pageChange="onPageChange"
    />
  </div>
</template>

<style lang="scss" scoped>
/*
The .article-ghost-class class is maintained as the vueDraggable doesn't allow multiple classes
to be passed in the ghost-class prop.
 */
.article-ghost-class {
  @apply opacity-50 bg-slate-50 dark:bg-slate-800;
}
</style>
