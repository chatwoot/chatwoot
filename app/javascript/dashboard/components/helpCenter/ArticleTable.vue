<template>
  <table>
    <thead>
      <tr>
        <th scope="col">Title</th>
        <th scope="col">Category</th>
        <th scope="col">Read Count</th>
        <th scope="col">Status</th>
        <th scope="col">Last Edited</th>
      </tr>
    </thead>
    <ArticleItem />
  </table>
</template>

<script>
import ArticleItem from './ArticleItem.vue';
export default {
  components: {
    ArticleItem,
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
</style>
