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
      dragEnabled: true,
      dragging: false,
      localArticles: [],
    };
  },
  watch: {
    articles() {
      this.localArticles = [...this.articles];
    },
  },
  methods: {
    onDragEnd() {
      this.dragging = false;
      // const sortedArticlePositions = this.localArticles
      //   .map(article => article.position)
      //   .sort();

      // const orderedArticles = this.localArticles.map(article => article.id);
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
