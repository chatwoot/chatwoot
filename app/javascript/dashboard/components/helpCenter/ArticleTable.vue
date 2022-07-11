<template>
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
      <td colspan="100%" class="border-class" />
    </tr>
    <tbody>
      <ArticleItem
        v-for="article in articles"
        :key="article.id"
        :title="article.title"
        :author="article.author"
        :category="article.category"
        :read-count="article.readCount"
        :status="article.status"
      />
    </tbody>
  </table>
</template>

<script>
import ArticleItem from './ArticleItem.vue';
export default {
  components: {
    ArticleItem,
  },
  props: {
    articles: {
      type: Array,
      default: () => {},
    },
  },
};
</script>
<style lang="scss" scoped>
table thead th {
  font-weight: var(--font-weight-bold);
  text-transform: capitalize;
  color: var(--s-600);
  font-size: var(--font-size-small);
}
.border-class {
  border-bottom: 1px solid var(--s-300);
}
</style>
