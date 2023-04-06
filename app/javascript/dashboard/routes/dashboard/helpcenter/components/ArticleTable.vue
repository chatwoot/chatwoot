<template>
  <div class="article-container">
    <table>
      <thead>
        <tr>
          <th scope="col">{{ $t('HELP_CENTER.TABLE.HEADERS.TITLE') }}</th>
          <th scope="col">{{ $t('HELP_CENTER.TABLE.HEADERS.CATEGORY') }}</th>
          <th scope="col">{{ $t('HELP_CENTER.TABLE.HEADERS.READ_COUNT') }}</th>
          <th scope="col">{{ $t('HELP_CENTER.TABLE.HEADERS.STATUS') }}</th>
          <th scope="col">{{ $t('HELP_CENTER.TABLE.HEADERS.LAST_EDITED') }}</th>
        </tr>
      </thead>
      <tr>
        <td colspan="100%" class="horizontal-line" />
      </tr>
      <draggable
        tag="tbody"
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
          :title="article.title"
          :author="article.author"
          :category="article.category"
          :views="article.views"
          :status="article.status"
          :updated-at="article.updated_at"
        />
      </draggable>
    </table>

    <table-footer
      v-if="articles.length"
      :current-page="currentPage"
      :total-count="totalCount"
      :page-size="pageSize"
      @page-change="onPageChange"
    />
  </div>
</template>

<script>
import ArticleItem from './ArticleItem.vue';
import TableFooter from 'dashboard/components/widgets/TableFooter';
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
        this.articles.length > 1 &&
        !this.isFetching &&
        this.$route.name === 'show_category'
      );
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
.article-container {
  width: 100%;

  table thead th {
    font-weight: var(--font-weight-bold);
    text-transform: capitalize;
    color: var(--s-700);
    font-size: var(--font-size-small);
    padding-left: 0;
  }
  .horizontal-line {
    border-bottom: 1px solid var(--color-border);
  }
  .footer {
    padding: 0;
    border: 0;
  }
}

.article-ghost-class {
  opacity: 0.5;
  background-color: var(--s-50);
}
</style>
