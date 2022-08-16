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
      <tbody>
        <ArticleItem
          v-for="article in articles"
          :id="article.id"
          :key="article.id"
          :title="article.title"
          :author="article.author"
          :category="article.category"
          :read-count="article.readCount"
          :status="article.status"
          :updated-at="article.updated_at"
        />
      </tbody>
    </table>
    <table-footer
      v-if="articles.length"
      :on-page-change="onPageChange"
      :current-page="Number(currentPage)"
      :total-count="totalCount"
      :page-size="pageSize"
    />
  </div>
</template>

<script>
import ArticleItem from './ArticleItem.vue';
import TableFooter from 'dashboard/components/widgets/TableFooter';
export default {
  components: {
    ArticleItem,
    TableFooter,
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
      default: 15,
    },
  },
  methods: {
    onPageChange(page) {
      this.$emit('on-page-change', page);
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
</style>
